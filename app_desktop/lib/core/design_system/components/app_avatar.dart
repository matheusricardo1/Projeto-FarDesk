import 'package:flutter/material.dart';

import '../responsive.dart';
import '../tokens/colors.dart';
import '../tokens/motion.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initial,
    required this.colors,
    this.imageUrl,
    this.size = 36,
    this.selected = false,
    this.glow = false,
  });

  final String initial;
  final List<Color> colors;

  /// Foto de perfil (ex: da conta Google) — some por cima do gradiente com a
  /// inicial quando carrega; sem URL, falhando o carregamento, ou enquanto
  /// carrega, o gradiente com a inicial continua sendo o que aparece.
  final String? imageUrl;

  /// Diâmetro base (passa pela escala responsiva).
  final double size;

  /// Anel de destaque ao redor (ex: avatar da sidebar quando a tela de conta
  /// está aberta).
  final bool selected;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final diameter = rem(size);
    final url = imageUrl;
    return AnimatedContainer(
      duration: Motion.fast,
      padding: EdgeInsets.all(selected ? rem(2.5) : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.brandAlt : Colors.transparent, width: 1.6),
      ),
      child: AnimatedContainer(
        duration: Motion.fast,
        width: diameter,
        height: diameter,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: glow ? [BoxShadow(color: colors.first.withValues(alpha: 0.4), blurRadius: rem(10))] : const [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              initial,
              style: TextStyle(color: AppColors.onBrand, fontWeight: FontWeight.w700, fontSize: diameter * 0.38),
            ),
            if (url != null)
              ClipOval(
                child: Image.network(
                  url,
                  key: ValueKey(url),
                  width: diameter,
                  height: diameter,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
