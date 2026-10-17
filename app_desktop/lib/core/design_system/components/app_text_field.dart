import 'package:flutter/material.dart';

import '../responsive.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.initialValue = '',
    this.hint,
    this.prefixIcon,
    this.textAlign = TextAlign.start,
    this.fillColor = AppColors.surfaceRaised,
    this.onChanged,
  });

  final String initialValue;
  final String? hint;
  final IconData? prefixIcon;
  final TextAlign textAlign;
  final Color fillColor;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(rem(Radii.md)),
          borderSide: BorderSide(color: color),
        );

    // isDense + padding vertical explícito: sem isso o TextField reserva
    // altura extra e corta texto/cursor quando fica numa linha compacta.
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textAlign: widget.textAlign,
      textAlignVertical: TextAlignVertical.center,
      style: text.bodySmall,
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        hintStyle: text.bodySmall.copyWith(color: AppColors.textMuted),
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon, size: rem(18), color: AppColors.textMuted),
        prefixIconConstraints: BoxConstraints(minWidth: rem(40), minHeight: rem(18)),
        filled: true,
        fillColor: widget.fillColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: widget.prefixIcon == null ? rem(Space.md) : 0,
          vertical: rem(10),
        ),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.brand),
      ),
    );
  }
}
