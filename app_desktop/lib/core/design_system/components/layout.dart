import 'package:flutter/material.dart';

import '../responsive.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Padding padrão de conteúdo de página.
EdgeInsets pagePadding(BuildContext context) {
  final rem = context.rem;
  return EdgeInsets.fromLTRB(rem(36), rem(Space.xxxl), rem(36), rem(Space.huge));
}

/// Cabeçalho de página: título + subtítulo, com ação opcional à direita.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.display),
              if (subtitle != null) ...[
                SizedBox(height: context.rem(Space.xs + 2)),
                Text(subtitle!, style: text.body),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[SizedBox(width: context.rem(Space.lg)), trailing!],
      ],
    );
  }
}

/// Rótulo de seção em caixa alta.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: context.textStyles.overline);
}

enum NoticeTone { warning, info }

/// Aviso em linha. `warning` pra risco real (segurança, falha); `info` pra
/// orientação neutra.
class InlineNotice extends StatelessWidget {
  const InlineNotice({super.key, required this.text, this.tone = NoticeTone.warning});

  final String text;
  final NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final color = tone == NoticeTone.warning ? AppColors.danger : AppColors.brandAlt;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(rem(Space.md)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(rem(Radii.md)),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tone == NoticeTone.warning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            size: rem(16),
            color: color,
          ),
          SizedBox(width: rem(Space.sm + 2)),
          Expanded(child: Text(text, style: context.textStyles.caption.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

/// Estado vazio/placeholder dentro de uma superfície.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(rem(28)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(rem(Radii.lg)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: rem(20), color: AppColors.textMuted),
          SizedBox(width: rem(Space.lg - 2)),
          Expanded(child: Text(message, style: context.textStyles.caption.copyWith(fontSize: rem(12.5), height: 1.5))),
          if (action != null) ...[SizedBox(width: rem(Space.lg)), action!],
        ],
      ),
    );
  }
}

/// Tabela simples somente leitura.
class AppTable extends StatelessWidget {
  const AppTable({super.key, required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(rem(Radii.lg)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: rem(Space.xl), vertical: rem(Space.md)),
            child: Row(
              children: [for (final header in headers) Expanded(child: Text(header.toUpperCase(), style: text.overline))],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          for (final row in rows)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: rem(Space.xl), vertical: rem(Space.sm + 2)),
              child: Row(
                children: [
                  for (final cell in row)
                    Expanded(child: Text(cell, style: text.mono.copyWith(color: AppColors.textPrimary, fontSize: rem(12.5)))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
