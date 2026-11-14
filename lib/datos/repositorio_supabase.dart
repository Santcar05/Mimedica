import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'identificador.dart';
import 'modelos.dart';
import 'repositorio.dart';

const _cubeta = 'formulas';

Fallo _traducir(Object error) {
  if (error is Fallo) return error;
  if (error is AuthException) {
    final codigo = error.code ?? '';
    if (codigo == 'otp_expired' || codigo == 'invalid_credentials') {
      return const Fallo('Ese código no coincide o ya venció. Pide uno nuevo.');
    }
    if (codigo == 'over_email_send_rate_limit' ||
        codigo == 'over_request_rate_limit') {
      return const Fallo(
        'Pediste varios códigos seguidos. Espera un minuto y vuelve a intentar.',
      );
    }
    if (error.statusCode == '401' || codigo == 'session_not_found') {
      return const Fallo(
        'Tu sesión venció. Entra de nuevo con tu correo.',
        sesionVencida: true,
      );
    }
    if (error is AuthRetryableFetchException) {
      return const Fallo(_sinConexion, sinRed: true);
    }
    return const Fallo('No pudimos validar tu ingreso. Inténtalo de nuevo.');
  }
  if (error is PostgrestException && error.code == 'PGRST301') {
    return const Fallo(
      'Tu sesión venció. Entra de nuevo con tu correo.',
      sesionVencida: true,
    );
  }
  if (error.toString().contains('SocketException') ||
      error is TimeoutException ||
      error.toString().contains('ClientException')) {
    return const Fallo(_sinConexion, sinRed: true);
  }
  return const Fallo(
    'Algo falló de nuestro lado. Tus datos no se perdieron; inténtalo de nuevo.',
  );
}

const _sinConexion =
    'No hay conexión. Revisa el wifi o los datos y vuelve a intentar.';

Future<T> _protegido<T>(Future<T> Function() tarea) async {
  try {
    return await tarea().timeout(const Duration(seconds: 20));
  } catch (error) {
    throw _traducir(error);
  }
}

class RepositorioSupabase implements Repositorio {
  RepositorioSupabase(this._cliente);
  final SupabaseClient _cliente;

  String get _usuario {
    final id = _cliente.auth.currentUser?.id;
    if (id == null) {
      throw const Fallo(
        'Tu sesión venció. Entra de nuevo con tu correo.',
        sesionVencida: true,
      );
    }
    return id;
  }

  Future<List<T>> _leer<T>(String tabla, T Function(Json) crear) =>
      _protegido(() async {
        final filas = await _cliente.from(tabla).select();
        return filas.map(crear).toList();
      });

  Future<void> _guardar(String tabla, Json fila) =>
      _protegido(() => _cliente.from(tabla).upsert(fila));

  @override
  Future<Perfil?> perfil() => _protegido(() async {
    final fila = await _cliente
        .from('perfiles')
        .select()
        .eq('id', _usuario)
        .maybeSingle();
    return fila == null ? null : Perfil.deJson(fila);
  });

  @override
  Future<void> guardarPerfil(Perfil perfil) =>
      _guardar('perfiles', {...perfil.aJson(), 'id': _usuario});

  @override
  Future<List<Persona>> personas() => _leer('personas', Persona.deJson);

  @override
  Future<void> guardarPersona(Persona persona) =>
      _guardar('personas', persona.aJson());

  @override
  Future<List<Tratamiento>> tratamientos() =>
      _leer('tratamientos', Tratamiento.deJson);

  @override
  Future<void> guardarTratamiento(Tratamiento tratamiento) =>
      _guardar('tratamientos', tratamiento.aJson());

  @override
  Future<void> eliminarTratamiento(String id) =>
      _protegido(() => _cliente.from('tratamientos').delete().eq('id', id));

  @override
  Future<List<Ciclo>> ciclos() => _leer('ciclos', Ciclo.deJson);

  @override
  Future<void> guardarCiclo(Ciclo ciclo) => _guardar('ciclos', ciclo.aJson());

  @override
  Future<List<Opcion>> opciones() => _leer('opciones', Opcion.deJson);

  @override
  Future<List<Pendiente>> pendientes() => _leer('pendientes', Pendiente.deJson);

  @override
  Future<void> guardarPendiente(Pendiente pendiente) =>
      _guardar('pendientes', pendiente.aJson());

  @override
  Future<String> subirFormula(Uint8List bytes) => _protegido(() async {
    final ruta = '$_usuario/${nuevoId()}.jpg';
    await _cliente.storage
        .from(_cubeta)
        .uploadBinary(
          ruta,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return ruta;
  });

  @override
  Future<Uint8List?> descargarFormula(String ruta) =>
      _protegido(() => _cliente.storage.from(_cubeta).download(ruta));

  @override
  Future<void> registrarEvento(String nombre, [Json datos = const {}]) async {
    // La medición nunca debe interrumpir al usuario.
    try {
      await _cliente.from('eventos').insert({'nombre': nombre, 'datos': datos});
    } catch (_) {}
  }

  @override
  Future<void> eliminarCuenta() => _protegido(() async {
    final fotos = await _cliente.storage.from(_cubeta).list(path: _usuario);
    if (fotos.isNotEmpty) {
      await _cliente.storage.from(_cubeta).remove([
        for (final f in fotos) '$_usuario/${f.name}',
      ]);
    }
    await _cliente.rpc('eliminar_cuenta');
    await _cliente.auth.signOut(scope: SignOutScope.local);
  });
}

class AccesoSupabase implements Acceso {
  AccesoSupabase(this._cliente);
  final SupabaseClient _cliente;

  @override
  bool get activa => _cliente.auth.currentSession != null;

  @override
  String? get correo => _cliente.auth.currentUser?.email;

  @override
  Stream<bool> get cambios =>
      _cliente.auth.onAuthStateChange.map((e) => e.session != null).distinct();

  @override
  Future<void> pedirCodigo(String correo) =>
      _protegido(() => _cliente.auth.signInWithOtp(email: correo));

  @override
  Future<void> verificar(String correo, String codigo) => _protegido(
    () => _cliente.auth.verifyOTP(
      type: OtpType.email,
      email: correo,
      token: codigo,
    ),
  );

  @override
  Future<void> cerrar() => _protegido(() => _cliente.auth.signOut());
}
