import 'package:flutter/material.dart';

import '../responsive.dart';
import '../tokens/colors.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';
import 'hover_builder.dart';

enum AppButtonVariant {
  /// Ação principal da tela/card.
  primary,

  /// Ação secundária, com contorno.
  secondary,

  /// Ação de baixa ênfase, sem contorno.
  ghost,

  /// Fundo claro sobre superfície escura (ex: "Continuar com Google").
  inverse,

  /// Não é ação — só ocupa o lugar do botão informando o estado
  /// ("Em uso por outra sessão", "Offline").
  muted,
}

enum AppButtonSize {
  small(32),
  medium(40),
  large(48);

  const AppButtonSize(this.height);
  final double height;
}

/// Botão do design system. Altura fixa por tamanho — todos os variantes do
/// mesmo tamanho têm exatamente a mesma altura, o que mantém cards e linhas
/// alinhados independente do estado.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expand;

  bool get _interactive => onPressed != null && !loading && variant != AppButtonVariant.muted;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final small = size == AppButtonSize.small;
    final textStyle = small ? context.textStyles.label : context.textStyles.labelLarge;

    return HoverBuilder(
      onTap: _interactive ? onPressed : null,
      builder: (context, hovering) {
        final colors = _colors(hovering: hovering && _interactive);
        return AnimatedContainer(
          duration: Motion.fast,
          height: rem(size.height),
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: rem(small ? Space.md : Space.lg)),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(rem(Radii.md)),
            border: colors.border == null ? null : Border.all(color: colors.border!),
          ),
          child: loading
              ? SizedBox(
                  width: rem(16),
                  height: rem(16),
                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.foreground),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: rem(small ? 15 : 18), color: colors.foreground),
                      SizedBox(width: rem(Space.sm)),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle.copyWith(
                          color: colors.foreground,
                          fontWeight: variant == AppButtonVariant.muted ? FontWeight.w500 : null,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  ({Color background, Color foreground, Color? border}) _colors({required bool hovering}) {
    final disabled = onPressed == null;
    final hoverFill = hovering ? AppColors.surfaceHover : Colors.transparent;
    return switch (variant) {
      AppButtonVariant.primary => (
          background: disabled
              ? AppColors.brand.withValues(alpha: 0.35)
              : (hovering ? Color.lerp(AppColors.brand, AppColors.onBrand, 0.1)! : AppColors.brand),
          foreground: disabled ? AppColors.onBrand.withValues(alpha: 0.55) : AppColors.onBrand,
          border: null,
        ),
      AppButtonVariant.secondary => (
          background: hoverFill,
          foreground: disabled ? AppColors.textMuted : AppColors.textPrimary,
          border: AppColors.border,
        ),
      AppButtonVariant.ghost => (
          background: hoverFill,
          foreground: disabled ? AppColors.textMuted : AppColors.textSecondary,
          border: null,
        ),
      AppButtonVariant.inverse => (
          background: hovering ? AppColors.textPrimary : AppColors.inverseSurface,
          foreground: AppColors.textInverse,
          border: null,
        ),
      AppButtonVariant.muted => (
          background: AppColors.surfaceRaised,
          foreground: AppColors.textMuted,
          border: null,
        ),
    };
  }
}

/// Botão só de ícone (barra lateral, ações compactas).
class AppIconButton extends StatelessWidget {
  const AppIconButton({super.key, required this.icon, required this.tooltip, this.onTap, this.active = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: HoverBuilder(
        onTap: onTap,
        builder: (context, hovering) => AnimatedContainer(
          duration: Motion.fast,
          width: rem(42),
          height: rem(42),
          decoration: BoxDecoration(
            color: active
                ? AppColors.brand.withValues(alpha: 0.18)
                : (hovering ? AppColors.surfaceHover : Colors.transparent),
            borderRadius: BorderRadius.circular(rem(Radii.md + 1)),
            border: active ? Border.all(color: AppColors.brand.withValues(alpha: 0.4)) : null,
          ),
          child: Icon(icon, size: rem(19), color: active ? AppColors.brandAlt : AppColors.textSecondary),
        ),
      ),
    );
  }
}
