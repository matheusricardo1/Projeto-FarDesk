import 'package:app_desktop/features/devices/data/mock_device_repository.dart';
import 'package:app_desktop/features/devices/domain/device.dart';
import 'package:app_desktop/features/devices/presentation/devices_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DevicesViewModel viewModel;

  setUp(() async {
    viewModel = DevicesViewModel(MockDeviceRepository(latency: Duration.zero));
    await viewModel.load();
  });

  test('carrega os dispositivos da conta', () {
    expect(viewModel.hasDevices, isTrue);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.loadError, isNull);
  });

  test('filtra pela busca, sem diferenciar maiúsculas', () {
    viewModel.setQuery('PC');

    expect(viewModel.visibleDevices, isNotEmpty);
    expect(viewModel.visibleDevices.every((d) => d.name.toLowerCase().contains('pc')), isTrue);
  });

  test('busca sem resultado retorna lista vazia', () {
    viewModel.setQuery('nada-com-esse-nome');
    expect(viewModel.visibleDevices, isEmpty);
  });

  test('acordar um dispositivo hibernando deixa ele online', () async {
    final hibernating = viewModel.visibleDevices.firstWhere((d) => d.canWake);

    await viewModel.wake(hibernating);

    final updated = viewModel.visibleDevices.firstWhere((d) => d.id == hibernating.id);
    expect(updated.status, DeviceStatus.online);
    expect(viewModel.isPending(hibernating.id), isFalse);
  });
}
