import 'package:flutter/painting.dart';

import '../../../core/design_system/design_system.dart';

const _avatarPalette = <List<Color>>[
  [AppColors.brand, AppColors.brandAlt],
  [Color(0xFFE0574A), Color(0xFFF5A623)],
  [Color(0xFF2A3F6B), Color(0xFF5C8CD6)],
  [Color(0xFF1F7A5E), AppColors.success],
];

/// Gradiente do avatar pela posição da conta na lista — a primeira conta
/// sempre usa as cores da marca.
List<Color> avatarGradientAt(int index) => _avatarPalette[index < 0 ? 0 : index % _avatarPalette.length];
