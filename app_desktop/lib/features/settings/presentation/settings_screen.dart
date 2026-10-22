import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/client_settings_schema.dart';
import '../domain/host_settings_schema.dart';
import '../domain/setting.dart';
import 'settings_block_view.dart';
import 'settings_view_model.dart';
import 'updates_view.dart';

const _pageIcons = <String, IconData>{
  'client.basic': Icons.tune_rounded,
  'client.input': Icons.mouse_outlined,
  'client.controller': Icons.sports_esports_outlined,
  'client.audio': Icons.volume_up_outlined,
  'client.session': Icons.cable_outlined,
  'client.advanced': Icons.settings_suggest_outlined,
  'client.interface': Icons.palette_outlined,
  'host.general': Icons.tune_rounded,
  'host.input': Icons.gamepad_outlined,
  'host.audioVideo': Icons.videocam_outlined,
  'host.network': Icons.lan_outlined,
  'host.configFiles': Icons.insert_drive_file_outlined,
  'host.advanced': Icons.settings_suggest_outlined,
  'about.updates': Icons.system_update_alt_rounded,
};

/// Não vem do schema declarativo (precisa de progresso de download, botões
/// de ação próprios) — tratada à parte em `_SettingsScreenState.build`.
const _updatesPage = SettingsPage(id: 'about.updates', label: 'Atualizações', scope: SettingsScope.client, blocks: []);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsPage _selected = clientSettingsPages.first;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final viewModel = context.watch<SettingsViewModel>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: rem(248),
          decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: rem(Space.xxl)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NavSection(title: 'Cliente', pages: clientSettingsPages, selected: _selected, onSelect: _select),
                SizedBox(height: rem(Space.xl + 2)),
                _NavSection(title: 'Host desta máquina', pages: hostSettingsPages, selected: _selected, onSelect: _select),
                SizedBox(height: rem(Space.xl + 2)),
                _NavSection(title: 'Sobre', pages: const [_updatesPage], selected: _selected, onSelect: _select),
              ],
            ),
          ),
        ),
        Expanded(
          child: _selected.id == _updatesPage.id
              ? const UpdatesView()
              : viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                  : SingleChildScrollView(
                      key: PageStorageKey(_selected.id),
                      padding: EdgeInsets.all(rem(Space.xxxl)),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: rem(720)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (viewModel.error != null) ...[
                              const InlineNotice(text: 'Algumas configurações não puderam ser salvas.'),
                              SizedBox(height: rem(Space.xxl)),
                            ],
                            for (final (index, block) in _selected.blocks.indexed) ...[
                              if (index > 0) SizedBox(height: rem(Space.xxxl)),
                              SettingsBlockView(scope: _selected.scope, block: block),
                            ],
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  void _select(SettingsPage page) => setState(() => _selected = page);
}

class _NavSection extends StatelessWidget {
  const _NavSection({required this.title, required this.pages, required this.selected, required this.onSelect});

  final String title;
  final List<SettingsPage> pages;
  final SettingsPage selected;
  final ValueChanged<SettingsPage> onSelect;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(rem(Space.xl), 0, rem(Space.xl), rem(Space.sm)),
          child: SectionLabel(title),
        ),
        for (final page in pages)
          _NavItem(page: page, active: page.id == selected.id, onTap: () => onSelect(page)),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.page, required this.active, required this.onTap});

  final SettingsPage page;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final icon = _pageIcons[page.id];
    return Padding(
      padding: EdgeInsets.fromLTRB(rem(Space.md), 0, rem(Space.md), rem(Space.xxs)),
      child: HoverBuilder(
        onTap: onTap,
        builder: (context, hovering) => AnimatedContainer(
          duration: Motion.fast,
          margin: EdgeInsets.only(left: page.isSubpage ? rem(Space.xl) : 0),
          padding: EdgeInsets.symmetric(horizontal: rem(Space.md), vertical: rem(Space.sm + 1)),
          decoration: BoxDecoration(
            color: active
                ? AppColors.brand.withValues(alpha: 0.16)
                : (hovering ? AppColors.surfaceHover : Colors.transparent),
            borderRadius: BorderRadius.circular(rem(Radii.sm + 1)),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: rem(16), color: active ? AppColors.brandAlt : AppColors.textSecondary),
                SizedBox(width: rem(Space.sm + 2)),
              ] else
                SizedBox(width: rem(Space.xs + 2)),
              Expanded(
                child: Text(
                  page.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
