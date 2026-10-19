import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design_system/design_system.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/devices/presentation/devices_screen.dart';
import '../features/devices/presentation/devices_view_model.dart';
import '../features/integrations/presentation/integrations_screen.dart';
import '../features/integrations/presentation/integrations_view_model.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/settings_view_model.dart';
import 'side_rail.dart';

/// Área logada. Os ViewModels das features vivem aqui (e não em cada tela)
/// pra manter o estado ao alternar entre as seções.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DevicesViewModel(context.read())..load()),
        ChangeNotifierProvider(create: (context) => IntegrationsViewModel(context.read())..load()),
        ChangeNotifierProvider(create: (context) => SettingsViewModel(context.read())..load()),
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

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SideRail(destination: _destination, onSelect: (d) => setState(() => _destination = d)),
        const VerticalDivider(width: 1, color: AppColors.border),
        Expanded(
          child: FadeSwitcher(
            child: switch (_destination) {
              ShellDestination.devices => const DevicesScreen(key: ValueKey(ShellDestination.devices)),
              ShellDestination.integrations => const IntegrationsScreen(key: ValueKey(ShellDestination.integrations)),
              ShellDestination.settings => const SettingsScreen(key: ValueKey(ShellDestination.settings)),
              ShellDestination.account => const AccountScreen(key: ValueKey(ShellDestination.account)),
            },
          ),
        ),
      ],
    );
  }
}
