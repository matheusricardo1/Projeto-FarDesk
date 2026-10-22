import 'dart:io';

import 'package:app_desktop/core/host_agent/host_activation.dart';
import 'package:app_desktop/core/host_agent/host_availability_store.dart';
import 'package:app_desktop/features/devices/presentation/host_activation_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Substitui o `HostActivation` de verdade (que instala/liga o Sunshine)
/// por um fake que só conta chamadas — nada de IO real, nada de serviço do
/// Windows.
class _FakeHostActivation extends HostActivation {
  bool prepared = false;
  bool failOnPrepare = false;
  int prepareCalls = 0;
  int shutdownCalls = 0;

  @override
  Future<void> reconcileOnStartup() async {}

  @override
  Future<bool> isPrepared() async => prepared;

  @override
  Future<void> prepare() async {
    prepareCalls++;
    if (failOnPrepare) throw Exception('falhou de propósito');
    prepared = true;
  }

  @override
  Future<void> shutdown() async {
    shutdownCalls++;
  }
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('host-availability-test-');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  /// Deixa a cadeia de `await`s do construtor (`unawaited(_initialize())`)
  /// terminar antes de checar o estado — tudo nela resolve de imediato
  /// (fakes síncronos), então um delay curto já basta.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('por padrão, prepara o host sozinho ao iniciar — ninguém precisa clicar em nada', () async {
    final hostActivation = _FakeHostActivation();
    final viewModel = HostActivationViewModel(
      hostActivation: hostActivation,
      availabilityStore: HostAvailabilityStore(directory: tempDir),
    );
    await settle();

    expect(viewModel.useAsHost, isTrue);
    expect(viewModel.status, HostActivationStatus.ready);
    expect(hostActivation.prepareCalls, 1);
  });

  test('não prepara sozinho se a pessoa já tinha desligado "usar como host" antes', () async {
    await HostAvailabilityStore(directory: tempDir).save(false);
    final hostActivation = _FakeHostActivation();
    final viewModel = HostActivationViewModel(
      hostActivation: hostActivation,
      availabilityStore: HostAvailabilityStore(directory: tempDir),
    );
    await settle();

    expect(viewModel.useAsHost, isFalse);
    expect(viewModel.status, HostActivationStatus.notReady);
    expect(hostActivation.prepareCalls, 0);
  });

  test('um serviço já instalado antes é reconhecido direto, sem reinstalar', () async {
    final hostActivation = _FakeHostActivation()..prepared = true;
    final viewModel = HostActivationViewModel(
      hostActivation: hostActivation,
      availabilityStore: HostAvailabilityStore(directory: tempDir),
    );
    await settle();

    expect(viewModel.status, HostActivationStatus.ready);
    expect(hostActivation.prepareCalls, 0);
  });

  test('desativar desliga o host e persiste a escolha em disco', () async {
    final hostActivation = _FakeHostActivation();
    final viewModel = HostActivationViewModel(
      hostActivation: hostActivation,
      availabilityStore: HostAvailabilityStore(directory: tempDir),
    );
    await settle();
    expect(viewModel.status, HostActivationStatus.ready);

    await viewModel.setUseAsHost(false);

    expect(viewModel.status, HostActivationStatus.notReady);
    expect(hostActivation.shutdownCalls, 1);
    expect(await HostAvailabilityStore(directory: tempDir).load(), isFalse);
  });

  test('reativar depois de desligado prepara de novo', () async {
    final hostActivation = _FakeHostActivation();
    final viewModel = HostActivationViewModel(
      hostActivation: hostActivation,
      availabilityStore: HostAvailabilityStore(directory: tempDir),
    );
    await settle();
    await viewModel.setUseAsHost(false);

    await viewModel.setUseAsHost(true);

    expect(viewModel.status, HostActivationStatus.ready);
    expect(hostActivation.prepareCalls, 2);
  });

  test('erro ao preparar sozinho vira status de erro, visível pra retry manual', () async {
    final hostActivation = _FakeHostActivation()..failOnPrepare = true;
    final viewModel = HostActivationViewModel(
      hostActivation: hostActivation,
      availabilityStore: HostAvailabilityStore(directory: tempDir),
    );
    await settle();

    expect(viewModel.status, HostActivationStatus.error);
  });
}
