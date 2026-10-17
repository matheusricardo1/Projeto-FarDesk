import 'package:flutter/material.dart';

import '../responsive.dart';
import '../tokens/colors.dart';
import '../tokens/motion.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initial,
    required this.colors,
    this.size = 36,
    this.selected = false,
    this.glow = false,
  });

  final String initial;
  final List<Color> colors;

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
        child: Text(
          initial,
          style: TextStyle(color: AppColors.onBrand, fontWeight: FontWeight.w700, fontSize: diameter * 0.38),
        ),
      ),
    );
  }
}
