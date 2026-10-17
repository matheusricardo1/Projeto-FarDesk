enum DeviceStatus { online, inUse, hibernating, offline }

enum DevicePlatform { windows, linux, macos, ps5, android, ios, web }

/// Dispositivo vinculado à conta. Puro Dart — sem dependência de Flutter, pra
/// ser compartilhado com o app mobile (`fardesk_core`) no futuro.
class Device {
  const Device({
    required this.id,
    required this.name,
    required this.platform,
    required this.status,
    this.isCurrentDevice = false,
  });

  final String id;
  final String name;
  final DevicePlatform platform;
  final DeviceStatus status;

  /// O próprio PC rodando o app — aparece na lista, mas não dá pra conectar.
  final bool isCurrentDevice;

  bool get canConnect => status == DeviceStatus.online && !isCurrentDevice;
  bool get canWake => status == DeviceStatus.hibernating && !isCurrentDevice;

  Device copyWith({DeviceStatus? status}) => Device(
        id: id,
        name: name,
        platform: platform,
        status: status ?? this.status,
        isCurrentDevice: isCurrentDevice,
      );
}
