import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/device/local_device_identity_store.dart';
import '../../../core/host_agent/host_activation.dart';
import '../../../core/host_agent/host_agent_pairing_service.dart';
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
/// Dois jeitos de chegar em `ready`: a pessoa clica em "Usar este PC como
/// host" (`prepare()`), ou — depois da primeira vez — o app descobre isso
/// sozinho ao abrir, porque `HostActivation.isPrepared()` já confirma sem
/// precisar de clique nenhum. Em ambos os casos, o vigia é ligado na hora.
class HostActivationViewModel extends ChangeNotifier {
  HostActivationViewModel({
    HostActivation? hostActivation,
    this.pairingApiClient,
    LocalDeviceIdentityStore? identityStore,
  }) : _identityStore = identityStore ?? LocalDeviceIdentityStore() {
    _credentialsStore = HostCredentialsStore();
    _hostActivation =
        hostActivation ?? HostActivation(credentialsStore: _credentialsStore);
    unawaited(_checkAlreadyPrepared());
  }

  late final HostActivation _hostActivation;
  final LocalDeviceIdentityStore _identityStore;
  late final HostCredentialsStore _credentialsStore;

  /// `null` quando o app está em modo mock (sem backend de verdade) — o
  /// vigia simplesmente não liga nesse caso.
  final PairingApiClient? pairingApiClient;

  HostAgentPairingService? _watcher;
  bool _startingWatcher = false;
  bool _shuttingDown = false;
  HostActivationStatus _status = HostActivationStatus.notReady;
  Object? _error;

  HostActivationStatus get status => _status;
  Object? get error => _error;
  bool get isBusy => _status == HostActivationStatus.preparing;

  Future<void> _checkAlreadyPrepared() async {
    try {
      await _hostActivation.reconcileOnStartup();
      if (await _hostActivation.isPrepared()) {
        _status = HostActivationStatus.ready;
        notifyListeners();
        unawaited(_startWatcherIfNeeded());
      }
    } catch (error) {
      _error = error;
      _status = HostActivationStatus.error;
      notifyListeners();
    }

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
