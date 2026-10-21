import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'network_runtime.dart';

typedef _NewNative = Int32 Function();
typedef _NewDart = int Function();
typedef _CloseNative = Int32 Function(Int32);
typedef _CloseDart = int Function(int);
typedef _SetStringNative = Int32 Function(Int32, Pointer<Utf8>);
typedef _SetStringDart = int Function(int, Pointer<Utf8>);
typedef _SetIntNative = Int32 Function(Int32, Int32);
typedef _SetIntDart = int Function(int, int);
typedef _UpNative = Int32 Function(Int32);
typedef _UpDart = int Function(int);
typedef _GetIpsNative = Int32 Function(Int32, Pointer<Char>, Size);
typedef _GetIpsDart = int Function(int, Pointer<Char>, int);
typedef _ErrorMessageNative = Int32 Function(Int32, Pointer<Char>, Size);
typedef _ErrorMessageDart = int Function(int, Pointer<Char>, int);

class LibtailscaleFfiRuntime implements NetworkRuntime {
  LibtailscaleFfiRuntime({DynamicLibrary? library})
      : _libraryOverride = library,
        _status = ValueNotifier(const NetworkRuntimeStatus(state: NetworkRuntimeState.stopped));

  final DynamicLibrary? _libraryOverride;
  final ValueNotifier<NetworkRuntimeStatus> _status;
  late final _NewDart _new;
  late final _CloseDart _close;
  late final _SetStringDart _setDir;
  late final _SetStringDart _setHostname;
  late final _SetStringDart _setAuthKey;
  late final _SetIntDart _setEphemeral;
  late final _UpDart _up;
  late final _GetIpsDart _getIps;
  late final _ErrorMessageDart _errorMessage;
  int? _handle;
  bool _bindingsLoaded = false;

  @override
  bool get supportsSystemSockets => false;

  @override
  ValueListenable<NetworkRuntimeStatus> get status => _status;

  @override
  Future<NetworkRuntimeStatus> start({
    required String authKey,
    required String stateDirectory,
    required String hostname,
  }) async {
    if (_handle != null && _status.value.state == NetworkRuntimeState.running) {
      return _status.value;
    }
    _status.value = const NetworkRuntimeStatus(state: NetworkRuntimeState.starting);

    try {
      _ensureBindings();
      final handle = _new();
      if (handle <= 0) throw const NetworkRuntimeException('Não foi possível criar o runtime de rede.');
      _handle = handle;
      _setString(_setDir, stateDirectory);
      _setString(_setHostname, hostname);
      _setString(_setAuthKey, authKey);
      _check(_setEphemeral(handle, 1));
      _check(_up(handle));

      final addresses = _readAddresses(handle);
      final next = NetworkRuntimeStatus(
        state: NetworkRuntimeState.running,
        addresses: addresses,
      );
      _status.value = next;
      return next;
    } catch (error) {
      await stop();
      final failure = NetworkRuntimeStatus(state: NetworkRuntimeState.failed, error: error);
      _status.value = failure;
      rethrow;
    }

  }

  void _ensureBindings() {
    if (_bindingsLoaded) return;
    final library = _libraryOverride ?? _openLibrary();
    _new = library.lookup<NativeFunction<_NewNative>>('tailscale_new').asFunction();
    _close = library.lookup<NativeFunction<_CloseNative>>('tailscale_close').asFunction();
    _setDir = library.lookup<NativeFunction<_SetStringNative>>('tailscale_set_dir').asFunction();
    _setHostname = library.lookup<NativeFunction<_SetStringNative>>('tailscale_set_hostname').asFunction();
    _setAuthKey = library.lookup<NativeFunction<_SetStringNative>>('tailscale_set_authkey').asFunction();
    _setEphemeral = library.lookup<NativeFunction<_SetIntNative>>('tailscale_set_ephemeral').asFunction();
    _up = library.lookup<NativeFunction<_UpNative>>('tailscale_up').asFunction();
    _getIps = library.lookup<NativeFunction<_GetIpsNative>>('tailscale_getips').asFunction();
    _errorMessage = library.lookup<NativeFunction<_ErrorMessageNative>>('tailscale_errmsg').asFunction();
    _bindingsLoaded = true;
  }

  @override
  Future<void> stop() async {
    final handle = _handle;
    if (handle == null) return;
    _status.value = const NetworkRuntimeStatus(state: NetworkRuntimeState.stopping);
    _handle = null;
    _close(handle);
    _status.value = const NetworkRuntimeStatus(state: NetworkRuntimeState.stopped);
  }

  @override
  void dispose() {
    stop();
    _status.dispose();
  }

  void _setString(_SetStringDart setter, String value) {
    final nativeValue = value.toNativeUtf8();
    try {
      _check(setter(_handle!, nativeValue));
    } finally {
      calloc.free(nativeValue);
    }
  }

  void _check(int result) {
    if (result == 0) return;
    throw NetworkRuntimeException(_lastError());
  }

  List<String> _readAddresses(int handle) {
    final buffer = calloc<Char>(256);
    try {
      _check(_getIps(handle, buffer, 256));
      final raw = buffer.cast<Utf8>().toDartString();
      return raw.split(',').where((address) => address.isNotEmpty).toList(growable: false);
    } finally {
      calloc.free(buffer);
    }
  }

  String _lastError() {
    final buffer = calloc<Char>(1024);
    try {
      _errorMessage(_handle ?? -1, buffer, 1024);
      return buffer.cast<Utf8>().toDartString();
    } finally {
      calloc.free(buffer);
    }
  }

  static DynamicLibrary _openLibrary() {
    if (!Platform.isWindows) {
      throw const NetworkRuntimeException('O runtime libtailscale está disponível apenas no Windows.');
    }
    return DynamicLibrary.open('libtailscale.dll');
  }
}
