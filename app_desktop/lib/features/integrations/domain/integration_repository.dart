import '../../../core/result.dart';
import 'integration.dart';

/// Conexão com serviços de terceiros (Tailscale, Steam, Hydra Launcher...).
/// A implementação real do Tailscale usa Auth Keys geradas via API pra
/// parear sozinho no login (ver panorama.md); Steam/Hydra usam OAuth ou
/// leitura local de biblioteca.
abstract interface class IntegrationRepository {
  Future<Result<List<Integration>>> fetchIntegrations();

  /// Conecta uma integração que não precisa de credenciais extras do
  /// usuário (hoje nenhuma — Steam/Hydra ainda não têm backend).
  Future<Result<Integration>> connect(String integrationId);

  /// O Tailscale usa um OAuth client (client ID + secret) gerado no painel
  /// do Tailscale, não um simples clique — por isso tem um método próprio
  /// em vez de reaproveitar [connect].
  Future<Result<Integration>> connectTailscale({required String clientId, required String clientSecret});

  Future<Result<Integration>> disconnect(String integrationId);
}
