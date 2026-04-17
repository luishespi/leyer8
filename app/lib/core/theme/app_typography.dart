import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tipografía de Leyer8.
///
/// Combinamos Plus Jakarta Sans (display/headlines — autoridad editorial)
/// con Inter (body/labels — voz técnica clara). Interlineado 150% para
/// facilitar la lectura en movimiento. Español MX es ~20% más largo que
/// inglés, por lo que los contenedores deben permitir saltos de línea en
/// lugar de truncar.
class AppTypography {
  AppTypography._();

  static const String _display = 'PlusJakartaSans';
  static const String _body = 'Inter';

  // ============================================================
  // Display — Pantallas de calma, afirmaciones ("Hola, Familia")
  // ============================================================

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _display,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppColors.onSurface,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _display,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
    color: AppColors.onSurface,
  );

  // ============================================================
  // Headline — Títulos de sección
  // ============================================================

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _display,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _display,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _display,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.onSurface,
  );

  // ============================================================
  // Title — Encabezados de tarjeta, títulos de componente
  // ============================================================

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _body,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _body,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.1,
    color: AppColors.onSurfaceVariant,
  );

  // ============================================================
  // Body — Texto corrido
  // ============================================================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _body,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurfaceVariant,
  );

  // ============================================================
  // Label — Botones, badges, chips
  // ============================================================

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _body,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.1,
    color: AppColors.onPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.1,
    color: AppColors.onSurface,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _body,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.8,
    color: AppColors.onSurfaceVariant,
  );
}