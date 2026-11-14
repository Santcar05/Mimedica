import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'calculo_agotamiento.dart';
import 'identificador.dart';
import 'modelos.dart';
import 'repositorio.dart';

final repositorioProvider = Provider<Repositorio>(
  (ref) => throw UnimplementedError('Se define al arrancar la app'),
);

final accesoProvider = Provider<Acceso>(
  (ref) => throw UnimplementedError('Se define al arrancar la app'),
);

/// El día de hoy, sin hora. Separado para poder fijarlo en las pruebas.
final hoyProvider = Provider<DateTime>((ref) => soloDia(DateTime.now()));

class Sesion extends Notifier<bool> {
  @override
  bool build() {
    final acceso = ref.watch(accesoProvider);
    final escucha = acceso.cambios.listen((activa) => state = activa);
    ref.onDispose(escucha.cancel);
    return acceso.activa;
  }
}

final sesionProvider = NotifierProvider<Sesion, bool>(Sesion.new);

/// Fotografía completa de lo que el hogar tiene guardado.
class Hogar {
  const Hogar({
    this.perfil,
    this.personas = const [],
    this.tratamientos = const [],
    this.ciclos = const [],
    this.opciones = const [],
    this.pendientes = const [],
    this.cargado = true,
  });

  /// Falso solo en el estado que existe mientras no hay sesión: no son datos
  /// de verdad, y nadie debe decidir a qué pantalla ir a partir de ellos.
  final bool cargado;

  final Perfil? perfil;
  final List<Persona> personas;
  final List<Tratamiento> tratamientos;
  final List<Ciclo> ciclos;
  final List<Opcion> opciones;
  final List<Pendiente> pendientes;

  bool get activado => (perfil?.autorizo ?? false) && tratamientos.isNotEmpty;

  Persona? persona(String id) => personas.where((p) => p.id == id).firstOrNull;

  Tratamiento? tratamiento(String id) =>
      tratamientos.where((t) => t.id == id).firstOrNull;

  Ciclo? ciclo(String id) => ciclos.where((c) => c.id == id).firstOrNull;

  Ciclo? cicloEnCurso(String tratamientoId) => ciclos
      .where((c) => c.tratamientoId == tratamientoId && c.enCurso)
      .firstOrNull;

  /// Del más reciente al más antiguo.
  List<Ciclo> ciclosDe(String tratamientoId) =>
      ciclos.where((c) => c.tratamientoId == tratamientoId).toList()
        ..sort((a, b) => b.abiertoEl.compareTo(a.abiertoEl));

  List<Opcion> opcionesDe(String cicloId) =>
      opciones.where((o) => o.cicloId == cicloId).toList();

  Hogar con({
    Perfil? perfil,
    List<Persona>? personas,
    List<Tratamiento>? tratamientos,
    List<Ciclo>? ciclos,
    List<Pendiente>? pendientes,
  }) => Hogar(
    perfil: perfil ?? this.perfil,
    personas: personas ?? this.personas,
    tratamientos: tratamientos ?? this.tratamientos,
    ciclos: ciclos ?? this.ciclos,
    opciones: opciones,
    pendientes: pendientes ?? this.pendientes,
  );
}

List<T> _reemplazar<T>(List<T> lista, T nuevo, bool Function(T) esElMismo) {
  final i = lista.indexWhere(esElMismo);
  return i < 0 ? [...lista, nuevo] : ([...lista]..[i] = nuevo);
}

class HogarNotifier extends AsyncNotifier<Hogar> {
  Repositorio get _repo => ref.read(repositorioProvider);

  @override
  Future<Hogar> build() async {
    if (!ref.watch(sesionProvider)) return const Hogar(cargado: false);
    final repo = ref.watch(repositorioProvider);

    final perfil = await repo.perfil();
    if (perfil == null) return const Hogar();

    final (personas, tratamientos, ciclos, opciones, pendientes) = await (
      repo.personas(),
      repo.tratamientos(),
      repo.ciclos(),
      repo.opciones(),
      repo.pendientes(),
    ).wait;

    final hogar = Hogar(
      perfil: perfil,
      personas: personas,
      tratamientos: tratamientos,
      ciclos: ciclos,
      opciones: opciones,
      pendientes: pendientes,
    );
    return _abrirCiclos(hogar);
  }

  /// Abre el ciclo de cada tratamiento que ya entró en los diez días
  /// de gestión y todavía no tiene uno en curso.
  Future<Hogar> _abrirCiclos(Hogar hogar) async {
    final hoy = ref.read(hoyProvider);
    final nuevos = <Ciclo>[];
    for (final t in hogar.tratamientos) {
      if (t.pausado || hogar.cicloEnCurso(t.id) != null) continue;
      if (!proyectar(t, hoy).enVentana) continue;
      final ciclo = Ciclo(id: nuevoId(), tratamientoId: t.id, abiertoEl: hoy);
      await _repo.guardarCiclo(ciclo);
      nuevos.add(ciclo);
    }
    if (nuevos.isEmpty) return hogar;
    unawaited(_repo.registrarEvento('ciclo_abierto', {'n': nuevos.length}));
    return hogar.con(ciclos: [...hogar.ciclos, ...nuevos]);
  }

  Hogar get _actual => state.value ?? const Hogar();

  Future<void> recargar() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> guardarPerfil(Perfil perfil) async {
    await _repo.guardarPerfil(perfil);
    state = AsyncData(_actual.con(perfil: perfil));
  }

  Future<void> autorizar({required bool estadistica}) async {
    final perfil = _actual.perfil!.con(
      autorizoServicioEl: DateTime.now(),
      autorizaEstadistica: estadistica,
    );
    await guardarPerfil(perfil);
    unawaited(
      _repo.registrarEvento('autorizacion', {'estadistica': estadistica}),
    );
  }

  Future<void> cambiarEstadistica(bool valor) =>
      guardarPerfil(_actual.perfil!.con(autorizaEstadistica: valor));

  Future<void> revocarAutorizacion() =>
      guardarPerfil(_actual.perfil!.con(revocar: true));

  Future<void> guardarPersona(Persona persona) async {
    await _repo.guardarPersona(persona);
    state = AsyncData(
      _actual.con(
        personas: _reemplazar(
          _actual.personas,
          persona,
          (p) => p.id == persona.id,
        ),
      ),
    );
  }

  Future<String> subirFormula(Uint8List bytes) => _repo.subirFormula(bytes);

  Future<void> guardarTratamiento(Tratamiento tratamiento) async {
    final esNuevo = _actual.tratamiento(tratamiento.id) == null;
    await _repo.guardarTratamiento(tratamiento);
    final hogar = _actual.con(
      tratamientos: _reemplazar(
        _actual.tratamientos,
        tratamiento,
        (t) => t.id == tratamiento.id,
      ),
    );
    state = AsyncData(await _abrirCiclos(hogar));
    if (esNuevo) {
      unawaited(
        _repo.registrarEvento('plan_activado', {
          'tratamientos': hogar.tratamientos.length,
        }),
      );
    }
  }

  Future<void> eliminarTratamiento(String id) async {
    await _repo.eliminarTratamiento(id);
    final ciclos = _actual.ciclos.where((c) => c.tratamientoId != id).toList();
    state = AsyncData(
      Hogar(
        perfil: _actual.perfil,
        personas: _actual.personas,
        tratamientos: _actual.tratamientos.where((t) => t.id != id).toList(),
        ciclos: ciclos,
        opciones: _actual.opciones
            .where((o) => ciclos.any((c) => c.id == o.cicloId))
            .toList(),
        pendientes: _actual.pendientes
            .where((p) => p.tratamientoId != id)
            .toList(),
      ),
    );
  }

  /// Suma lo recibido a lo que quedaba ese día, recalcula la fecha y cierra
  /// el ciclo en curso (o deja uno cerrado como registro de la entrega).
  Future<void> registrarEntrega({
    required String tratamientoId,
    required OrigenEntrega origen,
    required double cantidad,
    required DateTime fecha,
    String? punto,
  }) async {
    final t = _actual.tratamiento(tratamientoId)!;
    final actualizado = t.con(
      enCasa: enCasaTrasEntrega(t, cantidad, fecha),
      contadoEl: fecha,
    );
    final base =
        _actual.cicloEnCurso(tratamientoId) ??
        Ciclo(id: nuevoId(), tratamientoId: tratamientoId, abiertoEl: fecha);
    final cerrado = base.cerrar(
      origen: origen,
      cantidad: cantidad,
      fecha: fecha,
      punto: punto,
    );

    await _repo.guardarTratamiento(actualizado);
    await _repo.guardarCiclo(cerrado);

    final hogar = _actual.con(
      tratamientos: _reemplazar(
        _actual.tratamientos,
        actualizado,
        (x) => x.id == t.id,
      ),
      ciclos: _reemplazar(_actual.ciclos, cerrado, (c) => c.id == cerrado.id),
    );
    state = AsyncData(await _abrirCiclos(hogar));
    unawaited(_repo.registrarEvento('entrega', {'origen': origen.name}));
  }

  Future<void> registrarPendiente(Pendiente pendiente) async {
    await _repo.guardarPendiente(pendiente);
    state = AsyncData(
      _actual.con(pendientes: [..._actual.pendientes, pendiente]),
    );
  }

  Future<void> eliminarCuenta() async {
    await _repo.eliminarCuenta();
    await ref.read(accesoProvider).cerrar();
  }
}

final hogarProvider = AsyncNotifierProvider<HogarNotifier, Hogar>(
  HogarNotifier.new,
);
