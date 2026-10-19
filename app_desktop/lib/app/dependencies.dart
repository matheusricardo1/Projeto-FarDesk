import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/account/data/google_auth_repository.dart';
import '../features/account/data/mock_auth_repository.dart';
import '../features/account/domain/auth_repository.dart';
import '../features/account/presentation/session_view_model.dart';
import '../features/devices/data/device_api_repository.dart';
import '../features/devices/data/mock_device_repository.dart';
import '../features/devices/domain/device_repository.dart';
import '../features/integrations/data/integration_api_repository.dart';
import '../features/integrations/data/mock_integration_repository.dart';
import '../features/integrations/domain/integration_repository.dart';
import '../features/settings/data/in_memory_settings_repository.dart';
import '../features/settings/domain/settings_repository.dart';

/// Ponto único de composição: decide qual implementação de cada repositório
/// o app usa. Trocar um mock pela implementação real é mudar uma linha aqui —
/// nenhuma tela ou ViewModel precisa saber.
class AppDependencies {
  const AppDependencies({
    required this.authRepository,
    required this.deviceRepository,
    required this.integrationRepository,
    required this.settingsRepository,
  });

  /// Tudo em memória, sem backend — pra desenvolver e testar a UI.
  factory AppDependencies.mock() => AppDependencies(
        authRepository: MockAuthRepository(),
        deviceRepository: MockDeviceRepository(),
        integrationRepository: MockIntegrationRepository(),
        settingsRepository: InMemorySettingsRepository(),
      );

  /// Tudo contra o backend FarDesk de verdade. Configurações continuam só
  /// locais (`InMemorySettingsRepository`) de propósito — resolução, bitrate
  /// etc. são preferências do PC, não dados de conta; não existe (nem deveria
  /// existir) um endpoint de backend pra isso.
  factory AppDependencies.real({required String backendBaseUrl}) {
    final auth = GoogleAuthRepository(backendBaseUrl: backendBaseUrl);
    return AppDependencies(
      authRepository: auth,
      deviceRepository: DeviceApiRepository(backendBaseUrl: backendBaseUrl, accessToken: () => auth.activeAccessToken),
      integrationRepository:
          IntegrationApiRepository(backendBaseUrl: backendBaseUrl, accessToken: () => auth.activeAccessToken),
      settingsRepository: InMemorySettingsRepository(),
    );
  }

  final AuthRepository authRepository;
  final DeviceRepository deviceRepository;
  final IntegrationRepository integrationRepository;
  final SettingsRepository settingsRepository;

  List<SingleChildWidget> get providers => [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<DeviceRepository>.value(value: deviceRepository),
        Provider<IntegrationRepository>.value(value: integrationRepository),
        Provider<SettingsRepository>.value(value: settingsRepository),
        ChangeNotifierProvider(create: (_) => SessionViewModel(authRepository)),
      ];
}
