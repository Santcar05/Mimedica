import 'dart:typed_data';

import 'modelos.dart';

/// Error que la interfaz puede mostrar tal cual.
class Fallo implements Exception {
  const Fallo(this.mensaje, {this.sinRed = false, this.sesionVencida = false});

  final String mensaje;
  final bool sinRed;
  final bool sesionVencida;

  @override
  String toString() => mensaje;
}

/// Todo lo que el hogar guarda. La app solo conoce esta interfaz; detrás
/// puede haber Supabase o el almacenamiento del teléfono.
abstract interface class Repositorio {
  Future<Perfil?> perfil();
  Future<void> guardarPerfil(Perfil perfil);

  Future<List<Persona>> personas();
  Future<void> guardarPersona(Persona persona);

  Future<List<Tratamiento>> tratamientos();
  Future<void> guardarTratamiento(Tratamiento tratamiento);
  Future<void> eliminarTratamiento(String id);

  Future<List<Ciclo>> ciclos();
  Future<void> guardarCiclo(Ciclo ciclo);
  Future<List<Opcion>> opciones();

  Future<List<Pendiente>> pendientes();
  Future<void> guardarPendiente(Pendiente pendiente);

  /// Guarda la foto de la fórmula y devuelve su ruta.
  Future<String> subirFormula(Uint8List bytes);
  Future<Uint8List?> descargarFormula(String ruta);

  /// Marca de tiempo del embudo (p. ej. `plan_visto`).
  Future<void> registrarEvento(String nombre, [Json datos = const {}]);

  /// Borra todos los datos del hogar y la cuenta.
  Future<void> eliminarCuenta();
}

/// Ingreso sin contraseña con un código de seis dígitos al correo.
abstract interface class Acceso {
  bool get activa;
  String? get correo;
  Stream<bool> get cambios;

  Future<void> pedirCodigo(String correo);
  Future<void> verificar(String correo, String codigo);
  Future<void> cerrar();
}
