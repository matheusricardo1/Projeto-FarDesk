import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'moonlight_client.dart';

/// Ponte Windows para o `fardesk_stream_core.dll`.
///
/// O DLL deliberadamente não é carregado no construtor: isso permite abrir o
/// app e usar o restante do FarDesk mesmo quando o runtime nativo ainda não
/// foi distribuído. A conexão falha explicitamente até o core estar presente.
class WindowsMoonlightClient implements MoonlightClient {
  WindowsMoonlightClient({DynamicLibrary? library}) : _library = library;

  final DynamicLibrary? _library;
  final ValueNotifier<MoonlightConnectionState> _state = ValueNotifier(
    MoonlightConnectionState.disconnected,
  );
  final ValueNotifier<Object?> _error = ValueNotifier(null);
  final ValueNotifier<MoonlightVideoFrame?> _latestVideoFrame = ValueNotifier(null);

  DynamicLibrary? _loadedLibrary;
  bool _connecting = false;
  bool _cancelRequested = false;
  bool _disposed = false;
  Timer? _statePoller;
  int _lastVideoFrameVersion = 0;
  Uint8List? _videoFrameScratch;
  Pointer<Uint8> _videoFrameNativeBuffer = nullptr;
  int _videoFrameNativeBufferCapacity = 0;

  static const _statePollInterval = Duration(milliseconds: 16);

  @override
  ValueListenable<MoonlightConnectionState> get state => _state;

  @override
  ValueListenable<Object?> get error => _error;

  @override
  ValueListenable<MoonlightVideoFrame?> get latestVideoFrame => _latestVideoFrame;

  @override
  Future<void> connect(MoonlightConnectionConfig config) async {
    if (_disposed) {
      throw const MoonlightClientException(
        'O cliente Moonlight já foi descartado.',
      );
    }
    if (_connecting || _state.value == MoonlightConnectionState.connected)
      return;
    _validateConfig(config);
    _connecting = true;
    _cancelRequested = false;
    _error.value = null;
    _state.value = MoonlightConnectionState.connecting;

    try {
      _loadedLibrary = _library ?? _openLibrary();
      final start = _loadedLibrary!
          .lookupFunction<
            Int32 Function(
              Pointer<Utf8>,
              Pointer<Utf8>,
              Pointer<Uint8>,
              Pointer<Uint8>,
              Int32,
              Int32,
              Int32,
              Int32,
            ),
            int Function(
              Pointer<Utf8>,
              Pointer<Utf8>,
              Pointer<Uint8>,
              Pointer<Uint8>,
              int,
              int,
              int,
              int,
            )
          >('fardesk_moonlight_start');
      final state = _loadedLibrary!
          .lookupFunction<Int32 Function(), int Function()>(
            'fardesk_moonlight_state',
          );
      final lastError = _loadedLibrary!
          .lookupFunction<Int32 Function(), int Function()>(
            'fardesk_moonlight_last_error',
          );
      final address = config.host.toNativeUtf8();
      final sessionUrl = (config.sessionUrl ?? '').toNativeUtf8();
      final remoteInputKey = calloc<Uint8>(16);
      final remoteInputIv = calloc<Uint8>(16);
      try {
        if (config.remoteInputKey case final key?) {
          if (key.length != 16) {
            throw const MoonlightClientException(
              'A chave de input remoto precisa ter 16 bytes.',
            );
          }
          remoteInputKey.asTypedList(16).setAll(0, key);
        }
        if (config.remoteInputIv case final iv?) {
          if (iv.length != 16) {
            throw const MoonlightClientException(
              'O IV de input remoto precisa ter 16 bytes.',
            );
          }
          remoteInputIv.asTypedList(16).setAll(0, iv);
        }
        final result = start(
          address,
          sessionUrl,
          remoteInputKey,
          remoteInputIv,
          config.width,
          config.height,
          config.fps,
          config.bitrateKbps,
        );
        if (result != 0) {
          throw MoonlightClientException(
            'Não foi possível iniciar o core Moonlight (código $result).',
          );
        }
        await _waitForNativeState(state, lastError);
        _startStatePolling(state, lastError);
      } finally {
        calloc.free(address);
        calloc.free(sessionUrl);
        calloc.free(remoteInputKey);
        calloc.free(remoteInputIv);
      }
    } catch (error) {
      if (_cancelRequested) {
        _state.value = MoonlightConnectionState.disconnected;
        return;
      }
      _state.value = MoonlightConnectionState.failed;
      _error.value = error;
      rethrow;
    } finally {
      _connecting = false;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_state.value == MoonlightConnectionState.disconnected) return;
    _cancelRequested = true;
    _state.value = MoonlightConnectionState.disconnecting;
    try {
      _statePoller?.cancel();
      _statePoller = null;
      _loadedLibrary?.lookupFunction<Void Function(), void Function()>(
        'fardesk_moonlight_stop',
      )();
    } finally {
      _state.value = MoonlightConnectionState.disconnected;
    }
  }

  @override
  Future<void> interrupt() async {
    _cancelRequested = true;
    _statePoller?.cancel();
    _statePoller = null;
    _loadedLibrary?.lookupFunction<Void Function(), void Function()>(
      'fardesk_moonlight_interrupt',
    )();
    if (_state.value == MoonlightConnectionState.connecting) {
      _state.value = MoonlightConnectionState.disconnected;
    }
  }

  void _startStatePolling(int Function() state, int Function() lastError) {
    _statePoller?.cancel();

    final library = _loadedLibrary!;
    final frameVersion = library.lookupFunction<Int32 Function(), int Function()>(
      'fardesk_moonlight_video_frame_version',
    );
    final frameDimensions = library.lookupFunction<
        Int32 Function(Pointer<Int32>, Pointer<Int32>),
        int Function(Pointer<Int32>, Pointer<Int32>)>(
      'fardesk_moonlight_video_dimensions',
    );
    final copyFrame = library.lookupFunction<
        Int32 Function(Pointer<Uint8>, Int32),
        int Function(Pointer<Uint8>, int)>(
      'fardesk_moonlight_copy_video_frame',
    );
    final widthPtr = calloc<Int32>();
    final heightPtr = calloc<Int32>();

    void pollVideoFrame() {
      final version = frameVersion();
      if (version == _lastVideoFrameVersion) return;

      frameDimensions(widthPtr, heightPtr);
      final width = widthPtr.value;
      final height = heightPtr.value;
      if (width <= 0 || height <= 0) return;

      final byteCount = width * height * 4;
      var scratch = _videoFrameScratch;
      if (scratch == null || scratch.length != byteCount) {
        scratch = Uint8List(byteCount);
        _videoFrameScratch = scratch;
      }

      if (_videoFrameNativeBufferCapacity < byteCount) {
        if (_videoFrameNativeBuffer != nullptr) {
          calloc.free(_videoFrameNativeBuffer);
        }
        _videoFrameNativeBuffer = calloc<Uint8>(byteCount);
        _videoFrameNativeBufferCapacity = byteCount;
      }

      final copied = copyFrame(_videoFrameNativeBuffer, _videoFrameNativeBufferCapacity);
      if (copied != byteCount) return;
      scratch.setAll(0, _videoFrameNativeBuffer.asTypedList(byteCount));
      _lastVideoFrameVersion = version;
      _latestVideoFrame.value = MoonlightVideoFrame(
        width: width,
        height: height,
        bgra: Uint8List.fromList(scratch),
      );
    }

    void releaseVideoFramePollingResources() {
      calloc.free(widthPtr);
      calloc.free(heightPtr);
      if (_videoFrameNativeBuffer != nullptr) {
        calloc.free(_videoFrameNativeBuffer);
        _videoFrameNativeBuffer = nullptr;
        _videoFrameNativeBufferCapacity = 0;
      }
      _lastVideoFrameVersion = 0;
      _latestVideoFrame.value = null;
    }

    void poll() {
      if (_state.value == MoonlightConnectionState.disconnecting ||
          _state.value == MoonlightConnectionState.disconnected) {
        releaseVideoFramePollingResources();
        return;
      }
      final nativeState = state();
      if (nativeState == 2) {
        _state.value = MoonlightConnectionState.connected;
        pollVideoFrame();
      } else if (nativeState == 4) {
        _state.value = MoonlightConnectionState.failed;
        _error.value = MoonlightClientException(_nativeFailureMessage(lastError()));
        _statePoller?.cancel();
        _statePoller = null;
        releaseVideoFramePollingResources();
      } else if (nativeState == 0) {
        _state.value = MoonlightConnectionState.disconnected;
        _statePoller?.cancel();
        _statePoller = null;
        releaseVideoFramePollingResources();
      }
    }

    poll();
    _statePoller = Timer.periodic(_statePollInterval, (_) => poll());
  }

  Future<void> _waitForNativeState(
    int Function() state,
    int Function() lastError,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (DateTime.now().isBefore(deadline)) {
      final nativeState = state();
      if (nativeState == 2) return;
      if (nativeState == 0) {
        throw const MoonlightClientException(
          'A conexão Moonlight foi interrompida antes de iniciar.',
        );
      }
      if (nativeState == 4) {
        throw MoonlightClientException(_nativeFailureMessage(lastError()));
      }
      await Future<void>.delayed(_statePollInterval);
    }

    throw const MoonlightClientException(
      'Tempo esgotado ao conectar ao host Moonlight.',
    );
  }

  void _validateConfig(MoonlightConnectionConfig config) {
    if (config.host.trim().isEmpty) {
      throw const MoonlightClientException(
        'O host Moonlight não pode ser vazio.',
      );
    }
    if (config.width <= 0 ||
        config.height <= 0 ||
        config.fps <= 0 ||
        config.bitrateKbps <= 0) {
      throw const MoonlightClientException(
        'A resolução, FPS e bitrate precisam ser maiores que zero.',
      );
    }
  }

  /// Inclui a etapa do moonlight-common-c que falhou e onde está o log
  /// detalhado do core nativo — só o código numérico não diz nada.
  String _nativeFailureMessage(int errorCode) {
    final library = _loadedLibrary;
    var stage = 'desconhecida';
    var logPath = '';
    if (library != null) {
      stage = library
          .lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
            'fardesk_moonlight_last_failed_stage',
          )()
          .toDartString();
      logPath = library
          .lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
            'fardesk_moonlight_log_path',
          )()
          .toDartString();
    }
    final message = 'O core Moonlight falhou na etapa "$stage" (código $errorCode).'
        '${logPath.isEmpty ? '' : ' Detalhes em $logPath'}';
    debugPrint('[WindowsMoonlightClient] $message');
    return message;
  }

  DynamicLibrary _openLibrary() {
    try {
      return DynamicLibrary.open('fardesk_stream_core.dll');
    } catch (error) {
      throw MoonlightClientException(
        'O core nativo do Moonlight não foi encontrado '
        '(fardesk_stream_core.dll). Erro: $error',
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _statePoller?.cancel();
    _statePoller = null;
    if (_videoFrameNativeBuffer != nullptr) {
      calloc.free(_videoFrameNativeBuffer);
      _videoFrameNativeBuffer = nullptr;
      _videoFrameNativeBufferCapacity = 0;
    }
    _state.dispose();
    _error.dispose();
    _latestVideoFrame.dispose();
  }
}
