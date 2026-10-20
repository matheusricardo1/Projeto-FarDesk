import 'package:flutter/foundation.dart';
import 'dart:typed_data';

enum MoonlightConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  failed,
}

class MoonlightConnectionConfig {
  const MoonlightConnectionConfig({
    required this.host,
    this.sessionUrl,
    this.remoteInputKey,
    this.remoteInputIv,
    this.port = 47989,
    this.width = 1920,
    this.height = 1080,
    this.fps = 60,
    this.bitrateKbps = 20_000,
  });

  final String host;
  final String? sessionUrl;
  final Uint8List? remoteInputKey;
  final Uint8List? remoteInputIv;
  final int port;
  final int width;
  final int height;
  final int fps;
  final int bitrateKbps;
}

abstract interface class MoonlightClient {
  ValueListenable<MoonlightConnectionState> get state;
  ValueListenable<Object?> get error;

  Future<void> connect(MoonlightConnectionConfig config);

  Future<void> disconnect();

  Future<void> interrupt();

  void dispose();
}

class MoonlightClientException implements Exception {
  const MoonlightClientException(this.message);

  final String message;

  @override
  String toString() => 'MoonlightClientException: $message';
}
