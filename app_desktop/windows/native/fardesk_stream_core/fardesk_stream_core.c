#include <Limelight.h>

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

#ifdef _WIN32
#define FARDESK_EXPORT __declspec(dllexport)
#else
#define FARDESK_EXPORT
#endif

enum {
    FARDESK_STATE_DISCONNECTED = 0,
    FARDESK_STATE_CONNECTING = 1,
    FARDESK_STATE_CONNECTED = 2,
    FARDESK_STATE_DISCONNECTING = 3,
    FARDESK_STATE_FAILED = 4,
};

static volatile LONG state = FARDESK_STATE_DISCONNECTED;
static volatile LONG last_error = 0;
static volatile LONG has_connection_thread = 0;
static volatile LONG video_frame_count = 0;

typedef struct {
    char* address;
    char* session_url;
    unsigned char remote_input_key[16];
    unsigned char remote_input_iv[16];
    int width;
    int height;
    int fps;
    int bitrate_kbps;
} connection_args;

static void connection_started(void) {
    InterlockedExchange(&state, FARDESK_STATE_CONNECTED);
}

static void connection_terminated(int error_code) {
    InterlockedExchange(&last_error, error_code);
    InterlockedExchange(&state, error_code == 0 ? FARDESK_STATE_DISCONNECTED : FARDESK_STATE_FAILED);
}

static void stage_failed(int stage, int error_code) {
    (void)stage;
    InterlockedExchange(&last_error, error_code);
    InterlockedExchange(&state, FARDESK_STATE_FAILED);
}

static int decoder_setup(int video_format, int width, int height, int redraw_rate, void* context, int dr_flags) {
    (void)video_format;
    (void)width;
    (void)height;
    (void)redraw_rate;
    (void)context;
    (void)dr_flags;
    return 0;
}

static void decoder_start(void) {}
static void decoder_stop(void) {}
static void decoder_cleanup(void) {}

static int decoder_submit_decode_unit(PDECODE_UNIT decode_unit) {
    if (decode_unit != NULL) {
        InterlockedIncrement(&video_frame_count);
    }
    return DR_OK;
}

static int audio_init(int audio_configuration, const POPUS_MULTISTREAM_CONFIGURATION opus_config, void* context, int ar_flags) {
    (void)audio_configuration;
    (void)opus_config;
    (void)context;
    (void)ar_flags;
    return 0;
}

static void audio_start(void) {}
static void audio_stop(void) {}
static void audio_cleanup(void) {}
static void audio_decode_and_play_sample(char* sample_data, int sample_length) {
    (void)sample_data;
    (void)sample_length;
}

static DWORD WINAPI run_connection(void* raw_args) {
    connection_args* args = raw_args;
    SERVER_INFORMATION server;
    STREAM_CONFIGURATION config;
    CONNECTION_LISTENER_CALLBACKS callbacks;

    LiInitializeServerInformation(&server);
    LiInitializeConnectionCallbacks(&callbacks);
    LiInitializeStreamConfiguration(&config);

    server.address = args->address;
    server.rtspSessionUrl = args->session_url[0] == '\0' ? NULL : args->session_url;
    server.serverInfoAppVersion = "7.1.431";
    server.serverInfoGfeVersion = "3.22.0.0";
    server.serverCodecModeSupport = SCM_H264 | SCM_HEVC;

    config.width = args->width;
    config.height = args->height;
    config.fps = args->fps;
    config.bitrate = args->bitrate_kbps;
    config.packetSize = 1392;
    config.streamingRemotely = STREAM_CFG_AUTO;
    config.audioConfiguration = AUDIO_CONFIGURATION_STEREO;
    config.supportedVideoFormats = VIDEO_FORMAT_H264 | VIDEO_FORMAT_HEVC;
    config.encryptionFlags = ENCFLG_ALL;
    memcpy(config.remoteInputAesKey, args->remote_input_key, sizeof(args->remote_input_key));
    memcpy(config.remoteInputAesIv, args->remote_input_iv, sizeof(args->remote_input_iv));

    callbacks.stageFailed = stage_failed;
    callbacks.connectionStarted = connection_started;
    callbacks.connectionTerminated = connection_terminated;

    DECODER_RENDERER_CALLBACKS decoder;
    LiInitializeVideoCallbacks(&decoder);
    decoder.setup = decoder_setup;
    decoder.start = decoder_start;
    decoder.stop = decoder_stop;
    decoder.cleanup = decoder_cleanup;
    decoder.submitDecodeUnit = decoder_submit_decode_unit;

    AUDIO_RENDERER_CALLBACKS audio;
    LiInitializeAudioCallbacks(&audio);
    audio.init = audio_init;
    audio.start = audio_start;
    audio.stop = audio_stop;
    audio.cleanup = audio_cleanup;
    audio.decodeAndPlaySample = audio_decode_and_play_sample;

    const int result = LiStartConnection(
        &server,
        &config,
        &callbacks,
        &decoder,
        &audio,
        NULL,
        0,
        NULL,
        0
    );

    if (result != 0 && InterlockedCompareExchange(&state, 0, 0) != FARDESK_STATE_FAILED) {
        InterlockedExchange(&last_error, result);
        InterlockedExchange(&state, FARDESK_STATE_FAILED);
    }

    free(args->address);
    free(args->session_url);
    free(args);
    InterlockedExchange(&has_connection_thread, 0);
    return result;
}

FARDESK_EXPORT int fardesk_moonlight_state(void) {
    return InterlockedCompareExchange(&state, 0, 0);
}

FARDESK_EXPORT int fardesk_moonlight_last_error(void) {
    return InterlockedCompareExchange(&last_error, 0, 0);
}

FARDESK_EXPORT int fardesk_moonlight_video_frame_count(void) {
    return InterlockedCompareExchange(&video_frame_count, 0, 0);
}

FARDESK_EXPORT int fardesk_moonlight_start(
    const char* address,
    const char* session_url,
    const unsigned char* remote_input_key,
    const unsigned char* remote_input_iv,
    int width,
    int height,
    int fps,
    int bitrate_kbps
) {
    if (address == NULL || address[0] == '\0') return -1;
    if (session_url == NULL || remote_input_key == NULL || remote_input_iv == NULL) return -1;
    if (InterlockedCompareExchange(&has_connection_thread, 1, 0) != 0) return -2;

    connection_args* args = calloc(1, sizeof(*args));
    if (args == NULL) return -3;
    args->address = _strdup(address);
    args->session_url = _strdup(session_url);
    if (args->address == NULL || args->session_url == NULL) {
        free(args->address);
        free(args->session_url);
        free(args);
        return -3;
    }
    memcpy(args->remote_input_key, remote_input_key, sizeof(args->remote_input_key));
    memcpy(args->remote_input_iv, remote_input_iv, sizeof(args->remote_input_iv));
    args->width = width;
    args->height = height;
    args->fps = fps;
    args->bitrate_kbps = bitrate_kbps;

    InterlockedExchange(&last_error, 0);
    InterlockedExchange(&state, FARDESK_STATE_CONNECTING);
    HANDLE thread = CreateThread(NULL, 0, run_connection, args, 0, NULL);
    if (thread == NULL) {
        InterlockedExchange(&has_connection_thread, 0);
        free(args->address);
        free(args->session_url);
        free(args);
        InterlockedExchange(&state, FARDESK_STATE_FAILED);
        return -4;
    }
    CloseHandle(thread);
    return 0;
}

FARDESK_EXPORT void fardesk_moonlight_interrupt(void) {
    if (InterlockedCompareExchange(&state, 0, 0) == FARDESK_STATE_CONNECTING) {
        LiInterruptConnection();
        InterlockedExchange(&state, FARDESK_STATE_DISCONNECTED);
    }
}

FARDESK_EXPORT void fardesk_moonlight_stop(void) {
    if (!InterlockedCompareExchange(&has_connection_thread, 0, 0)) {
        InterlockedExchange(&state, FARDESK_STATE_DISCONNECTED);
        return;
    }
    if (InterlockedCompareExchange(&state, 0, 0) == FARDESK_STATE_CONNECTING) {
        // LiStopConnection is not safe while LiStartConnection is still
        // entering the connection. Interrupt first and let that thread unwind.
        LiInterruptConnection();
        return;
    }
    InterlockedExchange(&state, FARDESK_STATE_DISCONNECTING);
    LiStopConnection();
    InterlockedExchange(&state, FARDESK_STATE_DISCONNECTED);
}
