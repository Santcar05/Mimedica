import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'identificador.dart';
import 'modelos.dart';
import 'repositorio.dart';

const _claveDatos = 'mimedica.datos';
const _claveCorreo = 'mimedica.correo';
const _claveFoto = 'mimedica.foto.';

/// Guarda el hogar en el teléfono. Es el modo de trabajo cuando la app se
/// compila sin las llaves de Supabase.
class RepositorioLocal implements Repositorio {
  RepositorioLocal(this._prefs);
  final SharedPreferences _prefs;

  Json get _datos {
    final crudo = _prefs.getString(_claveDatos);
    return crudo == null ? <String, dynamic>{} : jsonDecode(crudo) as Json;
  }

  Future<void> _escribir(Json datos) =>
      _prefs.setString(_claveDatos, jsonEncode(datos));

  List<Json> _lista(String tabla) =>
      ((_datos[tabla] as List?) ?? const []).cast<Json>();

  Future<void> _upsert(String tabla, Json fila) async {
    final datos = _datos;
    final filas = ((datos[tabla] as List?) ?? []).cast<Json>().toList();
    final i = filas.indexWhere((f) => f['id'] == fila['id']);
    if (i < 0) {
      filas.add(fila);
    } else {
      filas[i] = fila;
    }
    datos[tabla] = filas;
    await _escribir(datos);
  }

  @override
  Future<Perfil?> perfil() async {
    final j = _datos['perfil'] as Json?;
    return j == null ? null : Perfil.deJson(j);
  }

  @override
  Future<void> guardarPerfil(Perfil perfil) =>
      _escribir(_datos..['perfil'] = perfil.aJson());

  @override
  Future<List<Persona>> personas() async =>
      _lista('personas').map(Persona.deJson).toList();

  @override
  Future<void> guardarPersona(Persona persona) =>
      _upsert('personas', persona.aJson());

  @override
  Future<List<Tratamiento>> tratamientos() async =>
      _lista('tratamientos').map(Tratamiento.deJson).toList();

  @override
  Future<void> guardarTratamiento(Tratamiento tratamiento) =>
      _upsert('tratamientos', tratamiento.aJson());

  @override
  Future<void> eliminarTratamiento(String id) async {
    final datos = _datos;
    final ciclos = _lista('ciclos')
        .where((c) => c['tratamiento_id'] == id)
        .map((c) => c['id'])
        .toSet();
    datos['tratamientos'] = _lista('tratamientos')
        .where((t) => t['id'] != id)
        .toList();
    datos['ciclos'] = _lista('ciclos')
        .where((c) => c['tratamiento_id'] != id)
        .toList();
    datos['opciones'] = _lista('opciones')
        .where((o) => !ciclos.contains(o['ciclo_id']))
        .toList();
    datos['pendientes'] = _lista('pendientes')
        .where((p) => p['tratamiento_id'] != id)
        .toList();
    await _escribir(datos);
  }

  @override
  Future<List<Ciclo>> ciclos() async =>
      _lista('ciclos').map(Ciclo.deJson).toList();

  @override
  Future<void> guardarCiclo(Ciclo ciclo) => _upsert('ciclos', ciclo.aJson());

  @override
  Future<List<Opcion>> opciones() async =>
      _lista('opciones').map(Opcion.deJson).toList();

  @override
  Future<List<Pendiente>> pendientes() async =>
      _lista('pendientes').map(Pendiente.deJson).toList();

  @override
  Future<void> guardarPendiente(Pendiente pendiente) =>
      _upsert('pendientes', pendiente.aJson());

  @override
  Future<String> subirFormula(Uint8List bytes) async {
    final ruta = nuevoId();
    await _prefs.setString('$_claveFoto$ruta', base64Encode(bytes));
    return ruta;
  }

  @override
  Future<Uint8List?> descargarFormula(String ruta) async {
    final crudo = _prefs.getString('$_claveFoto$ruta');
    return crudo == null ? null : base64Decode(crudo);
  }

  @override
  Future<void> registrarEvento(String nombre, [Json datos = const {}]) =>
      _upsert('eventos', {
        'id': nuevoId(),
        'nombre': nombre,
        'datos': datos,
        'ocurrio_el': DateTime.now().toUtc().toIso8601String(),
      });

  @override
  Future<void> eliminarCuenta() async {
    final claves = _prefs.getKeys().where((k) => k.startsWith('mimedica.'));
    for (final clave in claves.toList()) {
      await _prefs.remove(clave);
    }
  }
}

/// Ingreso de demostración: cualquier correo entra con el código fijo.
class AccesoLocal implements Acceso {
  AccesoLocal(this._prefs);

  static const codigoDemo = '123456';

  final SharedPreferences _prefs;
  final _cambios = StreamController<bool>.broadcast();

  @override
  bool get activa => correo != null;

  @override
  String? get correo => _prefs.getString(_claveCorreo);

  @override
  Stream<bool> get cambios => _cambios.stream;

  @override
  Future<void> pedirCodigo(String correo) async {}

  @override
  Future<void> verificar(String correo, String codigo) async {
    if (codigo != codigoDemo) {
      throw const Fallo(
        'Ese código no coincide. Revísalo o pide uno nuevo.',
      );
    }
    await _prefs.setString(_claveCorreo, correo);
    _cambios.add(true);
  }

  @override
  Future<void> cerrar() async {
    await _prefs.remove(_claveCorreo);
    _cambios.add(false);
  }
}
