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

  DynamicLibrary? _loadedLibrary;
  bool _connecting = false;
  bool _cancelRequested = false;
  bool _disposed = false;
  Timer? _statePoller;

  static const _statePollInterval = Duration(milliseconds: 16);

  @override
  ValueListenable<MoonlightConnectionState> get state => _state;

  @override
  ValueListenable<Object?> get error => _error;

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
    void poll() {
      if (_state.value == MoonlightConnectionState.disconnecting ||
          _state.value == MoonlightConnectionState.disconnected) {
        return;
      }
      final nativeState = state();
      if (nativeState == 2) {
        _state.value = MoonlightConnectionState.connected;
      } else if (nativeState == 4) {
        _state.value = MoonlightConnectionState.failed;
        _error.value = MoonlightClientException(
          'O core Moonlight falhou (código ${lastError()}).',
        );
        _statePoller?.cancel();
        _statePoller = null;
      } else if (nativeState == 0) {
        _state.value = MoonlightConnectionState.disconnected;
        _statePoller?.cancel();
        _statePoller = null;
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
        throw MoonlightClientException(
          'O core Moonlight falhou (código ${lastError()}).',
        );
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
    _statePoller?.    _state.dispose();
    _error.dispose();
  }
}
