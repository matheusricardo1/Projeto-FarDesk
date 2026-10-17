import 'package:flutter/widgets.dart';

import 'responsive.dart';

abstract final class BrandAssets {
  static const icon = 'assets/branding/icon.png';
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size, this.scaled = true});

  /// Tamanho base. Com [scaled] falso, é usado em pixels exatos (ex: chrome
  /// da janela, que não acompanha a escala responsiva).
  final double size;
  final bool scaled;

  @override
  Widget build(BuildContext context) {
    final px = scaled ? context.rem(size) : size;
    return ClipRRect(
      borderRadius: BorderRadius.circular(px * 0.28),
      child: Image.asset(BrandAssets.icon, width: px, height: px, filterQuality: FilterQuality.medium),
    );
  }
}
