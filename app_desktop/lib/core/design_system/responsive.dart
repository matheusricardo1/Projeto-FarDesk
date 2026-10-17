import 'package:flutter/widgets.dart';

import 'tokens/typography.dart';

/// Níveis de responsividade por faixa de largura (tipo breakpoint de media
/// query). Dentro de uma faixa o fator é fixo — só muda ao cruzar um
/// breakpoint, evitando o efeito de "zoom contínuo".
enum AppSizeTier {
  compact(maxWidth: 1050, factor: 0.90),
  comfortable(maxWidth: 1400, factor: 1.0),
  spacious(maxWidth: 1800, factor: 1.08),
  expansive(maxWidth: double.infinity, factor: 1.15);

  const AppSizeTier({required this.maxWidth, required this.factor});

  final double maxWidth;
  final double factor;

  static AppSizeTier fromWidth(double width) {
    for (final tier in values) {
      if (width < tier.maxWidth) return tier;
    }
    return expansive;
  }
}

extension DesignSystemContext on BuildContext {
  AppSizeTier get sizeTier => AppSizeTier.fromWidth(MediaQuery.sizeOf(this).width);

  /// Equivalente a "rem" do CSS: converte um valor base (tokens de
  /// espaçamento, raio, tamanho) pro nível de responsividade atual.
  double rem(double value) => value * sizeTier.factor;

  AppTextStyles get textStyles => AppTextStyles(sizeTier.factor);
}
