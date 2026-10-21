import 'package:flutter/foundation.dart';

enum NetworkRuntimeState {
  stopped,
  starting,
  running,
  stopping,
  failed,
}

class NetworkRuntimeStatus {
  const NetworkRuntimeStatus({
    required this.state,
    this.addresses = const [],
    this.error,
  });

  final NetworkRuntimeState state;
  final List<String> addresses;
  final Object? error;

  String? get ipv4Address => addresses.where((address) => address.contains('.')).firstOrNull;
}

abstract interface class NetworkRuntime {
  ValueListenable<NetworkRuntimeStatus> get status;
  bool get supportsSystemSockets;

  Future<NetworkRuntimeStatus> start({
    required String authKey,
    required String stateDirectory,
    required String hostname,
  });

  Future<void> stop();

  void dispose();
}

class NetworkRuntimeException implements Exception {
  const NetworkRuntimeException(this.message);

  final String message;

  @override
  String toString() => 'NetworkRuntimeException: $message';
}
