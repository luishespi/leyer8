import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Campo de texto de Leyer8.
///
/// En reposo: fondo `surface_container_high`, sin bordes visibles.
/// En focus: fondo se aclara a `surface_lowest` + resplandor (glow) sutil en
/// `primary` al 10% opacidad. Nunca bordes duros de 1px.
///
/// El label aparece arriba del campo (no flotante), siguiendo el tono editorial.
class TextFieldSentinel extends StatefulWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final List<String>? autofillHints;
  final int? maxLength;

  const TextFieldSentinel({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autofillHints,
    this.maxLength,
  });

  @override
  State<TextFieldSentinel> createState() => _TextFieldSentinelState();
}

class _TextFieldSentinelState extends State<TextFieldSentinel> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: AppRadii.radiusLg,
            boxShadow: _focused && !hasError
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : const [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            validator: widget.validator,
            style: AppTypography.bodyLarge,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              errorText: hasError ? widget.errorText : null,
              counterText: '',
              fillColor: _focused
                  ? AppColors.surfaceContainerLowest
                  : AppColors.surfaceContainerHigh,
            ),
          ),
        ),
        if (widget.helperText != null && !hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Text(widget.helperText!, style: AppTypography.bodySmall),
          ),
        ],
      ],
    );
  }
}