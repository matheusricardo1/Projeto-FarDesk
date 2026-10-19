import 'package:flutter/material.dart';

import '../domain/launch_target.dart';

/// Mapeamento do domínio pra linguagem visual — mesmo padrão usado em
/// `device_presentation.dart`.
extension LaunchTargetPresentation on LaunchTarget {
  String get label => switch (this) {
        LaunchTarget.desktop => 'Área de trabalho',
        LaunchTarget.steam => 'Steam',
        LaunchTarget.hydra => 'Hydra Launcher',
      };

  String get description => switch (this) {
        LaunchTarget.desktop => 'Acesso completo ao desktop remoto.',
        LaunchTarget.steam => 'Abre direto na sua biblioteca Steam.',
        LaunchTarget.hydra => 'Abre direto na sua biblioteca do Hydra Launcher.',
      };

  IconData get icon => switch (this) {
        LaunchTarget.desktop => Icons.desktop_windows_rounded,
        LaunchTarget.steam => Icons.videogame_asset_rounded,
        LaunchTarget.hydra => Icons.bolt_rounded,
      };
}
