/// Llaves que llegan al compilar con `--dart-define-from-file=env.json`.
abstract final class Entorno {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Correo al que escriben los usuarios que piden ayuda. Opcional.
  static const soporteCorreo = String.fromEnvironment('SOPORTE_CORREO');

  /// Sin llaves la app guarda todo en el teléfono y el ingreso es de prueba.
  static bool get conServidor =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
