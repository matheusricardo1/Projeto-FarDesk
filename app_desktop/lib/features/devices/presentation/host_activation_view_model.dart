import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/device/local_device_identity_store.dart';
import '../../../core/host_agent/host_activation.dart';
import '../../../core/host_agent/host_agent_pairing_service.dart';
import '../../../core/host_agent/host_availability_store.dart';
import '../../../core/host_agent/host_credentials_store.dart';
import '../../../core/host_agent/pairing_api_client.dart';
import '../../../core/host_agent/sunshine_admin_client.dart';

enum HostActivationStatus { notReady, preparing, ready, error }

/// Estado de "este PC pode ser host" pra UI. Importante: `ready` não
/// significa que o Sunshine está rodando agora — significa que o serviço
/// do Windows já está instalado (`start= demand`) e o `HostAgentPairingService`
/// está de olho, pronto pra ligar o Sunshine sozinho na primeira vez que
/// alguém tentar conectar.
///
/// `useAsHost` (padrão `true`, persistido em disco — ver
/// `HostAvailabilityStore`) é a configuração; `status` é o resultado dela.
/// Com a configuração ligada — o caso normal, ninguém precisa clicar em
/// nada — o app chama `prepare()` sozinho ao abrir. A pessoa só vê o botão
/// "Usar este PC como host" se tiver desligado isso antes, ou se
/// `prepare()` falhar e precisar de um retry manual.
class HostActivationViewModel extends ChangeNotifier {
  HostActivationViewModel({
    HostActivation? hostActivation,
    this.pairingApiClient,
    LocalDeviceIdentityStore? identityStore,
    HostAvailabilityStore? availabilityStore,
  }) : _identityStore = identityStore ?? LocalDeviceIdentityStore(),
       _availabilityStore = availabilityStore ?? HostAvailabilityStore() {
    _credentialsStore = HostCredentialsStore();
    _hostActivation =
        hostActivation ?? HostActivation(credentialsStore: _credentialsStore);
    unawaited(_initialize());
  }

  late final HostActivation _hostActivation;
  final LocalDeviceIdentityStore _identityStore;
  final HostAvailabilityStore _availabilityStore;
  late final HostCredentialsStore _credentialsStore;

  /// `null` quando o app está em modo mock (sem backend de verdade) — o
  /// vigia simplesmente não liga nesse caso.
  final PairingApiClient? pairingApiClient;

  HostAgentPairingService? _watcher;
  bool _startingWatcher = false;
  bool _shuttingDown = false;
  HostActivationStatus _status = HostActivationStatus.notReady;
  Object? _error;

  /// Valor otimista até `HostAvailabilityStore.load()` resolver — a
  /// configuração é ligada por padrão, então a UI já parte daí em vez de
  /// esperar o disco pra decidir o que mostrar.
  bool _useAsHost = true;

  HostActivationStatus get status => _status;
  Object? get error => _error;
  bool get isBusy => _status == HostActivationStatus.preparing;
  bool get useAsHost => _useAsHost;

  Future<void> _initialize() async {
    try {
      await _hostActivation.reconcileOnStartup();
      _useAsHost = await _availabilityStore.load();

      // Desligado explicitamente numa sessão anterior — não reativa sozinho
      // só porque o serviço do Windows continua instalado de antes
      // (`shutdown()` para o Sunshine, mas não desinstala nada).
      if (!_useAsHost) {
        notifyListeners();
        return;
      }

      if (await _hostActivation.isPrepared()) {
        _status = HostActivationStatus.ready;
        notifyListeners();
        unawaited(_startWatcherIfNeeded());
        return;
      }

      await prepare();
    } catch (error) {
      _error = error;
      _status = HostActivationStatus.error;
      notifyListeners();
    }
  }

  /// Liga/desliga a configuração "usar este PC como host". Desligar
  /// desarma o vigia e encerra o Sunshine se estiver rodando — religar
  /// chama `prepare()` de novo, do zero se precisar.
  Future<void> setUseAsHost(bool value) async {
    _useAsHost = value;
    await _availabilityStore.save(value);

    if (value) {
      if (_status != HostActivationStatus.ready) await prepare();
      return;
    }

    if (_status == HostActivationStatus.notReady) {
      notifyListeners();
      return;
    }
    _watcher?.stop();
    _watcher = null;
    await _hostActivation.shutdown();
    _status = HostActivationStatus.notReady;
    _error = null;
    notifyListeners();
  }

  Future<void> shutdown() async {
    if (_shuttingDown) return;
    _shuttingDown = true;
    _watcher?.stop();
    _watcher = null;
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (_startingWatcher && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await _hostActivation.shutdown();
  }

  Future<void> prepare() async {
    if (isBusy) return;
    _status = HostActivationStatus.preparing;
    _error = null;
    notifyListeners();

    try {
      await _hostActivation.prepare();
      _status = HostActivationStatus.ready;
      unawaited(_startWatcherIfNeeded());
    } catch (error) {
      _error = error;
      _status = HostActivationStatus.error;
    }
    notifyListeners();
  }

  /// Monta e liga o `HostAgentPairingService` — gera/lê a identidade local
  /// e as credenciais do admin do Sunshine antes de poder começar a
  /// pollar. Protegido por `_startingWatcher` pra não montar dois vigias
  /// se `prepare()` e a checagem de startup chamarem isso em paralelo.
  Future<void> _startWatcherIfNeeded() async {
    if (_watcher != null || _startingWatcher || _shuttingDown) return;
    final pairingApi = pairingApiClient;
    if (pairingApi == null) return;

    _startingWatcher = true;
    try {
      final identity = await _identityStore.load();
      if (_shuttingDown) return;
      await _credentialsStore.load();
      if (_credentialsStore.generatedThisRun) {
        final remoteCredentials = await pairingApi.fetchHostCredentials(
          identity.deviceId,
        );
        if (remoteCredentials != null) {
          await _credentialsStore.save(remoteCredentials);
        }
      }
      final effectiveCredentials = await _credentialsStore.load();
      if (_shuttingDown) return;
      final sunshineAdmin = SunshineAdminClient(
        username: effectiveCredentials.username,
        password: effectiveCredentials.password,
      );
      _watcher = HostAgentPairingService(
        deviceId: identity.deviceId,
        pairingApi: pairingApi,
        sunshineAdmin: sunshineAdmin,
        ensureHostRunning: () async {
          await _hostActivation.ensureRunning();
          await pairingApi.saveHostCredentials(
            identity.deviceId,
            effectiveCredentials,
          );
        },
      )..start();
    } finally {
      _startingWatcher = false;
    }
  }

  @override
  void dispose() {
    _watcher?.stop();
    unawaited(_hostActivation.shutdown());
    super.dispose();
  }
}
