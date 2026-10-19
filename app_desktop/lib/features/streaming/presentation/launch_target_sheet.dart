import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../devices/domain/device.dart';
import '../domain/launch_target.dart';
import 'launch_target_presentation.dart';

/// Pergunta onde abrir o stream nesse dispositivo. [availableTargets] já vem
/// filtrado por quem chamou (Steam/Hydra só entram se a integração estiver
/// conectada) — esse widget só lista e devolve a escolha.
Future<LaunchTarget?> showLaunchTargetSheet(
  BuildContext context, {
  required Device device,
  required List<LaunchTarget> availableTargets,
}) {
  return showDialog<LaunchTarget>(
    context: context,
    barrierColor: AppColors.shadow.withValues(alpha: 0.6),
    builder: (context) => _LaunchTargetDialog(device: device, targets: availableTargets),
  );
}

class _LaunchTargetDialog extends StatelessWidget {
  const _LaunchTargetDialog({required this.device, required this.targets});

  final Device device;
  final List<LaunchTarget> targets;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: rem(380)),
        child: AppCard(
          radius: Radii.xl,
          padding: EdgeInsets.all(rem(Space.xl)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Abrir ${device.name} em', style: text.headline),
              SizedBox(height: rem(Space.xs)),
              Text('Escolha onde conectar nesse dispositivo.', style: text.caption),
              SizedBox(height: rem(Space.lg)),
              for (final target in targets)
                Padding(
                  padding: EdgeInsets.only(bottom: rem(Space.sm)),
                  child: _TargetOption(target: target, onTap: () => Navigator.of(context).pop(target)),
                ),
              SizedBox(height: rem(Space.xxs)),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  label: 'Cancelar',
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.small,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetOption extends StatelessWidget {
  const _TargetOption({required this.target, required this.onTap});

  final LaunchTarget target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;

    return HoverBuilder(
      onTap: onTap,
      builder: (context, hovering) => AnimatedContainer(
        duration: Motion.fast,
        padding: EdgeInsets.all(rem(Space.md)),
        decoration: BoxDecoration(
          color: hovering ? AppColors.surfaceHover : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(rem(Radii.md)),
          border: Border.all(color: hovering ? AppColors.brand.withValues(alpha: 0.5) : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: rem(38),
              height: rem(38),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(rem(Radii.sm + 2))),
              child: Icon(target.icon, size: rem(18), color: AppColors.textPrimary),
            ),
            SizedBox(width: rem(Space.md)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(target.label, style: text.bodyStrong),
                  SizedBox(height: rem(2)),
                  Text(target.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.caption),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: rem(18), color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
