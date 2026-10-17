import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/setting.dart';
import 'settings_view_model.dart';

/// Renderiza qualquer bloco do schema. É o único lugar que sabe transformar
/// uma definição de configuração em widget.
class SettingsBlockView extends StatelessWidget {
  const SettingsBlockView({super.key, required this.scope, required this.block});

  final SettingsScope scope;
  final SettingsBlock block;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      final SettingsGroup group => _GroupView(scope: scope, group: group),
      final SettingsNotice notice => InlineNotice(text: notice.text),
      final SettingsTable table => AppTable(headers: table.headers, rows: table.rows),
      final SettingsPlaceholder placeholder => EmptyState(icon: Icons.hourglass_empty_rounded, message: placeholder.text),
    };
  }
}

class _GroupView extends StatelessWidget {
  const _GroupView({required this.scope, required this.group});

  final SettingsScope scope;
  final SettingsGroup group;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.title.toUpperCase(), style: text.sectionTitle),
        if (group.subtitle != null) ...[
          SizedBox(height: rem(Space.xs)),
          Text(group.subtitle!, style: text.caption.copyWith(fontSize: rem(12.5))),
        ],
        SizedBox(height: rem(Space.sm)),
        AppCard(
          padding: EdgeInsets.zero,
          radius: Radii.lg,
          child: Column(
            children: [
              for (final (index, setting) in group.items.indexed)
                _SettingRow(scope: scope, setting: setting, isLast: index == group.items.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.scope, required this.setting, required this.isLast});

  final SettingsScope scope;
  final SettingDefinition setting;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: rem(Space.xl), vertical: rem(Space.lg)),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(setting.label, style: text.bodyStrong),
                if (setting.description != null) ...[
                  SizedBox(height: rem(Space.xs)),
                  Text(setting.description!, style: text.caption),
                ],
              ],
            ),
          ),
          SizedBox(width: rem(Space.xxl)),
          SizedBox(
            width: rem(240),
            child: Align(alignment: Alignment.centerRight, child: _SettingControl(scope: scope, setting: setting)),
          ),
        ],
      ),
    );
  }
}

class _SettingControl extends StatelessWidget {
  const _SettingControl({required this.scope, required this.setting});

  final SettingsScope scope;
  final SettingDefinition setting;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    return switch (setting) {
      final ToggleSetting s => AppSwitch(
          value: viewModel.valueOf(scope, s),
          onChanged: (value) => viewModel.update(scope, s, value),
        ),
      final ChoiceSetting s => AppDropdown<String>(
          value: viewModel.valueOf(scope, s),
          options: [for (final option in s.options) AppDropdownOption(option.value, option.label)],
          onChanged: (value) => viewModel.update(scope, s, value),
        ),
      final TextSetting s => AppTextField(
          initialValue: viewModel.valueOf(scope, s),
          hint: s.hint,
          textAlign: TextAlign.right,
          onChanged: (value) => viewModel.update(scope, s, value),
        ),
      final ReadOnlySetting s => _ReadOnlyValue(value: viewModel.valueOf(scope, s), kind: s.kind),
      final ActionSetting s => AppButton(
          label: s.actionLabel,
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.small,
          onPressed: () {},
        ),
    };
  }
}

class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.value, required this.kind});

  final String value;
  final ReadOnlyKind kind;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: rem(Space.sm + 2), vertical: rem(Space.sm)),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(rem(Radii.md)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.mono)),
          SizedBox(width: rem(Space.sm)),
          Icon(
            kind == ReadOnlyKind.display ? Icons.monitor_outlined : Icons.folder_open_outlined,
            size: rem(15),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
