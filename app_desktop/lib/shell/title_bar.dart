import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../core/design_system/design_system.dart';

/// Barra de título própria (sem moldura nativa). Tamanhos fixos de propósito:
/// chrome de janela não acompanha a escala responsiva do conteúdo.
class TitleBar extends StatefulWidget {
  const TitleBar({super.key, this.onBeforeClose});

  final Future<void> Function()? onBeforeClose;

  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> with WindowListener {
  bool _maximized = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
    windowManager.isMaximized().then((value) {
      if (mounted) setState(() => _maximized = value);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  @override
  Future<void> onWindowClose() async {
    if (_closing) return;
    _closing = true;
    try {
      await widget.onBeforeClose?.call();
    } finally {
      await windowManager.destroy();
    }
  }

  Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: _toggleMaximize,
      child: Container(
        height: 40,
        color: AppColors.background,
        child: Row(
          children: [
            const SizedBox(width: Space.lg),
            const AppLogo(size: 16, scaled: false),
            const SizedBox(width: Space.sm + 2),
            const Text(
              'FarDesk',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.2),
            ),
            const Spacer(),
            _WindowButton(icon: Icons.remove, onTap: windowManager.minimize),
            _WindowButton(icon: _maximized ? Icons.filter_none : Icons.crop_square, onTap: _toggleMaximize),
            _WindowButton(icon: Icons.close, hoverColor: AppColors.danger, onTap: windowManager.close),
          ],
        ),
      ),
    );
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({required this.icon, required this.onTap, this.hoverColor = AppColors.surfaceHover});

  final IconData icon;
  final VoidCallback onTap;
  final Color hoverColor;

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      onTap: onTap,
      cursor: SystemMouseCursors.basic,
      builder: (context, hovering) => Container(
        width: 46,
        height: 40,
        alignment: Alignment.center,
        color: hovering ? hoverColor : Colors.transparent,
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}
