import 'package:flutter/material.dart';

import '../responsive.dart';
import '../tokens/colors.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';

/// Superfície base do app. [highlighted] aplica o tratamento de destaque da
/// marca (gradiente + borda + glow) — usado pra "o que está ativo/disponível"
/// (dispositivo online, conta atual).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = Radii.xxl,
    this.highlighted = false,
    this.hovering = false,
  });

  final Widget child;

  /// Padrão: `Space.xl` em todos os lados. Use `EdgeInsets.zero` pra listas
  /// que controlam o próprio espaçamento por linha.
  final EdgeInsetsGeometry? padding;
  final double radius;
  final bool highlighted;
  final bool hovering;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.curve,
      padding: padding ?? EdgeInsets.all(rem(Space.xl)),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(rem(radius)),
        gradient: highlighted
            ? LinearGradient(
                colors: [AppColors.brand.withValues(alpha: 0.22), AppColors.brandAlt.withValues(alpha: 0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: highlighted ? null : AppColors.surface,
        border: Border.all(
          color: highlighted
              ? AppColors.brand.withValues(alpha: hovering ? 0.85 : 0.5)
              : (hovering ? AppColors.textMuted.withValues(alpha: 0.4) : AppColors.border),
          width: highlighted ? 1.4 : 1,
        ),
        boxShadow: [
          if (highlighted)
            BoxShadow(
              color: AppColors.brand.withValues(alpha: hovering ? 0.28 : 0.16),
              blurRadius: rem(hovering ? 32 : 22),
              offset: Offset(0, rem(10)),
            )
          else if (hovering)
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.25),
              blurRadius: rem(18),
              offset: Offset(0, rem(8)),
            ),
        ],
      ),
      child: child,
    );
  }
}
