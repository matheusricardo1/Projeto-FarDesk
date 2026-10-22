import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../features/devices/domain/device.dart';

/// Identidade local deste PC como dispositivo da conta — gerada e
/// persistida uma única vez por instalação, mesmo padrão de
/// `SunshineIdentityStore`/`HostCredentialsStore`. É esse `deviceId` que o
/// app manda pro backend em `POST /devices/register`, e é comparando com
/// ele que o app sabe, na lista que `GET /devices` devolve, qual
/// dispositivo é "este aqui" — o backend nunca decide isso.
class LocalDeviceIdentity {
  const LocalDeviceIdentity({
    required this.deviceId,
    required this.name,
    required this.platform,
  });

  final String deviceId;
  final String name;
  final DevicePlatform platform;

  Map<String, dynamic> _toJson() => {
    'deviceId': deviceId,
    'name': name,
    'platform': platform.name,
  };

  static LocalDeviceIdentity _fromJson(Map<String, dynamic> json) =>
      LocalDeviceIdentity(
        deviceId: json['deviceId'] as String,
        name: json['name'] as String,
        platform: DevicePlatform.values.byName(json['platform'] as String),
      );

  factory LocalDeviceIdentity._generate() => LocalDeviceIdentity(
    deviceId: const Uuid().v4(),
    name: _defaultName(),
    platform: _currentPlatform(),
  );

  static String _defaultName() {
    try {
      final hostname = Platform.localHostname;
      return hostname.isEmpty ? 'Este PC' : hostname;
    } catch (_) {
      return 'Este PC';
    }
  }

  static DevicePlatform _currentPlatform() {
    if (Platform.isWindows) return DevicePlatform.windows;
    if (Platform.isLinux) return DevicePlatform.linux;
    if (Platform.isMacOS) return DevicePlatform.macos;
    return DevicePlatform.web;
  }
}

class LocalDeviceIdentityStore {
  LocalDeviceIdentityStore({Directory? directory})
    : _directoryOverride = directory;

  final Directory? _directoryOverride;
  LocalDeviceIdentity? _cached;

  Future<LocalDeviceIdentity> load() async {
    final cached = _cached;
    if (cached != null) return cached;

    final file = await _identityFile();
    if (await file.exists()) {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _cached = LocalDeviceIdentity._fromJson(json);
    }

    final identity = LocalDeviceIdentity._generate();
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(identity._toJson()));
    return _cached = identity;
  }

  /// O backend devolveu um `deviceId` diferente do que tínhamos localmente
  /// (ex.: esta mesma máquina já tinha um device registrado sob outro id,
  /// de uma instalação anterior) — adota o id canônico do backend para não
  /// duplicar o device dali em diante.
  Future<void> adoptDeviceId(String deviceId) async {
    final identity = await load();
    if (identity.deviceId == deviceId) return;
    final adopted = LocalDeviceIdentity(
      deviceId: deviceId,
      name: identity.name,
      platform: identity.platform,
    );
    final file = await _identityFile();
    await file.writeAsString(jsonEncode(adopted._toJson()));
    _cached = adopted;
  }

  Future<File> _identityFile() async {
    final directory =
        _directoryOverride ?? await getApplicationSupportDirectory();
    return File('${directory.path}/local_device_identity.json');
  }
}
