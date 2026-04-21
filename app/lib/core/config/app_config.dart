/// Configuración global de la app.
///
/// Las URLs apuntan al backend desplegado en Railway. En desarrollo
/// se puede apuntar a localhost cambiando el valor aquí.
class AppConfig {
  AppConfig._();

  /// URL base del backend. Sin trailing slash.
  static const String backendUrl =
      'https://leyer8-production.up.railway.app';

  /// Timeout para llamadas HTTP al backend.
  static const Duration httpTimeout = Duration(seconds: 20);
}