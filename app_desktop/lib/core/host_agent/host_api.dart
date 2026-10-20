import 'dart:io';

import 'host_credentials_store.dart';
import 'models/pending_sunshine_pairing.dart';
import 'sunshine_admin_client.dart';

/// A API REST que o `HostService` expõe depois de subir — a outra metade do
/// par "serviço + API" (ver `HostService`). Nada aqui sabe instalar, iniciar
/// ou parar processo; só fala HTTP com um Sunshine que já está no ar.
///
/// É essa classe que o resto do app (e o próprio `HostAgentPairingService`)
/// deveria importar pra lidar com o host local — não `SunshineAdminClient`
/// direto, que é só o transporte HTTP por baixo.
class HostApi {
  HostApi({required this.adminClient});

  /// Carrega credenciais do `HostCredentialsStore` sozinho — nenhuma tela pede nada.
  static Future<HostApi> autoProvisioned({HostCredentialsStore? credentialsStore}) async =>
      HostApi(adminClient: await SunshineAdminClient.autoProvisioned(credentialsStore: credentialsStore));

  final SunshineAdminClient adminClient;

  /// Chamada autenticada leve só pra saber se a API já está respondendo —
  /// exige que já exista usuário/senha configurados, então só serve depois
  /// de `bootstrapCredentials`. Pra esperar a porta abrir logo após o
  /// `HostService.start()` (antes de qualquer credencial existir), use
  /// [isReachable].
  Future<bool> ping() async {
    try {
      await adminClient.listPendingPairings();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Só confirma que a porta HTTP está aceitando conexão — sem autenticar.
  /// É o que dá pra checar antes de existir credencial nenhuma, logo depois
  /// do `sc start`.
  Future<bool> isReachable() async {
    try {
      final socket = await Socket.connect(adminClient.host, adminClient.port, timeout: const Duration(seconds: 2));
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Configura usuário/senha do admin na primeira vez que o serviço sobe —
  /// equivalente a preencher a tela `/welcome`, sem ninguém preenchendo nada.
  Future<bool> bootstrapCredentials() => adminClient.bootstrapCredentials();

  Future<List<Map<String, dynamic>>> listApps() => adminClient.listApps();

  Future<bool> addApp(Map<String, dynamic> app) => adminClient.addApp(app);

  Future<bool> closeApp() => adminClient.closeApp();

  Future<List<Map<String, dynamic>>> listClients() => adminClient.listClients();

  Future<bool> unpairClient(String uuid) => adminClient.unpairClient(uuid);

  Future<bool> unpairAllClients() => adminClient.unpairAllClients();

  Future<List<PendingSunshinePairing>> listPendingPairings() => adminClient.listPendingPairings();

  Future<bool> submitPin({required String pairingId, required String pin, required String clientName}) =>
      adminClient.submitPin(pairingId: pairingId, pin: pin, clientName: clientName);
}
