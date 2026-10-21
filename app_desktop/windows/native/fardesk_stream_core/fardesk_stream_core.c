#include <Limelight.h>

#include <share.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

// initguid.h faz com que os DEFINE_GUID dos headers a seguir gerem a
// definição real dos símbolos (CLSID_MMDeviceEnumerator, IID_IAudioClient
// etc.), não apenas a declaração extern — senão o link falha.
#include <initguid.h>
#include <mmdeviceapi.h>
#include <audioclient.h>
#include <mmreg.h>
#include <ksmedia.h>

#include <libavcodec/avcodec.h>
#include <libavutil/buffer.h>
#include <libavutil/frame.h>
#include <libavutil/hwcontext.h>
#include <libavutil/hwcontext_d3d11va.h>
#include <libavutil/pixdesc.h>
#include <libswscale/swscale.h>

#include <opus_multistream.h>

// Neste SDK, os headers da Core Audio API (mmdeviceapi.h/Audioclient.h) e o
// ksmedia.h só *declaram* essas GUIDs como extern para código C puro (a
// definição automática via INITGUID só existe para consumidores C++ via
// __uuidof). Por isso fornecemos a definição aqui mesmo, com os valores
// estáveis e documentados da Core Audio API / WASAPI.
DEFINE_GUID(CLSID_MMDeviceEnumerator, 0xbcde0395, 0xe52f, 0x467c, 0x8e, 0x3d, 0xc4, 0x57, 0x92, 0x91, 0x69, 0x2e);
DEFINE_GUID(IID_IMMDeviceEnumerator, 0xa95664d2, 0x9614, 0x4f35, 0xa7, 0x46, 0xde, 0x8d, 0xb6, 0x36, 0x17, 0xe6);
DEFINE_GUID(IID_IAudioClient, 0x1cb9ad4c, 0xdbfa, 0x4c32, 0xb1, 0x78, 0xc2, 0xf5, 0x68, 0xa7, 0x03, 0xb2);
DEFINE_GUID(IID_IAudioRenderClient, 0xf294acfc, 0x3146, 0x4483, 0xa7, 0xbf, 0xad, 0xdc, 0xa7, 0xc2, 0x60, 0xe2);
DEFINE_GUID(KSDATAFORMAT_SUBTYPE_PCM, 0x00000001, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71);

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
static volatile LONG last_failed_stage = STAGE_NONE;
static volatile LONG has_connection_thread = 0;
static volatile LONG video_frame_count = 0;
static volatile LONG video_frame_version = 0;

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

// ---------------------------------------------------------------------------
// Log: tudo que o core e o moonlight-common-c reportam vai pra
// %TEMP%\fardesk_stream_core.log — o processo é GUI, então stdout/stderr do
// DLL não aparecem em lugar nenhum.
// ---------------------------------------------------------------------------

static SRWLOCK log_lock = SRWLOCK_INIT;
static FILE* log_file = NULL;
static char log_path[MAX_PATH] = {0};

static void fardesk_log(const char* format, ...) {
    AcquireSRWLockExclusive(&log_lock);
    if (log_file == NULL) {
        DWORD length = GetTempPathA(MAX_PATH, log_path);
        if (length > 0 && length < MAX_PATH - 32) {
            strcat_s(log_path, MAX_PATH, "fardesk_stream_core.log");
            // _SH_DENYNO: fopen_s abre em modo exclusivo, o que impede de
            // ler o log (tail, editor) enquanto o app está rodando.
            log_file = _fsopen(log_path, "a", _SH_DENYNO);
        }
    }
    if (log_file != NULL) {
        SYSTEMTIME now;
        GetLocalTime(&now);
        fprintf(log_file, "[%02d:%02d:%02d.%03d] ", now.wHour, now.wMinute, now.wSecond, now.wMilliseconds);
        va_list args;
        va_start(args, format);
        vfprintf(log_file, format, args);
        va_end(args);
        size_t format_length = strlen(format);
        if (format_length == 0 || format[format_length - 1] != '\n') {
            fputc('\n', log_file);
        }
        fflush(log_file);
    }
    ReleaseSRWLockExclusive(&log_lock);
}

// ---------------------------------------------------------------------------
// Vídeo: decodificação via FFmpeg (H.264/HEVC) com aceleração de hardware
// D3D11VA, convertido para BGRA e exposto para o Dart via cópia sob lock.
// ---------------------------------------------------------------------------

// SRWLOCK com inicialização estática: o Dart pode consultar dimensões/frame
// antes do decoder_setup (ou depois do cleanup), então o lock tem que existir
// a vida toda do processo.
static SRWLOCK video_frame_lock = SRWLOCK_INIT;

static AVBufferRef* hw_device_ctx = NULL;
static AVCodecContext* video_decoder_ctx = NULL;
static AVFrame* hw_frame = NULL;
static AVFrame* sw_frame = NULL;
static struct SwsContext* sws_ctx = NULL;
static int sws_src_w = 0;
static int sws_src_h = 0;
static enum AVPixelFormat sws_src_fmt = AV_PIX_FMT_NONE;

static uint8_t* video_frame_buffer = NULL;
static int video_frame_width = 0;
static int video_frame_height = 0;

static uint8_t* decode_unit_scratch = NULL;
static int decode_unit_scratch_capacity = 0;

static void connection_started(void) {
    fardesk_log("Conexão iniciada.");
    InterlockedExchange(&state, FARDESK_STATE_CONNECTED);
}

static void connection_terminated(int error_code) {
    fardesk_log("Conexão encerrada (código %d).", error_code);
    InterlockedExchange(&last_error, error_code);
    InterlockedExchange(&state, error_code == 0 ? FARDESK_STATE_DISCONNECTED : FARDESK_STATE_FAILED);
}

static void stage_starting(int stage) {
    fardesk_log("Iniciando etapa: %s", LiGetStageName(stage));
}

static void stage_complete(int stage) {
    fardesk_log("Etapa concluída: %s", LiGetStageName(stage));
}

static void stage_failed(int stage, int error_code) {
    fardesk_log("Etapa FALHOU: %s (código %d)", LiGetStageName(stage), error_code);
    InterlockedExchange(&last_failed_stage, stage);
    InterlockedExchange(&last_error, error_code);
    InterlockedExchange(&state, FARDESK_STATE_FAILED);
}

static enum AVPixelFormat get_hw_pixel_format(AVCodecContext* ctx, const enum AVPixelFormat* pix_fmts) {
    (void)ctx;
    for (const enum AVPixelFormat* p = pix_fmts; *p != AV_PIX_FMT_NONE; p++) {
        if (*p == AV_PIX_FMT_D3D11) {
            fardesk_log("get_format: usando D3D11VA (decode por hardware).");
            return *p;
        }
    }
    fardesk_log("get_format: D3D11VA NÃO oferecido — caindo pra decode por software (%s).",
                av_get_pix_fmt_name(pix_fmts[0]));
    return pix_fmts[0];
}

static int decoder_setup(int video_format, int width, int height, int redraw_rate, void* context, int dr_flags) {
    (void)redraw_rate;
    (void)context;
    (void)dr_flags;

    enum AVCodecID codec_id = (video_format & VIDEO_FORMAT_MASK_H265) ? AV_CODEC_ID_HEVC : AV_CODEC_ID_H264;
    fardesk_log("decoder_setup: formato=0x%x (%s) %dx%d", video_format,
                codec_id == AV_CODEC_ID_HEVC ? "HEVC" : "H.264", width, height);

    int hw_result = av_hwdevice_ctx_create(&hw_device_ctx, AV_HWDEVICE_TYPE_D3D11VA, NULL, NULL, 0);
    if (hw_result < 0) {
        fardesk_log("decoder_setup: av_hwdevice_ctx_create(D3D11VA) falhou (%d).", hw_result);
        return -1;
    }

    const AVCodec* codec = avcodec_find_decoder(codec_id);
    if (codec == NULL) {
        fardesk_log("decoder_setup: decoder não encontrado no FFmpeg.");
        av_buffer_unref(&hw_device_ctx);
        return -1;
    }

    video_decoder_ctx = avcodec_alloc_context3(codec);
    if (video_decoder_ctx == NULL) {
        fardesk_log("decoder_setup: avcodec_alloc_context3 falhou.");
        av_buffer_unref(&hw_device_ctx);
        return -1;
    }

    video_decoder_ctx->width = width;
    video_decoder_ctx->height = height;
    // Baixa latência: sem buffering de múltiplos frames nem threads de frame
    // (que introduzem atraso para reordenar saída); o host já envia em ordem
    // de decodificação e sem B-frames.
    video_decoder_ctx->thread_count = 1;
    video_decoder_ctx->flags |= AV_CODEC_FLAG_LOW_DELAY;
    video_decoder_ctx->flags2 |= AV_CODEC_FLAG2_FAST;
    video_decoder_ctx->get_format = get_hw_pixel_format;
    video_decoder_ctx->hw_device_ctx = av_buffer_ref(hw_device_ctx);

    int open_result = avcodec_open2(video_decoder_ctx, codec, NULL);
    if (open_result < 0) {
        fardesk_log("decoder_setup: avcodec_open2 falhou (%d).", open_result);
        avcodec_free_context(&video_decoder_ctx);
        av_buffer_unref(&hw_device_ctx);
        return -1;
    }

    hw_frame = av_frame_alloc();
    sw_frame = av_frame_alloc();

    AcquireSRWLockExclusive(&video_frame_lock);
    video_frame_width = width;
    video_frame_height = height;
    video_frame_buffer = av_malloc((size_t)width * (size_t)height * 4);
    ReleaseSRWLockExclusive(&video_frame_lock);

    fardesk_log("decoder_setup: OK.");
    return 0;
}

static void decoder_start(void) {}
static void decoder_stop(void) {}

static void decoder_cleanup(void) {
    if (video_decoder_ctx != NULL) {
        avcodec_free_context(&video_decoder_ctx);
    }
    if (hw_device_ctx != NULL) {
        av_buffer_unref(&hw_device_ctx);
    }
    if (hw_frame != NULL) {
        av_frame_free(&hw_frame);
    }
    if (sw_frame != NULL) {
        av_frame_free(&sw_frame);
    }
    if (sws_ctx != NULL) {
        sws_freeContext(sws_ctx);
        sws_ctx = NULL;
    }
    sws_src_w = 0;
    sws_src_h = 0;
    sws_src_fmt = AV_PIX_FMT_NONE;

    av_freep(&decode_unit_scratch);
    decode_unit_scratch_capacity = 0;

    AcquireSRWLockExclusive(&video_frame_lock);
    av_freep(&video_frame_buffer);
    video_frame_width = 0;
    video_frame_height = 0;
    ReleaseSRWLockExclusive(&video_frame_lock);
}

static void handle_decoded_video_frame(AVFrame* decoded) {
    if (sws_ctx == NULL || sws_src_w != decoded->width || sws_src_h != decoded->height ||
        sws_src_fmt != decoded->format) {
        if (sws_ctx != NULL) {
            sws_freeContext(sws_ctx);
        }
        sws_ctx = sws_getContext(
            decoded->width, decoded->height, (enum AVPixelFormat)decoded->format,
            decoded->width, decoded->height, AV_PIX_FMT_BGRA,
            SWS_FAST_BILINEAR, NULL, NULL, NULL
        );
        sws_src_w = decoded->width;
        sws_src_h = decoded->height;
        sws_src_fmt = (enum AVPixelFormat)decoded->format;
    }
    if (sws_ctx == NULL) {
        return;
    }

    AcquireSRWLockExclusive(&video_frame_lock);
    if (video_frame_buffer == NULL || video_frame_width != decoded->width || video_frame_height != decoded->height) {
        av_freep(&video_frame_buffer);
        video_frame_width = decoded->width;
        video_frame_height = decoded->height;
        video_frame_buffer = av_malloc((size_t)video_frame_width * (size_t)video_frame_height * 4);
    }
    if (video_frame_buffer != NULL) {
        uint8_t* dst_slices[1] = { video_frame_buffer };
        int dst_strides[1] = { video_frame_width * 4 };
        sws_scale(sws_ctx, (const uint8_t* const*)decoded->data, decoded->linesize, 0, decoded->height, dst_slices, dst_strides);
        InterlockedIncrement(&video_frame_version);
    }
    ReleaseSRWLockExclusive(&video_frame_lock);
}

// Estatísticas de desempenho do pipeline de vídeo, logadas a cada
// STATS_WINDOW frames — é o que mostra onde está o gargalo quando o
// moonlight-common-c reporta "Video decode unit queue overflow".
#define STATS_WINDOW 120
static double stats_decode_ms = 0;
static double stats_transfer_ms = 0;
static double stats_convert_ms = 0;
static int stats_frames = 0;
static int stats_send_errors = 0;
static enum AVPixelFormat stats_last_format = AV_PIX_FMT_NONE;

static double now_ms(void) {
    static LARGE_INTEGER frequency = {0};
    if (frequency.QuadPart == 0) {
        QueryPerformanceFrequency(&frequency);
    }
    LARGE_INTEGER counter;
    QueryPerformanceCounter(&counter);
    return (double)counter.QuadPart * 1000.0 / (double)frequency.QuadPart;
}

static void stats_record_frame(double decode_ms, double transfer_ms, double convert_ms, enum AVPixelFormat format) {
    if (format != stats_last_format) {
        fardesk_log("vídeo: formato dos frames decodificados = %s", av_get_pix_fmt_name(format));
        stats_last_format = format;
    }
    stats_decode_ms += decode_ms;
    stats_transfer_ms += transfer_ms;
    stats_convert_ms += convert_ms;
    stats_frames++;
    if (stats_frames >= STATS_WINDOW) {
        fardesk_log("vídeo: média por frame em %d frames — decode %.2f ms, cópia GPU→CPU %.2f ms, conversão BGRA %.2f ms (erros de envio: %d)",
                    stats_frames, stats_decode_ms / stats_frames, stats_transfer_ms / stats_frames,
                    stats_convert_ms / stats_frames, stats_send_errors);
        stats_decode_ms = stats_transfer_ms = stats_convert_ms = 0;
        stats_frames = 0;
        stats_send_errors = 0;
    }
}

static int decoder_submit_decode_unit(PDECODE_UNIT decode_unit) {
    if (decode_unit == NULL || video_decoder_ctx == NULL) {
        return DR_OK;
    }
    InterlockedIncrement(&video_frame_count);
    const double decode_started = now_ms();

    if (decode_unit_scratch_capacity < decode_unit->fullLength) {
        uint8_t* bigger = av_realloc(decode_unit_scratch, (size_t)decode_unit->fullLength);
        if (bigger == NULL) {
            return DR_OK;
        }
        decode_unit_scratch = bigger;
        decode_unit_scratch_capacity = decode_unit->fullLength;
    }

    int offset = 0;
    for (PLENTRY entry = decode_unit->bufferList; entry != NULL; entry = entry->next) {
        memcpy(decode_unit_scratch + offset, entry->data, (size_t)entry->length);
        offset += entry->length;
    }

    AVPacket* packet = av_packet_alloc();
    if (packet == NULL) {
        return DR_OK;
    }
    packet->data = decode_unit_scratch;
    packet->size = offset;

    int send_result = avcodec_send_packet(video_decoder_ctx, packet);
    av_packet_free(&packet);
    if (send_result < 0) {
        stats_send_errors++;
        if (stats_send_errors <= 3) {
            fardesk_log("vídeo: avcodec_send_packet falhou (%d) no frame %d.", send_result, decode_unit->frameNumber);
        }
        return (decode_unit->frameType == FRAME_TYPE_IDR) ? DR_OK : DR_NEED_IDR;
    }

    for (;;) {
        int recv_result = avcodec_receive_frame(video_decoder_ctx, hw_frame);
        if (recv_result == AVERROR(EAGAIN) || recv_result == AVERROR_EOF) {
            break;
        }
        if (recv_result < 0) {
            fardesk_log("vídeo: avcodec_receive_frame falhou (%d).", recv_result);
            break;
        }
        const double decode_ms = now_ms() - decode_started;

        const double transfer_started = now_ms();
        AVFrame* decoded = hw_frame;
        if (hw_frame->format == AV_PIX_FMT_D3D11) {
            if (av_hwframe_transfer_data(sw_frame, hw_frame, 0) == 0) {
                decoded = sw_frame;
            } else {
                av_frame_unref(hw_frame);
                continue;
            }
        }
        const double transfer_ms = now_ms() - transfer_started;

        const double convert_started = now_ms();
        handle_decoded_video_frame(decoded);
        stats_record_frame(decode_ms, transfer_ms, now_ms() - convert_started,
                           (enum AVPixelFormat)hw_frame->format);

        av_frame_unref(hw_frame);
        if (decoded == sw_frame) {
            av_frame_unref(sw_frame);
        }
    }

    return DR_OK;
}

// ---------------------------------------------------------------------------
// Áudio: decodificação Opus multistream (mesma API usada pelo moonlight-qt)
// com playback direto via WASAPI, sem envolver o lado Dart.
// ---------------------------------------------------------------------------

static OpusMSDecoder* opus_decoder = NULL;
static int audio_channel_count = 0;

static bool audio_com_initialized = false;
static IMMDeviceEnumerator* mm_enumerator = NULL;
static IMMDevice* mm_device = NULL;
static IAudioClient* audio_client = NULL;
static IAudioRenderClient* audio_render_client = NULL;
static UINT32 audio_buffer_frame_count = 0;

static int16_t* opus_pcm_buffer = NULL;
static int opus_pcm_buffer_capacity_samples = 0;

static void audio_cleanup(void);

// Falha de áudio não derruba a sessão: o vídeo é o que importa pra controlar
// o PC remoto. Loga o motivo, libera o que já foi criado e segue sem som
// (audio_decode_and_play_sample ignora tudo quando não há render client).
static int audio_disable(const char* step, HRESULT hr) {
    fardesk_log("audio_init: %s falhou (HRESULT 0x%08lx) — seguindo sem áudio.", step, (unsigned long)hr);
    audio_cleanup();
    return 0;
}

static int audio_init(int audio_configuration, const POPUS_MULTISTREAM_CONFIGURATION opus_config, void* context, int ar_flags) {
    (void)audio_configuration;
    (void)context;
    (void)ar_flags;

    if (opus_config == NULL) {
        return audio_disable("opus_config ausente", E_POINTER);
    }
    fardesk_log("audio_init: %d Hz, %d canais, %d streams (%d acoplados), %d amostras/frame",
                opus_config->sampleRate, opus_config->channelCount, opus_config->streams,
                opus_config->coupledStreams, opus_config->samplesPerFrame);

    HRESULT hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
    audio_com_initialized = (hr == S_OK || hr == S_FALSE);

    int opus_error = 0;
    opus_decoder = opus_multistream_decoder_create(
        opus_config->sampleRate,
        opus_config->channelCount,
        opus_config->streams,
        opus_config->coupledStreams,
        opus_config->mapping,
        &opus_error
    );
    if (opus_error != OPUS_OK || opus_decoder == NULL) {
        fardesk_log("audio_init: opus_multistream_decoder_create falhou (%d).", opus_error);
        return audio_disable("decoder Opus", E_FAIL);
    }
    audio_channel_count = opus_config->channelCount;

    hr = CoCreateInstance(&CLSID_MMDeviceEnumerator, NULL, CLSCTX_ALL, &IID_IMMDeviceEnumerator, (void**)&mm_enumerator);
    if (FAILED(hr)) {
        return audio_disable("CoCreateInstance(MMDeviceEnumerator)", hr);
    }
    hr = mm_enumerator->lpVtbl->GetDefaultAudioEndpoint(mm_enumerator, eRender, eConsole, &mm_device);
    if (FAILED(hr)) {
        return audio_disable("GetDefaultAudioEndpoint", hr);
    }
    hr = mm_device->lpVtbl->Activate(mm_device, &IID_IAudioClient, CLSCTX_ALL, NULL, (void**)&audio_client);
    if (FAILED(hr)) {
        return audio_disable("IMMDevice::Activate(IAudioClient)", hr);
    }

    WAVEFORMATEXTENSIBLE desired;
    ZeroMemory(&desired, sizeof(desired));
    desired.Format.wFormatTag = WAVE_FORMAT_EXTENSIBLE;
    desired.Format.nChannels = (WORD)opus_config->channelCount;
    desired.Format.nSamplesPerSec = (DWORD)opus_config->sampleRate;
    desired.Format.wBitsPerSample = 16;
    desired.Format.nBlockAlign = (WORD)(opus_config->channelCount * 2);
    desired.Format.nAvgBytesPerSec = desired.Format.nSamplesPerSec * desired.Format.nBlockAlign;
    desired.Format.cbSize = sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX);
    desired.Samples.wValidBitsPerSample = 16;
    desired.dwChannelMask = (opus_config->channelCount == 2)
        ? (SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT)
        : (DWORD)((1u << opus_config->channelCount) - 1u);
    desired.SubFormat = KSDATAFORMAT_SUBTYPE_PCM;

    // Buffer pequeno (20ms): prioriza latência baixa sobre robustez contra
    // glitches de scheduling, igual ao objetivo do projeto.
    //
    // AUTOCONVERTPCM: em modo compartilhado, sem essa flag o WASAPI só aceita
    // exatamente o formato do mixer (normalmente float 32-bit), e Initialize
    // falha com AUDCLNT_E_UNSUPPORTED_FORMAT pro PCM 16-bit que o Opus gera.
    REFERENCE_TIME buffer_duration = 20 * 10000;
    hr = audio_client->lpVtbl->Initialize(
        audio_client, AUDCLNT_SHAREMODE_SHARED,
        AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM | AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY,
        buffer_duration, 0, (WAVEFORMATEX*)&desired, NULL
    );
    if (FAILED(hr)) {
        return audio_disable("IAudioClient::Initialize", hr);
    }

    hr = audio_client->lpVtbl->GetBufferSize(audio_client, &audio_buffer_frame_count);
    if (FAILED(hr)) {
        return audio_disable("IAudioClient::GetBufferSize", hr);
    }

    hr = audio_client->lpVtbl->GetService(audio_client, &IID_IAudioRenderClient, (void**)&audio_render_client);
    if (FAILED(hr)) {
        return audio_disable("IAudioClient::GetService(IAudioRenderClient)", hr);
    }

    opus_pcm_buffer_capacity_samples = 8192;
    opus_pcm_buffer = (int16_t*)malloc((size_t)opus_pcm_buffer_capacity_samples * (size_t)audio_channel_count * sizeof(int16_t));
    if (opus_pcm_buffer == NULL) {
        return audio_disable("malloc do buffer PCM", E_OUTOFMEMORY);
    }

    fardesk_log("audio_init: OK (buffer de %u frames).", audio_buffer_frame_count);
    return 0;
}

static void audio_start(void) {
    if (audio_client != NULL) {
        audio_client->lpVtbl->Start(audio_client);
    }
}

static void audio_stop(void) {
    if (audio_client != NULL) {
        audio_client->lpVtbl->Stop(audio_client);
    }
}

static void audio_cleanup(void) {
    if (audio_render_client != NULL) {
        audio_render_client->lpVtbl->Release(audio_render_client);
        audio_render_client = NULL;
    }
    if (audio_client != NULL) {
        audio_client->lpVtbl->Release(audio_client);
        audio_client = NULL;
    }
    if (mm_device != NULL) {
        mm_device->lpVtbl->Release(mm_device);
        mm_device = NULL;
    }
    if (mm_enumerator != NULL) {
        mm_enumerator->lpVtbl->Release(mm_enumerator);
        mm_enumerator = NULL;
    }
    if (opus_decoder != NULL) {
        opus_multistream_decoder_destroy(opus_decoder);
        opus_decoder = NULL;
    }
    free(opus_pcm_buffer);
    opus_pcm_buffer = NULL;
    opus_pcm_buffer_capacity_samples = 0;
    audio_channel_count = 0;

    if (audio_com_initialized) {
        CoUninitialize();
        audio_com_initialized = false;
    }
}

static void audio_decode_and_play_sample(char* sample_data, int sample_length) {
    if (opus_decoder == NULL || audio_render_client == NULL || opus_pcm_buffer == NULL || audio_client == NULL) {
        return;
    }

    int decoded_samples = opus_multistream_decode(
        opus_decoder,
        (const unsigned char*)sample_data,
        sample_length,
        opus_pcm_buffer,
        opus_pcm_buffer_capacity_samples,
        0
    );
    if (decoded_samples <= 0) {
        return;
    }

    UINT32 padding_frames = 0;
    if (FAILED(audio_client->lpVtbl->GetCurrentPadding(audio_client, &padding_frames))) {
        return;
    }
    if (padding_frames >= audio_buffer_frame_count) {
        return;
    }
    UINT32 frames_free = audio_buffer_frame_count - padding_frames;
    UINT32 frames_to_write = (UINT32)decoded_samples;
    if (frames_to_write > frames_free) {
        frames_to_write = frames_free;
    }
    if (frames_to_write == 0) {
        return;
    }

    BYTE* buffer = NULL;
    if (FAILED(audio_render_client->lpVtbl->GetBuffer(audio_render_client, frames_to_write, &buffer))) {
        return;
    }
    memcpy(buffer, opus_pcm_buffer, (size_t)frames_to_write * (size_t)audio_channel_count * sizeof(int16_t));
    audio_render_client->lpVtbl->ReleaseBuffer(audio_render_client, frames_to_write, 0);
}

// ---------------------------------------------------------------------------
// Conexão / exportações FFI
// ---------------------------------------------------------------------------

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
    config.supportedVideoFormats = VIDEO_FORMAT_H264 | VIDEO_FORMAT_H265;
    config.encryptionFlags = ENCFLG_ALL;
    memcpy(config.remoteInputAesKey, args->remote_input_key, sizeof(args->remote_input_key));
    memcpy(config.remoteInputAesIv, args->remote_input_iv, sizeof(args->remote_input_iv));

    callbacks.stageStarting = stage_starting;
    callbacks.stageComplete = stage_complete;
    callbacks.stageFailed = stage_failed;
    callbacks.connectionStarted = connection_started;
    callbacks.connectionTerminated = connection_terminated;
    callbacks.logMessage = fardesk_log;

    fardesk_log("==== Nova conexão: host=%s sessionUrl=%s %dx%d@%d %d kbps ====",
                args->address, args->session_url[0] == '\0' ? "(nenhuma)" : args->session_url,
                args->width, args->height, args->fps, args->bitrate_kbps);

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

    fardesk_log("LiStartConnection retornou %d.", result);
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

// Nome estável da etapa do moonlight-common-c que falhou por último (ex:
// "RTSP handshake"), ou "none" se a falha não veio de uma etapa.
FARDESK_EXPORT const char* fardesk_moonlight_last_failed_stage(void) {
    return LiGetStageName(InterlockedCompareExchange(&last_failed_stage, 0, 0));
}

// Caminho do arquivo de log do core (vazio até a primeira linha ser escrita).
FARDESK_EXPORT const char* fardesk_moonlight_log_path(void) {
    return log_path;
}

FARDESK_EXPORT int fardesk_moonlight_video_frame_count(void) {
    return InterlockedCompareExchange(&video_frame_count, 0, 0);
}

FARDESK_EXPORT int fardesk_moonlight_video_frame_version(void) {
    return InterlockedCompareExchange(&video_frame_version, 0, 0);
}

FARDESK_EXPORT int fardesk_moonlight_video_dimensions(int* out_width, int* out_height) {
    AcquireSRWLockShared(&video_frame_lock);
    if (out_width != NULL) {
        *out_width = video_frame_width;
    }
    if (out_height != NULL) {
        *out_height = video_frame_height;
    }
    ReleaseSRWLockShared(&video_frame_lock);
    return 0;
}

// Copia o último frame decodificado (BGRA) para o buffer fornecido pelo Dart.
// Retorna o número de bytes copiados, ou 0 se ainda não há frame ou o buffer
// é pequeno demais.
FARDESK_EXPORT int fardesk_moonlight_copy_video_frame(uint8_t* dst, int dst_capacity) {
    int copied = 0;
    AcquireSRWLockShared(&video_frame_lock);
    size_t needed = (size_t)video_frame_width * (size_t)video_frame_height * 4;
    if (video_frame_buffer != NULL && dst != NULL && needed > 0 && (size_t)dst_capacity >= needed) {
        memcpy(dst, video_frame_buffer, needed);
        copied = (int)needed;
    }
    ReleaseSRWLockShared(&video_frame_lock);
    return copied;
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
    InterlockedExchange(&last_failed_stage, STAGE_NONE);
    InterlockedExchange(&video_frame_count, 0);
    InterlockedExchange(&video_frame_version, 0);
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
