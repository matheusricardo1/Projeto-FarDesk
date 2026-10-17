import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/device.dart';

/// Mapeamento do domínio pra linguagem visual — mantém o modelo `Device`
/// livre de cores, ícones e textos de UI.
extension DeviceStatusPresentation on DeviceStatus {
  String get label => switch (this) {
        DeviceStatus.online => 'Online',
        DeviceStatus.inUse => 'Em uso',
        DeviceStatus.hibernating => 'Hibernando',
        DeviceStatus.offline => 'Offline',
      };

  Color get color => switch (this) {
        DeviceStatus.online => AppColors.success,
        DeviceStatus.inUse => AppColors.warning,
        DeviceStatus.hibernating => AppColors.neutral,
        DeviceStatus.offline => AppColors.inactive,
      };
}

extension DevicePlatformPresentation on DevicePlatform {
  IconData get icon => switch (this) {
        DevicePlatform.windows => Icons.window_outlined,
        DevicePlatform.linux => Icons.terminal,
        DevicePlatform.macos => Icons.laptop_mac,
        DevicePlatform.ps5 => Icons.sports_esports,
        DevicePlatform.android => Icons.phone_android,
        DevicePlatform.ios => Icons.phone_iphone,
        DevicePlatform.web => Icons.public,
      };
}

extension DevicePresentation on Device {
  String get subtitle {
    if (isCurrentDevice) return 'Este dispositivo';
    return switch (status) {
      DeviceStatus.online => 'Pronto pra conectar',
      DeviceStatus.inUse => 'Em uso por outra sessão',
      DeviceStatus.hibernating => 'Hibernando — toque pra acordar',
      DeviceStatus.offline => 'Offline',
    };
  }
}
