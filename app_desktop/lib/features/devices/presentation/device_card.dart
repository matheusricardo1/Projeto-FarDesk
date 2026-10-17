import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/device.dart';
import 'device_presentation.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.pending,
    required this.onConnect,
    required this.onWake,
  });

  final Device device;
  final bool pending;
  final VoidCallback onConnect;
  final VoidCallback onWake;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    final online = device.status == DeviceStatus.online;

    return HoverBuilder(
      builder: (context, hovering) => AnimatedScale(
        scale: hovering ? 1.018 : 1.0,
        duration: Motion.medium,
        curve: Motion.curve,
        child: AppCard(
          highlighted: online,
          hovering: hovering,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlatformTile(platform: device.platform, highlighted: online),
                  const Spacer(),
                  StatusBadge(label: device.status.label, color: device.status.color, pulse: online),
                ],
              ),
              const Spacer(),
              Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.headline),
              SizedBox(height: rem(Space.xxs)),
              Text(
                device.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: online ? AppColors.brandAlt : AppColors.textMuted,
                ),
              ),
              SizedBox(height: rem(Space.lg)),
              _buildAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction() {
    if (device.isCurrentDevice) {
      return const AppButton(label: 'Este dispositivo', variant: AppButtonVariant.muted, expand: true);
    }
    return switch (device.status) {
      DeviceStatus.online => AppButton(label: 'Conectar', expand: true, loading: pending, onPressed: onConnect),
      DeviceStatus.inUse => const AppButton(label: 'Em uso por outra sessão', variant: AppButtonVariant.muted, expand: true),
      DeviceStatus.hibernating => AppButton(
          label: 'Acordar e conectar',
          variant: AppButtonVariant.secondary,
          expand: true,
          loading: pending,
          onPressed: onWake,
        ),
      DeviceStatus.offline => const AppButton(label: 'Offline', variant: AppButtonVariant.muted, expand: true),
    };
  }
}

class _PlatformTile extends StatelessWidget {
  const _PlatformTile({required this.platform, required this.highlighted});

  final DevicePlatform platform;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return Container(
      width: rem(46),
      height: rem(46),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.onBrand.withValues(alpha: 0.12) : AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(rem(Radii.lg)),
      ),
      child: Icon(platform.icon, size: rem(22), color: AppColors.textPrimary),
    );
  }
}
