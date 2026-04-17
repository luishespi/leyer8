import 'package:flutter/material.dart';

/// Sistema de radios de Leyer8.
///
/// La iconografía y componentes son redondeados, "soft-touch". Nunca angulares.
/// Las tarjetas y botones principales usan `xl` (24px) para transmitir
/// amabilidad táctil.
class AppRadii {
  AppRadii._();

  /// 4px — detalles mínimos (chips pequeños, badges).
  static const double sm = 4.0;

  /// 8px — inputs, elementos secundarios.
  static const double md = 8.0;

  /// 12px — tarjetas medias, botones secundarios.
  static const double lg = 12.0;

  /// 24px — tarjetas principales, botones primarios. Valor por defecto.
  static const double xl = 24.0;

  /// Totalmente redondeado — handles de sliders, avatares, badges circulares.
  static const double full = 999.0;

  // Helpers — BorderRadius listos para usar
  static BorderRadius get radiusSm => BorderRadius.circular(sm);
  static BorderRadius get radiusMd => BorderRadius.circular(md);
  static BorderRadius get radiusLg => BorderRadius.circular(lg);
  static BorderRadius get radiusXl => BorderRadius.circular(xl);
  static BorderRadius get radiusFull => BorderRadius.circular(full);
}