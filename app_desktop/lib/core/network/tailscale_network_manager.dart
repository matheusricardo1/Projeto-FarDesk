import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../device/local_device_identity_store.dart';
import 'network_runtime.dart';
import 'tailscale_network_api.dart';

class FarDeskNetworkManager {
  FarDeskNetworkManager({
    required this.api,
    required this.runtime,
    LocalDeviceIdentityStore? identityStore,
  }) : _identityStore = identityStore ?? LocalDeviceIdentityStore();

  final TailscaleNetworkApi api;
  final NetworkRuntime runtime;
  final LocalDeviceIdentityStore _identityStore;

  ValueListenable<NetworkRuntimeStatus> get status => runtime.status;
  bool get supportsSystemSockets => runtime.supportsSystemSockets;

  Future<NetworkRuntimeStatus> ensureUp() async {
    if (runtime.status.value.state == NetworkRuntimeState.running) {
      return runtime.status.value;
    }

    final identity = await _identityStore.load();
    final authKey = await api.issueAuthKey();
    if (authKey.expiresAt.isBefore(DateTime.now().toUtc())) {
      throw const NetworkRuntimeException(
        'A chave da rede FarDesk já expirou.',
      );
    }

    final supportDirectory = await getApplicationSupportDirectory();
    final stateDirectory = Directory('${supportDirectory.path}\\network');
    await stateDirectory.create(recursive: true);

    return runtime.start(
      authKey: authKey.value,
      stateDirectory: stateDirectory.path,
      hostname: 'fardesk-${identity.deviceId}',
    );
  }

  Future<String> resolveHostAddress({
    required String deviceId,
    required String deviceName,
  }) async {
    final devices = await api.listDevices();
    final normalizedName = deviceName.trim().toLowerCase();
    final expectedHostname = 'fardesk-${deviceId.trim().toLowerCase()}';
    final device = devices.where((candidate) {
      return candidate.online &&
          (candidate.name.toLowerCase() == normalizedName ||
              candidate.hostname.toLowerCase() == normalizedName ||
              candidate.hostname.toLowerCase() == expectedHostname);
    }).firstOrNull;
    if (device == null) {
      throw NetworkRuntimeException(
        'O PC "$deviceName" não está online na rede FarDesk.',
      );
    }

    final address = device.addresses
        .where((candidate) => candidate.contains('.'))
        .firstOrNull;
    if (address == null) {
      throw NetworkRuntimeException(
        'O PC "$deviceName" não possui um endereço IPv4 disponível.',
      );
    }
    return address;
  }

  Future<void> stop() => runtime.stop();

  void dispose() => runtime.dispose();
}
