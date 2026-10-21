import '../host_agent/pairing_api_client.dart';
import '../network/tailscale_network_manager.dart';
import '../sunshine/paired_host_store.dart';
import '../sunshine/sunshine_exception.dart';
import '../sunshine/sunshine_identity.dart';
import 'moonlight_client.dart';
import 'streaming_session_launcher.dart';

class RemoteConnectionCoordinator {
  RemoteConnectionCoordinator({
    required this.network,
    required this.pairingApi,
    required this.identity,
    required this.pairedHostStore,
    required this.moonlightClient,
  });

  final FarDeskNetworkManager network;
  final PairingApiClient pairingApi;
  final SunshineIdentity identity;
  final PairedHostStore pairedHostStore;
  final MoonlightClient moonlightClient;

  Future<void> connect({
    required String deviceId,
    required String deviceName,
    required String targetName,
    int width = 1920,
    int height = 1080,
    int fps = 60,
    int bitrateKbps = 20000,
  }) async {
    final runtimeStatus = await network.ensureUp();
    if (runtimeStatus.ipv4Address == null) {
      throw const SunshineException(
        'A rede FarDesk subiu, mas não recebeu um endereço IPv4.',
      );
    }

    final host = await network.resolveHostAddress(
      deviceId: deviceId,
      deviceName: deviceName,
    );
    if (!network.supportsSystemSockets) {
      throw const SunshineException(
        'O runtime de rede FarDesk não fornece uma interface de sockets para o Moonlight.',
      );
    }

    final launcher = StreamingSessionLauncher(
      identity: identity,
      pairedHostStore: pairedHostStore,
      moonlightClient: moonlightClient,
    );
    final hostClient = await launcher.ensurePaired(
      deviceId: deviceId,
      host: host,
      onPairingStarted: (pin) async {
        await pairingApi.createPairingRequest(deviceId, pin);
      },
    );
    final apps = await hostClient.fetchAppList();
    if (apps.isEmpty) {
      throw const SunshineException(
        'O host não tem nenhum app configurado pra abrir.',
      );
    }
    final wanted = targetName.toLowerCase();
    final requested = apps
        .where((app) => app.title.toLowerCase().contains(wanted))
        .firstOrNull;
    final desktop = apps
        .where((app) => app.title.toLowerCase().contains('desktop'))
        .firstOrNull;
    final resolvedAppId = (requested ?? desktop ?? apps.first).id;
    await launcher.launchAndConnect(
      hostClient: hostClient,
      appId: resolvedAppId,
      width: width,
      height: height,
      fps: fps,
      bitrateKbps: bitrateKbps,
    );
  }
}
