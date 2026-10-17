/// Escala de espaçamento. Valores base — sempre passe por `context.rem(...)`.
abstract final class Space {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}

/// Raios de borda. Valores base — sempre passe por `context.rem(...)`.
abstract final class Radii {
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
  static const double xxl = 20;
  static const double pill = 999;
}
