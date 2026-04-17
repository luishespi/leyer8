import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Prompt de navegación secundario en pantallas de auth.
///
/// Ej.: "¿No tienes cuenta? Regístrate" o "¿Ya tienes cuenta? Inicia sesión".
/// Respeta el tono editorial — el texto "líder" en onSurfaceVariant y el
/// link en primary con peso semibold.
class AuthLink extends StatelessWidget {
  final String leadingText;
  final String actionText;
  final VoidCallback? onPressed;

  const AuthLink({
    super.key,
    required this.leadingText,
    required this.actionText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(leadingText, style: AppTypography.bodyMedium),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionText,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}