import 'package:flutter/painting.dart';

/// Paleta do FarDesk. Componentes e telas só usam estas cores — nada de
/// `Color(0x...)` avulso fora daqui.
abstract final class AppColors {
  // Neutros (do mais fundo ao mais elevado)
  static const background = Color(0xFF0A0C10);
  static const surface = Color(0xFF12151C);
  static const surfaceRaised = Color(0xFF1A1E27);
  static const surfaceHover = Color(0xFF222733);
  static const border = Color(0xFF242934);

  // Marca
  static const brand = Color(0xFF7B5CFA);
  static const brandAlt = Color(0xFF4CC9F0);
  static const onBrand = Color(0xFFFFFFFF);
  static const brandGradient = LinearGradient(
    colors: [brand, brandAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Texto
  static const textPrimary = Color(0xFFF5F6FA);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF5B6270);
  static const textInverse = Color(0xFF1A1A1A);

  // Semânticas
  static const success = Color(0xFF3DDC84);
  static const warning = Color(0xFFFFB454);
  static const neutral = Color(0xFF6B7280);
  static const inactive = Color(0xFF3A3F4B);
  static const danger = Color(0xFFFF5470);

  static const shadow = Color(0xFF000000);
  static const inverseSurface = Color(0xFFFFFFFF);
}
