import 'package:flutter/painting.dart';

import 'colors.dart';

/// Escala tipográfica, já multiplicada pelo fator de responsividade atual.
/// Obtida via `context.textStyles` — nunca crie `TextStyle` com tamanho fixo
/// nas telas; derive destes com `copyWith` quando precisar de variação.
class AppTextStyles {
  const AppTextStyles(this._scale);

  final double _scale;

  /// Título de página ("Seus dispositivos", "Conta").
  TextStyle get display => _style(26, FontWeight.w700, AppColors.textPrimary, letterSpacing: -0.5);

  /// Nome em destaque (card da conta atual).
  TextStyle get title => _style(17, FontWeight.w700, AppColors.textPrimary);

  /// Título de card (nome do dispositivo).
  TextStyle get headline => _style(16, FontWeight.w700, AppColors.textPrimary);

  /// Cabeçalho de seção de configuração.
  TextStyle get sectionTitle => _style(13, FontWeight.w700, AppColors.textPrimary, letterSpacing: 0.2);

  /// Rótulo principal de linha (nome de configuração, nome de conta).
  TextStyle get bodyStrong => _style(13.5, FontWeight.w600, AppColors.textPrimary);

  /// Texto corrido / subtítulo de página.
  TextStyle get body => _style(13.5, FontWeight.w400, AppColors.textSecondary, height: 1.4);

  /// Valor de campo, item de menu.
  TextStyle get bodySmall => _style(12.5, FontWeight.w500, AppColors.textPrimary);

  /// Descrições e textos de apoio.
  TextStyle get caption => _style(12, FontWeight.w400, AppColors.textSecondary, height: 1.4);

  TextStyle get label => _style(12, FontWeight.w600, AppColors.textPrimary);
  TextStyle get labelLarge => _style(13.5, FontWeight.w600, AppColors.textPrimary);

  /// Rótulo de seção em caixa alta ("SEUS DISPOSITIVOS").
  TextStyle get overline => _style(11, FontWeight.w700, AppColors.textMuted, letterSpacing: 0.8);

  /// Pílulas de status.
  TextStyle get micro => _style(10.5, FontWeight.w700, AppColors.textPrimary);

  /// Caminhos, IDs, portas.
  TextStyle get mono => _style(11.5, FontWeight.w400, AppColors.textSecondary).copyWith(fontFamily: 'monospace');

  TextStyle _style(double size, FontWeight weight, Color color, {double? letterSpacing, double? height}) {
    return TextStyle(
      fontSize: size * _scale,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
