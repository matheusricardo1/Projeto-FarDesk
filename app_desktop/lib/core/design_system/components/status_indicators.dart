import 'package:flutter/material.dart';

import '../responsive.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Ponto de status com glow. Com [pulse], pulsa suavemente — sinaliza "isso
/// está vivo agora" (ex: dispositivo online).
class StatusDot extends StatefulWidget {
  const StatusDot({super.key, required this.color, this.size = 8, this.pulse = false});

  final Color color;

  /// Tamanho base (passa pela escala responsiva).
  final double size;
  final bool pulse;

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = context.rem(widget.size);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final glow = widget.pulse ? 0.75 + _controller.value * 0.25 : 1.0;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.65 * glow),
                blurRadius: size * 1.1 * glow,
                spreadRadius: size * 0.12,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Pílula escura com ponto de status e rótulo — fica legível sobre qualquer
/// fundo, inclusive gradiente de destaque.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color, this.pulse = false});

  final String label;
  final Color color;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: rem(Space.sm), vertical: rem(Space.xs)),
      decoration: BoxDecoration(
        color: AppColors.shadow.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusDot(color: color, size: 7, pulse: pulse),
          SizedBox(width: rem(Space.xs + 1)),
          Text(label, style: context.textStyles.micro),
        ],
      ),
    );
  }
}

/// Etiqueta tingida com a cor semântica ("Conta atual").
class TagPill extends StatelessWidget {
  const TagPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: rem(Space.sm), vertical: rem(3)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(label, style: context.textStyles.micro.copyWith(color: color, fontSize: rem(10))),
    );
  }
}
