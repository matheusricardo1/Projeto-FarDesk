import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/design_system.dart';
import '../../devices/domain/device.dart';
import '../../devices/presentation/device_presentation.dart';
import '../domain/launch_target.dart';
import 'launch_target_presentation.dart';

/// Tela de stream ativo. Sem vídeo de verdade ainda — é só o "palco" preto
/// com o toolbar de controle, pronto pra receber o player quando o núcleo
/// de streaming (Sunshine/Moonlight) for integrado.
class StreamingScreen extends StatefulWidget {
  const StreamingScreen({super.key, required this.device, required this.target});

  final Device device;
  final LaunchTarget target;

  @override
  State<StreamingScreen> createState() => _StreamingScreenState();
}

class _StreamingScreenState extends State<StreamingScreen> {
  bool _toolbarOpen = true;
  bool _connecting = true;
  bool _muted = false;
  bool _showStats = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _connecting = false);
    });
    // Toolbar some sozinho depois de um tempo, como num player de verdade —
    // Esc ou o puxador no topo trazem de volta.
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _toolbarOpen = false);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleToolbar() => setState(() => _toolbarOpen = !_toolbarOpen);

  void _endSession() => Navigator.of(context).pop();

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      _toggleToolbar();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final barHeight = rem(64);
    final nubHeight = rem(20);

    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: _connecting
                  ? const _ConnectingState()
                  : _StreamPlaceholder(device: widget.device, target: widget.target),
            ),
            AnimatedPositioned(
              duration: Motion.medium,
              curve: Motion.curve,
              top: _toolbarOpen ? 0 : -barHeight,
              left: 0,
              right: 0,
              height: barHeight,
              child: _StreamToolbar(
                device: widget.device,
                target: widget.target,
                connecting: _connecting,
                muted: _muted,
                showStats: _showStats,
                onToggleMute: () => setState(() => _muted = !_muted),
                onToggleStats: () => setState(() => _showStats = !_showStats),
                onEndSession: _endSession,
              ),
            ),
            AnimatedPositioned(
              duration: Motion.medium,
              curve: Motion.curve,
              top: _toolbarOpen ? barHeight : 0,
              left: 0,
              right: 0,
              height: nubHeight,
              child: Center(child: _ToolbarPullTab(open: _toolbarOpen, onTap: _toggleToolbar)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectingState extends StatelessWidget {
  const _ConnectingState();

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: rem(28),
            height: rem(28),
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textMuted.withValues(alpha: 0.7)),
          ),
          SizedBox(height: rem(Space.lg)),
          Text('Conectando ao stream...', style: context.textStyles.caption.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _StreamPlaceholder extends StatelessWidget {
  const _StreamPlaceholder({required this.device, required this.target});

  final Device device;
  final LaunchTarget target;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(device.platform.icon, size: rem(40), color: AppColors.textMuted.withValues(alpha: 0.3)),
          SizedBox(height: rem(Space.lg)),
          Text(
            device.name,
            style: text.body.copyWith(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: rem(14)),
          ),
          SizedBox(height: rem(Space.xxs)),
          Text(
            'Streaming — ${target.label}',
            style: text.caption.copyWith(color: AppColors.textMuted.withValues(alpha: 0.35)),
          ),
        ],
      ),
    );
  }
}

class _StreamToolbar extends StatelessWidget {
  const _StreamToolbar({
    required this.device,
    required this.target,
    required this.connecting,
    required this.muted,
    required this.showStats,
    required this.onToggleMute,
    required this.onToggleStats,
    required this.onEndSession,
  });

  final Device device;
  final LaunchTarget target;
  final bool connecting;
  final bool muted;
  final bool showStats;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleStats;
  final VoidCallback onEndSession;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: rem(Space.xl)),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(device.platform.icon, size: rem(18), color: AppColors.textSecondary),
          SizedBox(width: rem(Space.sm + 2)),
          Text(device.name, style: text.bodyStrong),
          SizedBox(width: rem(Space.sm + 2)),
          StatusBadge(
            label: connecting ? 'Conectando' : 'Streaming',
            color: connecting ? AppColors.warning : AppColors.success,
            pulse: !connecting,
          ),
          const Spacer(),
          _ToolbarToggle(icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, active: muted, tooltip: 'Áudio', onTap: onToggleMute),
          SizedBox(width: rem(Space.sm)),
          _ToolbarToggle(icon: Icons.speed_rounded, active: showStats, tooltip: 'Estatísticas de desempenho', onTap: onToggleStats),
          SizedBox(width: rem(Space.lg)),
          AppButton(
            label: 'Encerrar sessão',
            variant: AppButtonVariant.danger,
            size: AppButtonSize.small,
            icon: Icons.call_end_rounded,
            onPressed: onEndSession,
          ),
        ],
      ),
    );
  }
}

class _ToolbarToggle extends StatelessWidget {
  const _ToolbarToggle({required this.icon, required this.active, required this.tooltip, required this.onTap});

  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: HoverBuilder(
        onTap: onTap,
        builder: (context, hovering) => AnimatedContainer(
          duration: Motion.fast,
          width: rem(36),
          height: rem(36),
          decoration: BoxDecoration(
            color: active
                ? AppColors.brand.withValues(alpha: 0.18)
                : (hovering ? AppColors.surfaceHover : Colors.transparent),
            borderRadius: BorderRadius.circular(rem(Radii.sm + 2)),
            border: active ? Border.all(color: AppColors.brand.withValues(alpha: 0.4)) : null,
          ),
          child: Icon(icon, size: rem(17), color: active ? AppColors.brandAlt : AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ToolbarPullTab extends StatelessWidget {
  const _ToolbarPullTab({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return Tooltip(
      message: open ? 'Esconder controles (Esc)' : 'Mostrar controles (Esc)',
      waitDuration: const Duration(milliseconds: 400),
      child: HoverBuilder(
        onTap: onTap,
        builder: (context, hovering) => Container(
          width: rem(56),
          height: rem(18),
          decoration: BoxDecoration(
            color: (hovering ? AppColors.surfaceHover : AppColors.surface).withValues(alpha: 0.92),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(rem(Radii.sm + 2))),
            border: const Border(left: BorderSide(color: AppColors.border), right: BorderSide(color: AppColors.border), bottom: BorderSide(color: AppColors.border)),
          ),
          alignment: Alignment.center,
          child: Icon(
            open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            size: rem(16),
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
