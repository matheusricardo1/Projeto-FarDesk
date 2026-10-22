import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design_system/design_system.dart';
import '../core/host_agent/pairing_api_client.dart';
import '../core/network/tailscale_network_manager.dart';
import '../core/update/app_update_service.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/devices/presentation/devices_screen.dart';
import '../features/devices/presentation/devices_view_model.dart';
import '../features/devices/presentation/host_activation_view_model.dart';
import '../features/integrations/presentation/integrations_screen.dart';
import '../features/integrations/presentation/integrations_view_model.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/settings_view_model.dart';
import '../features/settings/presentation/update_view_model.dart';
import 'side_rail.dart';

/// Área logada. Os ViewModels das features vivem aqui (e não em cada tela)
/// pra manter o estado ao alternar entre as seções.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    unawaited(_startFarDeskNetwork(context.read<FarDeskNetworkManager?>()));
  }

  Future<void> shutdown() async {
    final hostActivation = context.read<HostActivationViewModel>();
    final network = context.read<FarDeskNetworkManager?>();
    await hostActivation.shutdown();
    await network?.stop();
  }

  Future<void> _startFarDeskNetwork(FarDeskNetworkManager? network) async {
    if (network == null) return;
    try {
      await network.ensureUp();
    } catch (error, stackTrace) {
      debugPrint('[AppShell] não foi possível iniciar a rede FarDesk: $error');
      debugPrint('$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => DevicesViewModel(context.read())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => HostActivationViewModel(
            pairingApiClient: context.read<PairingApiClient?>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => IntegrationsViewModel(context.read())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsViewModel(context.read())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => UpdateViewModel(context.read<AppUpdateService>()),
        ),
      ],
      child: const _ShellLayout(),
    );
  }
}

class _ShellLayout extends StatefulWidget {
  const _ShellLayout();

  @override
  State<_ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends State<_ShellLayout> {
  ShellDestination _destination = ShellDestination.devices;
  late final HostActivationViewModel _hostActivation;
  late final DevicesViewModel _devices;

  @override
  void initState() {
    super.initState();
    _hostActivation = context.read<HostActivationViewModel>();
    _devices = context.read<DevicesViewModel>();
    // Heartbeat é "este PC está disponível como host" — não "a tela de
    // dispositivos está aberta". Liga/desliga seguindo o estado real do
    // `HostActivationViewModel`, não o ciclo de vida da tela.
    _syncHeartbeat();
    _hostActivation.addListener(_syncHeartbeat);
  }

  void _syncHeartbeat() {
    if (_hostActivation.status == HostActivationStatus.ready) {
      _devices.startHeartbeat();
    } else {
      _devices.stopHeartbeat();
    }
  }

  @override
  void dispose() {
    _hostActivation.removeListener(_syncHeartbeat);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SideRail(
          destination: _destination,
          onSelect: (d) => setState(() => _destination = d),
        ),
        const VerticalDivider(width: 1, color: AppColors.border),
        Expanded(
          child: FadeSwitcher(
            child: switch (_destination) {
              ShellDestination.devices => const DevicesScreen(
                key: ValueKey(ShellDestination.devices),
              ),
              ShellDestination.integrations => const IntegrationsScreen(
                key: ValueKey(ShellDestination.integrations),
              ),
              ShellDestination.settings => const SettingsScreen(
                key: ValueKey(ShellDestination.settings),
              ),
              ShellDestination.account => const AccountScreen(
                key: ValueKey(ShellDestination.account),
              ),
            },
          ),
        ),
      ],
    );
  }
}
