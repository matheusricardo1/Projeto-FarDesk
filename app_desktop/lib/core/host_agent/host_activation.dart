import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';

import 'host_api.dart';
import 'host_credentials_store.dart';
import 'host_service.dart';
import 'sunshine_admin_client.dart';
import 'sunshine_runtime_provisioner.dart';

/// Ponto único pra tudo relacionado a "este PC pode ser host" — duas
/// operações bem separadas:
///
/// - `prepare()`: baixa os arquivos e registra o serviço do Windows
///   (`start= demand`, ver `HostService`) se ainda não estiver — mas não
///   liga nada. É o que roda na primeira vez que a pessoa habilita esta
///   máquina como host.
/// - `ensureRunning()`: só liga o Sunshine (e configura a credencial, na
///   primeira vez) quando alguém de fato tenta conectar — chamado pelo
///   `HostAgentPairingService` logo antes de precisar falar com a API local.
///
/// O FarDesk não exige administrador pra abrir — `prepare()` pede UAC
/// (via `HostService.install()`) só na primeira vez que esta máquina é
/// preparada como host; depois disso, nem `prepare()` nem `ensureRunning()`
/// pedem nada de novo.
class HostActivation {
  HostActivation({
    SunshineRuntimeProvisioner? provisioner,
    HostCredentialsStore? credentialsStore,
  }) : _provisioner = provisioner ?? SunshineRuntimeProvisioner(),
       _credentialsStore = credentialsStore ?? HostCredentialsStore();

  final SunshineRuntimeProvisioner _provisioner;
  final HostCredentialsStore _credentialsStore;
  bool _startedByFarDesk = false;

  /// `true` se este PC já foi preparado como host numa sessão anterior —
  /// sem baixar nem instalar nada só por perguntar. É o que o app chama no
  /// startup pra decidir se liga o `HostAgentPairingService` sozinho.
  Future<bool> isPrepared() async {
    final installDirectory = await _provisioner.installedDirectoryIfPresent();
    if (installDirectory == null) return false;
    return HostService(installDirectory: installDirectory).isInstalled();
  }

  /// Remove um Sunshine que ficou ativo após crash, kill do processo ou
  /// encerramento forçado do Flutter. O serviço é demand-start, então não
  /// deve permanecer rodando sem uma instância do FarDesk gerenciando-o.
  Future<void> reconcileOnStartup() async {
    final marker = await _sessionMarker();
    if (!await marker.exists()) return;
    final installDirectory = await _provisioner.installedDirectoryIfPresent();
    if (installDirectory != null) {
      await HostService(installDirectory: installDirectory).stop();
    }
    await marker.delete();
  }

  /// Baixa/instala sem ligar. Idempotente — chamar de novo com tudo já
  /// pronto não faz nada.
  Future<void> prepare() async {
    final installDirectory = await _provisioner.ensureInstalled();
    final service = HostService(installDirectory: installDirectory);
    if (!await service.isInstalled()) {
      await service.install();
    }
  }

  /// Garante que o Sunshine está rodando e com credencial configurada —
  /// chama `prepare()` primeiro caso ainda não tenha sido feito. Devolve a
  /// `HostApi` já pronta pra uso (submeter PIN, listar apps etc.).
  Future<HostApi> ensureRunning({HostCredentials? credentialsOverride}) async {
    final installDirectory = await _provisioner.ensureInstalled();
    final service = HostService(installDirectory: installDirectory);

    if (!await service.isInstalled()) {
      debugPrint('[HostActivation] ensureRunning(): serviço não instalado, instalando agora...');
      await service.install();
    }

    final credentials = credentialsOverride ?? await _credentialsStore.load();
    final api = HostApi(
      adminClient: SunshineAdminClient(
        username: credentials.username,
        password: credentials.password,
      ),
    );

    final alreadyRunning = await service.isRunning();
    debugPrint('[HostActivation] ensureRunning(): serviço já rodando? $alreadyRunning');
    if (!alreadyRunning) {
      await (await _sessionMarker()).writeAsString(
        DateTime.now().toUtc().toIso8601String(),
      );
      await service.start();
      _startedByFarDesk = true;
      // Antes de existir credencial, a porta responde mas não autentica
      // nada ainda — por isso a espera checa só conectividade, não login.
      await service.waitUntilReady(onReady: api.isReachable);

      if (_credentialsStore.generatedThisRun) {
        debugPrint('[HostActivation] ensureRunning(): bootstrapando credencial admin pela primeira vez...');
        await api.bootstrapCredentials();
      }
    }

    debugPrint('[HostActivation] ensureRunning(): pronto, devolvendo HostApi.');
    return api;
  }

  /// Desliga o Sunshine — ex: depois que o último cliente desconectar.
  Future<void> stopRunning() async {
    if (!_startedByFarDesk) return;
    final installDirectory = await _provisioner.installedDirectoryIfPresent();
    if (installDirectory == null) return;
    try {
      await HostService(installDirectory: installDirectory).stop();
    } finally {
      _startedByFarDesk = false;
      final marker = await _sessionMarker();
      if (await marker.exists()) await marker.delete();
    }
  }

  Future<void> shutdown() => stopRunning();

  Future<File> _sessionMarker() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return File('${supportDirectory.path}\\sunshine-session.marker');
  }
}
