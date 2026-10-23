import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/account.dart';
import 'account_presentation.dart';
import 'session_view_model.dart';

/// Identidade e gerenciamento de contas. Separada de Configurações de
/// propósito: aqui é "quem está usando", lá é "como o app se comporta".
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final session = context.watch<SessionViewModel>();
    final active = session.activeAccount;
    if (active == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: rem(720)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(title: 'Conta', subtitle: 'Gerencie quem está conectado ao FarDesk neste dispositivo.'),
            SizedBox(height: rem(Space.xxl + 4)),
            _ActiveAccountCard(
              account: active,
              colors: avatarGradientAt(session.activeIndex),
              signingOut: session.isSigningOut,
              onSignOut: session.signOut,
            ),
            SizedBox(height: rem(Space.xxxl)),
            const SectionLabel('Contas neste dispositivo'),
            SizedBox(height: rem(Space.xs)),
            Text(
              'Troque entre contas sem sair do FarDesk — dispositivos e integrações ficam separados por conta.',
              style: context.textStyles.caption,
            ),
            SizedBox(height: rem(Space.md)),
            AppCard(
              padding: EdgeInsets.zero,
              radius: Radii.lg,
              child: Column(
                children: [
                  for (final (index, account) in session.accounts.indexed)
                    _AccountRow(
                      account: account,
                      colors: avatarGradientAt(index),
                      isActive: account.id == active.id,
                      switching: session.pendingSwitchId == account.id,
                      onUse: () => session.switchAccount(account.id),
                    ),
                  _AddAccountRow(loading: session.isAddingAccount, onTap: session.addAccount),
                ],
              ),
            ),
            if (session.error != null) ...[
              SizedBox(height: rem(Space.lg)),
              const InlineNotice(text: 'Não foi possível concluir a ação. Tente de novo em instantes.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveAccountCard extends StatelessWidget {
  const _ActiveAccountCard({
    required this.account,
    required this.colors,
    required this.signingOut,
    required this.onSignOut,
  });

  final Account account;
  final List<Color> colors;
  final bool signingOut;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    return AppCard(
      highlighted: true,
      radius: Radii.xl,
      padding: EdgeInsets.all(rem(Space.xxl)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(initial: account.initial, imageUrl: account.avatarUrl, colors: colors, size: 72),
          SizedBox(width: rem(Space.xl)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TagPill(label: 'Conta atual', color: AppColors.success),
                SizedBox(height: rem(Space.sm)),
                Text(account.name, overflow: TextOverflow.ellipsis, style: text.display.copyWith(fontSize: rem(21))),
                SizedBox(height: rem(Space.xxs)),
                Row(
                  children: [
                    Icon(Icons.mail_outline_rounded, size: rem(14), color: AppColors.textMuted),
                    SizedBox(width: rem(Space.xs + 1)),
                    Flexible(
                      child: Text(
                        account.email,
                        overflow: TextOverflow.ellipsis,
                        style: text.body.copyWith(fontSize: rem(13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: rem(Space.lg)),
          AppButton(
            label: 'Sair desta conta',
            icon: Icons.logout_rounded,
            variant: AppButtonVariant.danger,
            size: AppButtonSize.small,
            loading: signingOut,
            onPressed: signingOut ? null : onSignOut,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.colors,
    required this.isActive,
    required this.switching,
    required this.onUse,
  });

  final Account account;
  final List<Color> colors;
  final bool isActive;
  final bool switching;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    return HoverBuilder(
      builder: (context, hovering) => AnimatedContainer(
        duration: Motion.fast,
        padding: EdgeInsets.symmetric(horizontal: rem(18), vertical: rem(Space.md + 2)),
        decoration: BoxDecoration(
          color: hovering ? AppColors.surfaceHover : Colors.transparent,
          border: const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            AppAvatar(initial: account.initial, imageUrl: account.avatarUrl, colors: colors, size: 38),
            SizedBox(width: rem(Space.md + 2)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name, style: text.bodyStrong),
                  SizedBox(height: rem(Space.xxs)),
                  Text(account.email, style: text.caption),
                ],
              ),
            ),
            if (isActive)
              Text('Em uso', style: text.label.copyWith(color: AppColors.textMuted))
            else
              AppButton(
                label: 'Usar esta conta',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                loading: switching,
                onPressed: onUse,
              ),
          ],
        ),
      ),
    );
  }
}

class _AddAccountRow extends StatelessWidget {
  const _AddAccountRow({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return HoverBuilder(
      onTap: loading ? null : onTap,
      builder: (context, hovering) => AnimatedContainer(
        duration: Motion.fast,
        padding: EdgeInsets.symmetric(horizontal: rem(18), vertical: rem(Space.md + 2)),
        color: hovering ? AppColors.surfaceHover : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: rem(38),
              height: rem(38),
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border, width: 1.4)),
              child: loading
                  ? SizedBox(
                      width: rem(14),
                      height: rem(14),
                      child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandAlt),
                    )
                  : Icon(Icons.add, size: rem(18), color: AppColors.textSecondary),
            ),
            SizedBox(width: rem(Space.md + 2)),
            Text(
              loading ? 'Conectando conta...' : 'Adicionar outra conta',
              style: context.textStyles.bodyStrong.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
