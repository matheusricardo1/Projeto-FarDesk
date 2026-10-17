import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design_system/design_system.dart';
import '../features/account/presentation/account_presentation.dart';
import '../features/account/presentation/session_view_model.dart';

enum ShellDestination { devices, settings, account }

class SideRail extends StatelessWidget {
  const SideRail({super.key, required this.destination, required this.onSelect});

  final ShellDestination destination;
  final ValueChanged<ShellDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final session = context.watch<SessionViewModel>();
    final account = session.activeAccount;

    return Container(
      width: rem(80),
      color: AppColors.surface,
      child: Column(
        children: [
          SizedBox(height: rem(Space.xl + 2)),
          AppIconButton(
            icon: Icons.devices_other_rounded,
            tooltip: 'Dispositivos',
            active: destination == ShellDestination.devices,
            onTap: () => onSelect(ShellDestination.devices),
          ),
          const Spacer(),
          AppIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Configurações',
            active: destination == ShellDestination.settings,
            onTap: () => onSelect(ShellDestination.settings),
          ),
          SizedBox(height: rem(18)),
          if (account != null)
            Tooltip(
              message: 'Conta — ${account.name}',
              waitDuration: const Duration(milliseconds: 400),
              child: HoverBuilder(
                onTap: () => onSelect(ShellDestination.account),
                builder: (context, hovering) => AppAvatar(
                  initial: account.initial,
                  colors: avatarGradientAt(session.activeIndex),
                  selected: destination == ShellDestination.account,
                  glow: hovering,
                ),
              ),
            ),
          SizedBox(height: rem(Space.xl + 2)),
        ],
      ),
    );
  }
}
