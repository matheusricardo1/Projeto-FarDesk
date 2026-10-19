import 'package:flutter/widgets.dart';

enum IntegrationCategory { network, library }

enum IntegrationStatus { connected, disconnected }

/// Como o usuário autentica essa integração. Afeta só a UI do botão de
/// conectar (ícone/rótulo/diálogo) — a ação em si é sempre
/// [IntegrationRepository.connect] ou [IntegrationRepository.connectTailscale].
enum IntegrationAuthMethod {
  /// Cola uma chave/credencial (ex: o OAuth client ID + secret gerado no
  /// painel do Tailscale) — não é um login, é colar algo que o usuário já tem.
  apiKey,

  /// Fluxo próprio do serviço (ex: OAuth real da Steam).
  generic,
}

/// Serviço de terceiros que o FarDesk conecta. Puro Dart — sem dependência
/// de Flutter além de [IconData], pra ser compartilhado com o app mobile no
/// futuro (`fardesk_core`).
class Integration {
  const Integration({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.status,
    this.required = false,
    this.authMethod = IntegrationAuthMethod.generic,
    this.connectedAs,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final IntegrationCategory category;
  final IntegrationStatus status;

  /// Se true, o app depende desse serviço pra funcionar (hoje só o
  /// Tailscale — é a rede que viabiliza conectar em outro PC ou acessar
  /// este PC pelo celular).
  final bool required;

  final IntegrationAuthMethod authMethod;

  /// Identificação da conta conectada (ex: e-mail, usuário), exibida no
  /// lugar da descrição quando conectado.
  final String? connectedAs;

  bool get isConnected => status == IntegrationStatus.connected;

  /// Nomeados em vez de um `copyWith` genérico: `connectedAs` é nulável de
  /// propósito (precisa ser limpo ao desconectar), e um `copyWith` com `??`
  /// não consegue expressar "defina como null".
  Integration connectedWith(String account) => _copyWith(status: IntegrationStatus.connected, connectedAs: account);

  Integration disconnected() => _copyWith(status: IntegrationStatus.disconnected, connectedAs: null);

  Integration _copyWith({required IntegrationStatus status, required String? connectedAs}) => Integration(
        id: id,
        name: name,
        description: description,
        icon: icon,
        category: category,
        status: status,
        required: required,
        authMethod: authMethod,
        connectedAs: connectedAs,
      );
}
