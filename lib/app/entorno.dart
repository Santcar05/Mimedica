/// Llaves que llegan al compilar con `--dart-define-from-file=env.json`.
abstract final class Entorno {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Solo el dominio del proyecto. Si se pegó la URL con un tramo de más
  /// (p. ej. `/rest/v1/`), se descarta para no romper las rutas de ingreso.
  static String get urlServidor {
    final limpia = supabaseUrl.trim();
    final uri = Uri.tryParse(limpia);
    if (uri == null || !uri.hasAuthority) return limpia;
    return '${uri.scheme}://${uri.authority}';
  }

  /// Correo al que escriben los usuarios que piden ayuda. Opcional.
  static const soporteCorreo = String.fromEnvironment('SOPORTE_CORREO');

  /// Sin llaves la app guarda todo en el teléfono y el ingreso es de prueba.
  static bool get conServidor =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
