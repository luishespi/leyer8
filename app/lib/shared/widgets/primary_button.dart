import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';

/// Botón primario de Leyer8.
///
/// Usa el gradiente 135° primary → primaryContainer. En estado presionado
/// reduce la escala al 98% para simular profundidad física (ver DESIGN.md §5).
///
/// Uso:
/// ```dart
/// PrimaryButton(
///   label: 'Comenzar el Paso 1',
///   onPressed: () => ...,
///   trailing: Icon(Icons.arrow_forward),
/// )
/// ```
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final bool isLoading;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.98 : 1.0;
    final opacity = _isEnabled ? 1.0 : 0.5;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          onTapDown: _isEnabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _isEnabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _isEnabled ? () => setState(() => _pressed = false) : null,
          onTap: _isEnabled ? widget.onPressed : null,
          child: Container(
            width: widget.fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppRadii.radiusXl,
              boxShadow: AppShadows.medium,
            ),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const SizedBox(
        height: 24,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
            ),
          ),
        ),
      );
    }

    final labelWidget = Text(
      widget.label,
      style: AppTypography.labelLarge,
      textAlign: TextAlign.center,
    );

    if (widget.leading == null && widget.trailing == null) {
      return labelWidget;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.leading != null) ...[
          IconTheme(
            data: const IconThemeData(color: AppColors.onPrimary, size: 20),
            child: widget.leading!,
          ),
          const SizedBox(width: 12),
        ],
        Flexible(child: labelWidget),
        if (widget.trailing != null) ...[
          const SizedBox(width: 12),
          IconTheme(
            data: const IconThemeData(color: AppColors.onPrimary, size: 20),
            child: widget.trailing!,
          ),
        ],
      ],
    );
  }
}