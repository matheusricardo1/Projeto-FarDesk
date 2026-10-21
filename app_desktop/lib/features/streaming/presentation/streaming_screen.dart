import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/host_agent/host_activation.dart';
import '../../../core/host_agent/host_api.dart';
import '../../../core/moonlight/moonlight_client.dart';
import '../../../core/moonlight/remote_connection_coordinator.dart';
import '../../../core/moonlight/streaming_session_launcher.dart';
import '../../../core/network/tailscale_network_manager.dart';
import '../../../core/host_agent/pairing_api_client.dart';
import '../../../core/sunshine/paired_host_store.dart';
import '../../../core/sunshine/sunshine_exception.dart';
import '../../../core/sunshine/sunshine_host_client.dart';
import '../../../core/sunshine/sunshine_identity.dart';
import '../../../core/sunshine/sunshine_pairing_client.dart'
    show sunshineClientDeviceName;
import '../../devices/domain/device.dart';
import '../../devices/presentation/device_presentation.dart';
import '../domain/launch_target.dart';
import 'launch_target_presentation.dart';
import 'moonlight_video_view.dart';

/// Host usado enquanto não existe resolução real de endereço por
/// dispositivo (Tailscale/IP manual) — hoje só serve pra testar contra o
/// Sunshine rodando nesta própria máquina.
const String _testOnlyLocalHost = '127.0.0.1';

/// Tela de stream ativo. Sem vídeo de verdade ainda — é só o "palco" preto
/// com o toolbar de controle, pronto pra receber o player quando o núcleo
/// de streaming (Sunshine/Moonlight) for integrado.
class StreamingScreen extends StatefulWidget {
  const StreamingScreen({
    super.key,
    required this.device,
    required this.target,
  });

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
  String? _connectError;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _connect();
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

  /// Pareia (se preciso) e abre a sessão de stream no host remoto.
  Future<void> _connect() async {
    final moonlightClient = context.read<MoonlightClient>();
    final network = context.read<FarDeskNetworkManager?>();
    final pairingApi = context.read<PairingApiClient?>();
    final stopwatch = Stopwatch()..start();
    try {
      final identity = await SunshineIdentityStore().load();
      debugPrint(
        '[StreamingScreen] identidade carregada (${stopwatch.elapsed}).',
      );

      if (network != null &&
          pairingApi != null &&
          widget.device.id != 'debug-local-sunshine') {
        final coordinator = RemoteConnectionCoordinator(
          network: network,
          pairingApi: pairingApi,
          identity: identity,
          pairedHostStore: PairedHostStore(),
          moonlightClient: moonlightClient,
        );
        await coordinator.connect(
          deviceId: widget.device.id,
          deviceName: widget.device.name,
          targetName: widget.target.name,
        );
      } else {
        // O alvo local só existe no botão de diagnóstico disponível em
        // builds debug; o fluxo real sempre usa o coordenador remoto.
        debugPrint('[StreamingScreen] usando fluxo local de diagnóstico...');
        final hostApi = await HostActivation().ensureRunning();

        final launcher = StreamingSessionLauncher(
          identity: identity,
          pairedHostStore: PairedHostStore(),
          moonlightClient: moonlightClient,
        );

        final hostClient = await launcher.ensurePaired(
          deviceId: widget.device.id,
          host: _testOnlyLocalHost,
          selfPairViaAdmin: (pin) => _selfPairViaAdmin(hostApi, pin),
        );
        debugPrint(
          '[StreamingScreen] ensurePaired() concluído (${stopwatch.elapsed}).',
        );

        final appId = await _resolveAppId(hostClient);
        debugPrint(
          '[StreamingScreen] appId resolvido: $appId. Chamando launchAndConnect()...',
        );
        await launcher.launchAndConnect(hostClient: hostClient, appId: appId);
        debugPrint(
          '[StreamingScreen] launchAndConnect() concluído (${stopwatch.elapsed}).',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[StreamingScreen] _connect() falhou após ${stopwatch.elapsed}: $error',
      );
      debugPrint('$stackTrace');
      if (!mounted) return;
      setState(() => _connectError = error.toString());
      return;
    }
    if (mounted) setState(() => _connecting = false);
  }

  /// Confirma o PIN de pareamento pelo próprio app, via API admin do
  /// Sunshine local — substitui alguém digitando o PIN na tela do host
  /// (mesma ideia do `HostAgentPairingService`, só que pareando com nós
  /// mesmos em vez de outro dispositivo).
  Future<bool> _selfPairViaAdmin(HostApi hostApi, String pin) async {
    for (var attempt = 0; attempt < 30; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final pending = await hostApi.listPendingPairings();
      debugPrint(
        '[StreamingScreen] tentativa $attempt: pendências=${pending.map((p) => p.deviceName).toList()}',
      );
      final match = pending
          .where((p) => p.deviceName == sunshineClientDeviceName)
          .firstOrNull;
      if (match != null) {
        final accepted = await hostApi.submitPin(
          pairingId: match.pairingId,
          pin: pin,
          clientName: sunshineClientDeviceName,
        );
        debugPrint('[StreamingScreen] submitPin retornou: $accepted');
        return accepted;
      }
    }
    return false;
  }

  /// Os ids dos apps do Sunshine são gerados por ele na hora de carregar o
  /// apps.json (não existe id fixo/reservado pra "área de trabalho") — então
  /// sempre pega o id real do `/applist`. Mandar um id que não existe faz o
  /// `/launch` passar, mas o host encerra a sessão logo depois de conectar
  /// ("Process terminated" → termination reason 0x80030023).
  Future<String> _resolveAppId(SunshineHostClient hostClient) async {
    final apps = await hostClient.fetchAppList();
    debugPrint(
      '[StreamingScreen] apps no host: ${apps.map((a) => '${a.title}=${a.id}').toList()}',
    );
    if (apps.isEmpty) {
      throw const SunshineException(
        'O host não tem nenhum app configurado pra abrir.',
      );
    }

    final wanted = switch (widget.target) {
      LaunchTarget.desktop => 'desktop',
      LaunchTarget.steam => 'steam',
      LaunchTarget.hydra => 'hydra',
    };
    final match = apps
        .where((app) => app.title.toLowerCase().contains(wanted))
        .firstOrNull;
    if (match != null) return match.id;

    final desktop = apps
        .where((app) => app.title.toLowerCase().contains('desktop'))
        .firstOrNull;
    return (desktop ?? apps.first).id;
  }

  void _toggleToolbar() => setState(() => _toolbarOpen = !_toolbarOpen);

  void _endSession() => Navigator.of(context).pop();

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
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
    final moonlightClient = context.watch<MoonlightClient>();

    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: ValueListenableBuilder<MoonlightConnectionState>(
                valueListenable: moonlightClient.state,
                builder: (context, moonlightState, _) {
                  final error = _connectError;
                  if (error != null) {
                    return _StreamErrorState(message: error);
                  }
                  if (moonlightState == MoonlightConnectionState.connected) {
                    return ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: MoonlightVideoView(client: moonlightClient),
                      ),
                    );
                  }
                  return _connecting
                      ? const _ConnectingState()
                      : _StreamPlaceholder(
                          device: widget.device,
                          target: widget.target,
                        );
                },
              ),
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
              child: Center(
                child: _ToolbarPullTab(
                  open: _toolbarOpen,
                  onTap: _toggleToolbar,
                ),
              ),
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
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.textMuted.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: rem(Space.lg)),
          Text(
            'Conectando ao stream...',
            style: context.textStyles.caption.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreamErrorState extends StatelessWidget {
  const _StreamErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: rem(48)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: rem(32),
              color: AppColors.danger,
            ),
            SizedBox(height: rem(Space.lg)),
            Text(
              'Não foi possível conectar ao stream.',
              style: context.textStyles.bodyStrong,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: rem(Space.xxs)),
            Text(
              message,
              style: context.textStyles.caption.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
          Icon(
            device.platform.icon,
            size: rem(40),
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
          SizedBox(height: rem(Space.lg)),
          Text(
            device.name,
            style: text.body.copyWith(
              color: AppColors.textMuted.withValues(alpha: 0.6),
              fontSize: rem(14),
            ),
          ),
          SizedBox(height: rem(Space.xxs)),
          Text(
            'Streaming — ${target.label}',
            style: text.caption.copyWith(
              color: AppColors.textMuted.withValues(alpha: 0.35),
            ),
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
          Icon(
            device.platform.icon,
            size: rem(18),
            color: AppColors.textSecondary,
          ),
          SizedBox(width: rem(Space.sm + 2)),
          Text(device.name, style: text.bodyStrong),
          SizedBox(width: rem(Space.sm + 2)),
          StatusBadge(
            label: connecting ? 'Conectando' : 'Streaming',
            color: connecting ? AppColors.warning : AppColors.success,
            pulse: !connecting,
          ),
          const Spacer(),
          _ToolbarToggle(
            icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            active: muted,
            tooltip: 'Áudio',
            onTap: onToggleMute,
          ),
          SizedBox(width: rem(Space.sm)),
          _ToolbarToggle(
            icon: Icons.speed_rounded,
            active: showStats,
            tooltip: 'Estatísticas de desempenho',
            onTap: onToggleStats,
          ),
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
  const _ToolbarToggle({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

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
            border: active
                ? Border.all(color: AppColors.brand.withValues(alpha: 0.4))
                : null,
          ),
          child: Icon(
            icon,
            size: rem(17),
            color: active ? AppColors.brandAlt : AppColors.textSecondary,
          ),
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
            color: (hovering ? AppColors.surfaceHover : AppColors.surface)
                .withValues(alpha: 0.92),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(rem(Radii.sm + 2)),
            ),
            border: const Border(
              left: BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            open
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: rem(16),
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
