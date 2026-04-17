import 'package:flutter/material.dart';

/// Paleta de Leyer8 — "The Serene Sentinel"
///
/// La seguridad se transmite a través de la estabilidad del Navy y la pureza
/// del Blanco. Evitamos contrastes agresivos. La estructura visual se define
/// por jerarquía de capas tonales, no por bordes.
class AppColors {
  AppColors._();

  // ============================================================
  // Brand / Primary
  // ============================================================

  /// Navy profundo. Color ancla de la marca.
  /// Usado en textos de alta jerarquía y base del gradiente primario.
  static const Color primary = Color(0xFF031632);

  /// Navy medio. Par del gradiente primario (135°).
  static const Color primaryContainer = Color(0xFF1A2B48);

  /// Texto sobre superficies primary/primaryContainer.
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ============================================================
  // Secondary (Verde de éxito — "Protección Activa")
  // ============================================================

  /// Verde calmado para estados de seguridad y confirmación.
  /// Nunca alarma, siempre tranquiliza.
  static const Color secondary = Color(0xFF2E7D5B);

  /// Verde suave para fondos de estado "protegido".
  static const Color secondaryContainer = Color(0xFFDFF5E8);

  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF0A3D26);

  // ============================================================
  // Surfaces — Jerarquía por capas tonales
  // ============================================================

  /// Fondo base de la app. Casi blanco, no puro.
  static const Color surface = Color(0xFFF5F6F8);

  /// Capa de sección. Sobre el surface base.
  static const Color surfaceContainerLow = Color(0xFFEEF0F3);

  /// Capa neutral (por defecto de tarjetas medias).
  static const Color surfaceContainer = Color(0xFFE6E9ED);

  /// Capa alta — inputs en reposo.
  static const Color surfaceContainerHigh = Color(0xFFDDE1E7);

  /// Capa más alta — énfasis sin color.
  static const Color surfaceContainerHighest = Color(0xFFD4D9E0);

  /// Blanco puro — reservado para tarjetas flotantes que captan atención.
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  /// Texto principal sobre superficies claras.
  static const Color onSurface = Color(0xFF031632);

  /// Texto secundario / labels.
  static const Color onSurfaceVariant = Color(0xFF5A6577);

  // ============================================================
  // Errores / Alertas
  // ============================================================
  // Se usan con moderación. Los mensajes de la app deben reforzar la paz
  // mental, no alarmar.

  /// Rojo editorial — para alertas de bloqueo e intentos sospechosos.
  static const Color error = Color(0xFFB3261E);

  /// Fondo suave de alerta.
  static const Color errorContainer = Color(0xFFFCE4E4);

  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF5C0F0A);

  // ============================================================
  // Outlines (uso restringido)
  // ============================================================

  /// Borde fantasma — solo si accesibilidad lo exige. Usar al 15% opacidad.
  static const Color outlineVariant = Color(0xFFBCC2CC);

  // ============================================================
  // Gradientes
  // ============================================================

  /// Gradiente primario para CTAs principales. Ángulo 135°.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );
}