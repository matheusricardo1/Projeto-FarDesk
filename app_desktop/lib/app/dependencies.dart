import 'dart:io';

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/host_agent/pairing_api_client.dart';
import '../core/moonlight/moonlight_client.dart';
import '../core/moonlight/windows_moonlight_client.dart';
import '../core/network/bundled_tailscale_tun_runtime.dart';
import '../core/network/tailscale_network_api.dart';
import '../core/network/tailscale_network_manager.dart';
import '../core/update/app_update_service.dart';
import '../features/account/data/google_auth_repository.dart';
import '../features/account/domain/auth_repository.dart';
import '../features/account/presentation/session_view_model.dart';
import '../features/devices/data/device_api_repository.dart';
import '../features/devices/domain/device_repository.dart';
import '../features/integrations/data/integration_api_repository.dart';
import '../features/integrations/domain/integration_repository.dart';
import '../features/settings/data/in_memory_settings_repository.dart';
import '../features/settings/domain/settings_repository.dart';

/// Ponto único de composição: monta cada repositório contra o backend
/// FarDesk de verdade — nenhuma tela ou ViewModel precisa saber como.
class AppDependencies {
  const AppDependencies({
    required this.authRepository,
    required this.deviceRepository,
    required this.integrationRepository,
    required this.settingsRepository,
    this.pairingApiClient,
    required this.moonlightClient,
    required this.networkManager,
    required this.updateService,
  });

  /// Tudo contra o backend FarDesk de verdade. Configurações continuam só
  /// locais (`InMemorySettingsRepository`) de propósito — resolução, bitrate
  /// etc. são preferências do PC, não dados de conta; não existe (nem deveria
  /// existir) um endpoint de backend pra isso.
  factory AppDependencies.real({
    required String backendBaseUrl,
    required String appVersion,
  }) {
    final auth = GoogleAuthRepository(backendBaseUrl: backendBaseUrl);
    return AppDependencies(
      authRepository: auth,
      deviceRepository: DeviceApiRepository(
        backendBaseUrl: backendBaseUrl,
        accessToken: () => auth.activeAccessToken,
      ),
      integrationRepository: IntegrationApiRepository(
        backendBaseUrl: backendBaseUrl,
        accessToken: () => auth.activeAccessToken,
      ),
      settingsRepository: InMemorySettingsRepository(),
      pairingApiClient: PairingApiClient(
        backendBaseUrl: backendBaseUrl,
        accessToken: () => auth.activeAccessToken,
      ),
      moonlightClient: WindowsMoonlightClient(),
      networkManager: FarDeskNetworkManager(
        api: TailscaleNetworkApi(
          backendBaseUrl: backendBaseUrl,
          accessToken: () => auth.activeAccessToken,
        ),
        runtime: BundledTailscaleTunRuntime(
          executableDirectory: Directory(
            '${Platform.resolvedExecutable}\\..\\network',
          ),
        ),
      ),
      updateService: AppUpdateService(currentVersion: appVersion),
    );
  }

  final AuthRepository authRepository;
  final DeviceRepository deviceRepository;
  final IntegrationRepository integrationRepository;
  final SettingsRepository settingsRepository;

  /// Sempre preenchido aqui — opcional só pra ficar fácil de omitir em
  /// teste (`HostActivationViewModel` não liga o vigia sem ele).
  final PairingApiClient? pairingApiClient;
  final MoonlightClient moonlightClient;
  final FarDeskNetworkManager? networkManager;
  final AppUpdateService updateService;

  List<SingleChildWidget> get providers => [
    Provider<AuthRepository>.value(value: authRepository),
    Provider<DeviceRepository>.value(value: deviceRepository),
    Provider<IntegrationRepository>.value(value: integrationRepository),
    Provider<SettingsRepository>.value(value: settingsRepository),
    Provider<PairingApiClient?>.value(value: pairingApiClient),
    Provider<MoonlightClient>.value(value: moonlightClient),
    Provider<FarDeskNetworkManager?>.value(value: networkManager),
    Provider<AppUpdateService>.value(value: updateService),
    ChangeNotifierProvider(create: (_) => SessionViewModel(authRepository)),
  ];
}
