import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/integration.dart';
import 'integrations_view_model.dart';

class IntegrationsScreen extends StatelessWidget {
  const IntegrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final viewModel = context.watch<IntegrationsViewModel>();

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Integrações',
            subtitle: 'Conecte os serviços que o FarDesk usa pra funcionar.',
          ),
          SizedBox(height: rem(Space.xxxl)),
          _IntegrationsBody(viewModel: viewModel),
        ],
      ),
    );
  }
}

/// O Tailscale não conecta com um clique: precisa de um API access token
/// gerado no painel do Tailscale, colado numa chave. As outras integrações
/// do catálogo (hoje nenhuma de verdade) seguem o clique direto.
Future<void> _handleConnect(BuildContext context, IntegrationsViewModel viewModel, Integration integration) async {
  if (integration.authMethod != IntegrationAuthMethod.apiKey) {
    await viewModel.connect(integration);
    return;
  }
  final apiAccessToken = await showDialog<String>(
    context: context,
    builder: (_) => const _TailscaleCredentialsDialog(),
  );
  if (apiAccessToken == null) return;
  await viewModel.connectTailscale(integration, apiAccessToken: apiAccessToken);
}

class _TailscaleCredentialsDialog extends StatefulWidget {
  const _TailscaleCredentialsDialog();

  @override
  State<_TailscaleCredentialsDialog> createState() => _TailscaleCredentialsDialogState();
}

class _TailscaleCredentialsDialogState extends State<_TailscaleCredentialsDialog> {
  String _apiAccessToken = '';

  bool get _canSubmit => _apiAccessToken.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Conectar Tailscale'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No painel do Tailscale: Settings → Keys → "API access tokens" → Generate access token... '
              'e cole o valor abaixo.',
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'API access token',
              hint: 'tskey-api-...',
              obscureText: true,
              onChanged: (v) => setState(() => _apiAccessToken = v),
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Cancelar',
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.small,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Conectar',
          size: AppButtonSize.small,
          onPressed: _canSubmit ? () => Navigator.of(context).pop(_apiAccessToken.trim()) : null,
        ),
      ],
    );
  }
}

class _IntegrationsBody extends StatelessWidget {
  const _IntegrationsBody({required this.viewModel});

  final IntegrationsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;

    if (viewModel.isLoading && !viewModel.hasIntegrations) {
      return Padding(
        padding: EdgeInsets.only(top: rem(80)),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    if (viewModel.loadError != null && !viewModel.hasIntegrations) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        message: 'Não foi possível carregar suas integrações.',
        action: AppButton(
          label: 'Tentar de novo',
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.small,
          onPressed: viewModel.load,
        ),
      );
    }

    final network = viewModel.byCategory(IntegrationCategory.network);
    final library = viewModel.byCategory(IntegrationCategory.library);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (viewModel.actionError != null) ...[
          const InlineNotice(text: 'Não foi possível concluir a ação. Tente de novo em instantes.'),
          SizedBox(height: rem(Space.lg)),
        ],
        if (viewModel.missingRequired.isNotEmpty) ...[
          InlineNotice(
            text: 'O Tailscale é obrigatório: é ele que permite conectar em outro PC ou acessar este dispositivo '
                'pelo celular. Conecte abaixo pra continuar.',
          ),
          SizedBox(height: rem(Space.xxxl)),
        ],
        if (network.isNotEmpty) ...[
          const SectionLabel('Rede'),
          SizedBox(height: rem(Space.md)),
          for (final integration in network)
            Padding(
              padding: EdgeInsets.only(bottom: rem(Space.lg)),
              child: _IntegrationHeroCard(
                integration: integration,
                pending: viewModel.isPending(integration.id),
                onConnect: () => _handleConnect(context, viewModel, integration),
                onDisconnect: () => viewModel.disconnect(integration),
              ),
            ),
          SizedBox(height: rem(Space.xl)),
        ],
        if (library.isNotEmpty) ...[
          const SectionLabel('Biblioteca de jogos'),
          SizedBox(height: rem(Space.md)),
          AppCard(
            padding: EdgeInsets.zero,
            radius: Radii.lg,
            child: Column(
              children: [
                for (final (index, integration) in library.indexed)
                  _IntegrationRow(
                    integration: integration,
                    isLast: index == library.length - 1,
                    pending: viewModel.isPending(integration.id),
                    onConnect: () => viewModel.connect(integration),
                    onDisconnect: () => viewModel.disconnect(integration),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _IntegrationHeroCard extends StatelessWidget {
  const _IntegrationHeroCard({
    required this.integration,
    required this.pending,
    required this.onConnect,
    required this.onDisconnect,
  });

  final Integration integration;
  final bool pending;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    final connected = integration.isConnected;

    return AppCard(
      highlighted: connected,
      radius: Radii.xl,
      padding: EdgeInsets.all(rem(Space.xxl)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: rem(56),
            height: rem(56),
            decoration: BoxDecoration(
              color: connected ? AppColors.onBrand.withValues(alpha: 0.12) : AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(rem(Radii.lg)),
            ),
            child: Icon(integration.icon, size: rem(26), color: AppColors.textPrimary),
          ),
          SizedBox(width: rem(18)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(integration.name, overflow: TextOverflow.ellipsis, style: text.title)),
                    SizedBox(width: rem(Space.sm + 2)),
                    if (connected)
                      const TagPill(label: 'Conectado', color: AppColors.success)
                    else if (integration.required)
                      const TagPill(label: 'Obrigatório', color: AppColors.warning),
                  ],
                ),
                SizedBox(height: rem(Space.xs)),
                Text(
                  connected ? 'Conectado como ${integration.connectedAs}' : integration.description,
                  style: text.body.copyWith(fontSize: rem(13)),
                ),
              ],
            ),
          ),
          SizedBox(width: rem(Space.lg)),
          _ConnectButton(integration: integration, pending: pending, onConnect: onConnect, onDisconnect: onDisconnect),
        ],
      ),
    );
  }
}

/// Botão de conectar/desconectar de uma integração. Quando a integração
/// precisa de uma chave colada à mão (hoje só o Tailscale), o rótulo e o
/// ícone deixam isso explícito em vez de parecer um login.
class _ConnectButton extends StatelessWidget {
  const _ConnectButton({
    required this.integration,
    required this.pending,
    required this.onConnect,
    required this.onDisconnect,
  });

  final Integration integration;
  final bool pending;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    if (integration.isConnected) {
      return AppButton(label: 'Desconectar', variant: AppButtonVariant.secondary, loading: pending, onPressed: onDisconnect);
    }
    if (integration.authMethod == IntegrationAuthMethod.apiKey) {
      return AppButton(
        label: 'Inserir chave',
        icon: Icons.key_rounded,
        variant: AppButtonVariant.inverse,
        loading: pending,
        onPressed: onConnect,
      );
    }
    return AppButton(label: 'Conectar', loading: pending, onPressed: onConnect);
  }
}

class _IntegrationRow extends StatelessWidget {
  const _IntegrationRow({
    required this.integration,
    required this.isLast,
    required this.pending,
    required this.onConnect,
    required this.onDisconnect,
  });

  final Integration integration;
  final bool isLast;
  final bool pending;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    final connected = integration.isConnected;

    return HoverBuilder(
      builder: (context, hovering) => AnimatedContainer(
        duration: Motion.fast,
        padding: EdgeInsets.symmetric(horizontal: rem(Space.xl), vertical: rem(Space.md + 2)),
        decoration: BoxDecoration(
          color: hovering ? AppColors.surfaceHover : Colors.transparent,
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: rem(38),
              height: rem(38),
              decoration: const BoxDecoration(color: AppColors.surfaceRaised, shape: BoxShape.circle),
              child: Icon(integration.icon, size: rem(18), color: AppColors.textPrimary),
            ),
            SizedBox(width: rem(Space.md + 2)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(integration.name, style: text.bodyStrong),
                  SizedBox(height: rem(Space.xxs)),
                  Text(
                    connected ? 'Conectado como ${integration.connectedAs}' : integration.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.caption,
                  ),
                ],
              ),
            ),
            AppButton(
              label: connected ? 'Desconectar' : 'Conectar',
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              loading: pending,
              onPressed: connected ? onDisconnect : onConnect,
            ),
          ],
        ),
      ),
    );
  }
}
