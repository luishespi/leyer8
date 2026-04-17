import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Sombras de Leyer8.
///
/// Profundidad atmosférica, nunca estructural. Prohibidas las sombras negras
/// duras. Cuando un elemento necesita flotar, usa un tinte del color de la
/// marca con blur generoso y opacidad muy baja.
class AppShadows {
  AppShadows._();

  /// Sin elevación — default.
  static const List<BoxShadow> none = [];

  /// Elevación sutil — tarjetas que flotan ligeramente sobre el fondo.
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.04),
      blurRadius: 24,
      offset: const Offset(0, 4),
    ),
  ];

  /// Elevación media — tarjetas de acción principal (botón de pánico,
  /// tarjeta de estado).
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.06),
      blurRadius: 40,
      offset: const Offset(0, 8),
    ),
  ];

  /// Elevación alta — modales, menús flotantes (glassmorphism).
  static List<BoxShadow> get high => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.08),
      blurRadius: 56,
      offset: const Offset(0, 16),
    ),
  ];
}