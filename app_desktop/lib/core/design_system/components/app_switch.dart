import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.onBrand,
      activeTrackColor: AppColors.brand,
      inactiveThumbColor: AppColors.textMuted,
      inactiveTrackColor: AppColors.surfaceRaised,
    );
  }
}
