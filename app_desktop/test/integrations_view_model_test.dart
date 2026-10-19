import 'package:app_desktop/features/integrations/data/mock_integration_repository.dart';
import 'package:app_desktop/features/integrations/domain/integration.dart';
import 'package:app_desktop/features/integrations/presentation/integrations_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late IntegrationsViewModel viewModel;

  setUp(() async {
    viewModel = IntegrationsViewModel(MockIntegrationRepository(latency: Duration.zero));
    await viewModel.load();
  });

  test('começa com o Tailscale obrigatório listado como pendente', () {
    expect(viewModel.missingRequired, hasLength(1));
    expect(viewModel.missingRequired.single.id, 'tailscale');
  });

  test('conectar preenche a conta e tira da lista de pendentes', () async {
    final tailscale = viewModel.all.firstWhere((i) => i.id == 'tailscale');

    await viewModel.connect(tailscale);

    final updated = viewModel.all.firstWhere((i) => i.id == 'tailscale');
    expect(updated.isConnected, isTrue);
    expect(updated.connectedAs, isNotNull);
    expect(viewModel.missingRequired, isEmpty);
  });

  test('desconectar limpa a conta — não fica presa no valor antigo', () async {
    final steam = viewModel.all.firstWhere((i) => i.id == 'steam');
    await viewModel.connect(steam);

    final connected = viewModel.all.firstWhere((i) => i.id == 'steam');
    await viewModel.disconnect(connected);

    final updated = viewModel.all.firstWhere((i) => i.id == 'steam');
    expect(updated.isConnected, isFalse);
    expect(updated.connectedAs, isNull);
  });

  test('biblioteca de jogos agrupa Steam e Hydra, rede agrupa só o Tailscale', () {
    expect(viewModel.byCategory(IntegrationCategory.library).map((i) => i.id), containsAll(['steam', 'hydra']));
    expect(viewModel.byCategory(IntegrationCategory.network).map((i) => i.id), ['tailscale']);
  });
}
