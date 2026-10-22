import '../../../core/result.dart';
import '../domain/device.dart';
import '../domain/device_repository.dart';

/// Implementação em memória pra desenvolver a UI sem backend.
class MockDeviceRepository implements DeviceRepository {
  MockDeviceRepository({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;

  final List<Device> _devices = [
    const Device(
      id: 'pc-matheus',
      name: 'PC do Matheus',
      platform: DevicePlatform.windows,
      status: DeviceStatus.online,
      isCurrentDevice: true,
    ),
    const Device(
      id: 'pc-sala',
      name: 'PC da Sala',
      platform: DevicePlatform.windows,
      status: DeviceStatus.inUse,
    ),
    const Device(
      id: 'ps5',
      name: 'PS5',
      platform: DevicePlatform.ps5,
      status: DeviceStatus.hibernating,
    ),
    const Device(
      id: 'pc-trabalho',
      name: 'PC do Trabalho',
      platform: DevicePlatform.windows,
      status: DeviceStatus.offline,
    ),
    const Device(
      id: 'notebook',
      name: 'Notebook',
      platform: DevicePlatform.windows,
      status: DeviceStatus.online,
    ),
    const Device(
      id: 'servidor-home',
      name: 'Servidor Home',
      platform: DevicePlatform.linux,
      status: DeviceStatus.hibernating,
    ),
  ];

  @override
  Future<Result<void>> registerThisDevice() async {
    await Future<void>.delayed(latency);
    return const Ok(null);
  }

  @override
  Future<Result<void>> heartbeatThisDevice() async {
    await Future<void>.delayed(latency);
    return const Ok(null);
  }

  @override
  Future<Result<List<Device>>> fetchDevices() async {
    await Future<void>.delayed(latency);
    return Ok(List.unmodifiable(_devices));
  }

  @override
  Future<Result<void>> connect(String deviceId) async {
    await Future<void>.delayed(latency);
    return const Ok(null);
  }

  @override
  Future<Result<Device>> wake(String deviceId) async {
    await Future<void>.delayed(latency * 2);
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index < 0)
      return Failure(StateError('Dispositivo não encontrado: $deviceId'));
    _devices[index] = _devices[index].copyWith(status: DeviceStatus.online);
    return Ok(_devices[index]);
  }
}
