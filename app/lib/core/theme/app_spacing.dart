/// Sistema de espaciado de Leyer8.
///
/// Priorizamos el aire sobre la densidad. El espacio en blanco es una
/// herramienta de jerarquía — nunca "espacio vacío". Todos los valores son
/// múltiplos de 4px. Mínimo 24px entre bloques de contenido.
class AppSpacing {
  AppSpacing._();

  /// 4px — espacio mínimo (entre icono y label adyacente).
  static const double xs = 4.0;

  /// 8px — gap interno de chips o badges.
  static const double sm = 8.0;

  /// 12px — separación entre elementos relacionados.
  static const double md = 12.0;

  /// 16px — padding interno estándar de tarjetas.
  static const double lg = 16.0;

  /// 24px — mínimo entre bloques. Padding horizontal de pantallas.
  static const double xl = 24.0;

  /// 32px — separación entre secciones.
  static const double xxl = 32.0;

  /// 48px — respiro generoso en layouts editoriales.
  static const double xxxl = 48.0;

  /// 64px — separación entre secciones mayores (encabezado vs contenido).
  static const double huge = 64.0;
}