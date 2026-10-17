import 'package:flutter/material.dart';

import '../responsive.dart';
import '../tokens/colors.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';
import 'hover_builder.dart';

class AppDropdownOption<T> {
  const AppDropdownOption(this.value, this.label);
  final T value;
  final String label;
}

/// Seletor com menu próprio — o `DropdownButton` do Material abre um menu
/// genérico que destoa do resto do app. Ocupa toda a largura disponível.
class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({super.key, required this.value, required this.options, required this.onChanged});

  final T value;
  final List<AppDropdownOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final _triggerKey = GlobalKey();
  bool _open = false;

  String get _selectedLabel {
    for (final option in widget.options) {
      if (option.value == widget.value) return option.label;
    }
    return widget.options.isEmpty ? '' : widget.options.first.label;
  }

  Future<void> _openMenu() async {
    final rem = context.rem;
    final box = _triggerKey.currentContext!.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final width = box.size.width < rem(220) ? rem(220) : box.size.width;

    setState(() => _open = true);
    final selected = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy + box.size.height + rem(Space.xs + 2),
        overlay.size.width - topLeft.dx - box.size.width,
        0,
      ),
      color: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: AppColors.shadow.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(rem(Radii.md + 2)),
        side: const BorderSide(color: AppColors.border),
      ),
      constraints: BoxConstraints(minWidth: box.size.width, maxWidth: width),
      items: [
        for (final option in widget.options)
          PopupMenuItem<T>(
            value: option.value,
            height: rem(38),
            padding: EdgeInsets.zero,
            child: _MenuRow(label: option.label, selected: option.value == widget.value),
          ),
      ],
    );
    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && selected != widget.value) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return HoverBuilder(
      onTap: _openMenu,
      builder: (context, hovering) {
        final active = hovering || _open;
        return AnimatedContainer(
          key: _triggerKey,
          duration: Motion.fast,
          width: double.infinity,
          height: rem(36),
          padding: EdgeInsets.symmetric(horizontal: rem(Space.md)),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(rem(Radii.md)),
            border: Border.all(color: active ? AppColors.brand.withValues(alpha: 0.6) : AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(_selectedLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall),
              ),
              SizedBox(width: rem(Space.sm)),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: Motion.medium,
                child: Icon(
                  Icons.expand_more_rounded,
                  size: rem(18),
                  color: active ? AppColors.brandAlt : AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return HoverBuilder(
      builder: (context, hovering) => Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: rem(Space.md)),
        color: hovering
            ? AppColors.surfaceHover
            : (selected ? AppColors.brand.withValues(alpha: 0.12) : Colors.transparent),
        child: Row(
          children: [
            SizedBox(
              width: rem(18),
              child: selected ? Icon(Icons.check_rounded, size: rem(15), color: AppColors.brandAlt) : null,
            ),
            SizedBox(width: rem(Space.xs + 2)),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodySmall.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
