import 'package:flutter/widgets.dart';

import '../tokens/motion.dart';

/// Troca de conteúdo com fade, preenchendo todo o espaço disponível.
///
/// O `AnimatedSwitcher` padrão empilha os filhos centralizados com restrição
/// frouxa — uma página curta acabava centralizada verticalmente em vez de
/// alinhada ao topo. Aqui o filho sempre recebe o espaço inteiro.
class FadeSwitcher extends StatelessWidget {
  const FadeSwitcher({super.key, required this.child, this.duration = Motion.medium});

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Motion.curve,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, ?current],
      ),
      child: child,
    );
  }
}
