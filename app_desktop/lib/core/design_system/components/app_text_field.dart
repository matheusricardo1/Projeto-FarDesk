import 'package:flutter/material.dart';

import '../responsive.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.initialValue = '',
    this.label,
    this.hint,
    this.prefixIcon,
    this.textAlign = TextAlign.start,
    this.fillColor = AppColors.surfaceRaised,
    this.onChanged,
    this.obscureText = false,
  });

  final String initialValue;

  /// Texto fixo acima do campo — ao contrário do [hint], não desaparece
  /// quando a pessoa digita. Use pra campos onde isso importa (ex: formulário
  /// com mais de um campo, como o diálogo de credenciais do Tailscale).
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final TextAlign textAlign;
  final Color fillColor;
  final ValueChanged<String>? onChanged;

  /// Esconde o valor digitado (com um ícone pra revelar temporariamente) —
  /// pra credenciais (senhas, client secrets) que não deveriam ficar
  /// visíveis em texto puro na tela.
  final bool obscureText;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final _controller = TextEditingController(text: widget.initialValue);
  bool _revealed = false;

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

    final field = TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textAlign: widget.textAlign,
      textAlignVertical: TextAlignVertical.center,
      obscureText: widget.obscureText && !_revealed,
      style: text.bodySmall,
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        hintStyle: text.bodySmall.copyWith(color: AppColors.textMuted),
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon, size: rem(18), color: AppColors.textMuted),
        prefixIconConstraints: BoxConstraints(minWidth: rem(40), minHeight: rem(18)),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(_revealed ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: rem(18)),
                color: AppColors.textMuted,
                onPressed: () => setState(() => _revealed = !_revealed),
              )
            : null,
        // isDense + padding vertical explícito: sem isso o TextField reserva
        // altura extra e corta texto/cursor quando fica numa linha compacta.
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

    final label = widget.label;
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        SizedBox(height: rem(Space.xs)),
        field,
      ],
    );
  }
}
