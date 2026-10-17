import 'package:flutter/widgets.dart';

/// Expõe o estado de hover pro [builder] e trata o clique. Substitui o par
/// `MouseRegion` + `setState` que todo componente interativo precisaria.
class HoverBuilder extends StatefulWidget {
  const HoverBuilder({super.key, required this.builder, this.onTap, this.cursor});

  final Widget Function(BuildContext context, bool hovering) builder;
  final VoidCallback? onTap;

  /// Padrão: mão quando há [onTap], cursor normal caso contrário.
  final MouseCursor? cursor;

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _hovering = false;

  void _setHovering(bool value) {
    if (_hovering != value) setState(() => _hovering = value);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(context, _hovering);
    return MouseRegion(
      cursor: widget.cursor ?? (widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer),
      onEnter: (_) => _setHovering(true),
      onExit: (_) => _setHovering(false),
      child: widget.onTap == null
          ? child
          : GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: child),
    );
  }
}
