import 'package:intl/intl.dart';

typedef Json = Map<String, dynamic>;

final _soloFecha = DateFormat('yyyy-MM-dd');

String _fecha(DateTime d) => _soloFecha.format(d);
DateTime _leerFecha(String s) => DateTime.parse(s.substring(0, 10));
DateTime? _leerFechaOpc(Object? s) => s == null ? null : _leerFecha(s as String);
DateTime? _leerInstante(Object? s) =>
    s == null ? null : DateTime.parse(s as String).toLocal();
double? _num(Object? n) => (n as num?)?.toDouble();

/// Día sin hora, en la zona del teléfono.
DateTime soloDia(DateTime d) => DateTime(d.year, d.month, d.day);

enum Frecuencia {
  cada24(1, 'Cada 24 horas', 'una vez al día'),
  cada12(2, 'Cada 12 horas', 'cada 12 horas'),
  cada8(3, 'Cada 8 horas', 'cada 8 horas'),
  cada6(4, 'Cada 6 horas', 'cada 6 horas');

  const Frecuencia(this.tomasAlDia, this.rotulo, this.enFrase);
  final int tomasAlDia;
  final String rotulo;
  final String enFrase;
}

enum Presentacion {
  tableta('Tableta', 'tableta', 'tabletas', 'tab.'),
  capsula('Cápsula', 'cápsula', 'cápsulas', 'cáps.'),
  unidad('Otra', 'unidad', 'unidades', 'und.');

  const Presentacion(this.rotulo, this.singular, this.plural, this.corto);
  final String rotulo;
  final String singular;
  final String plural;
  final String corto;

  String contar(double n) => '${cantidad(n)} ${n == 1 ? singular : plural}';
}

/// «1», «0,5», «2,5»: cantidades como se escriben en Colombia.
String cantidad(double n) => n == n.roundToDouble()
    ? n.toInt().toString()
    : n.toStringAsFixed(1).replaceAll('.', ',');

class Perfil {
  const Perfil({
    required this.nombre,
    required this.tipoDocumento,
    required this.documento,
    required this.nacimiento,
    this.autorizoServicioEl,
    this.autorizaEstadistica = false,
  });

  static const versionAutorizacion = '2026-11';

  final String nombre;
  final String tipoDocumento;
  final String documento;
  final DateTime nacimiento;
  final DateTime? autorizoServicioEl;
  final bool autorizaEstadistica;

  bool get autorizo => autorizoServicioEl != null;
  String get primerNombre => nombre.trim().split(RegExp(r'\s+')).first;

  Perfil con({
    DateTime? autorizoServicioEl,
    bool? autorizaEstadistica,
    bool revocar = false,
  }) => Perfil(
    nombre: nombre,
    tipoDocumento: tipoDocumento,
    documento: documento,
    nacimiento: nacimiento,
    autorizoServicioEl: revocar
        ? null
        : autorizoServicioEl ?? this.autorizoServicioEl,
    autorizaEstadistica: autorizaEstadistica ?? this.autorizaEstadistica,
  );

  factory Perfil.deJson(Json j) => Perfil(
    nombre: j['nombre'] as String,
    tipoDocumento: j['tipo_documento'] as String,
    documento: j['documento'] as String,
    nacimiento: _leerFecha(j['nacimiento'] as String),
    autorizoServicioEl: _leerInstante(j['autorizo_servicio_el']),
    autorizaEstadistica: j['autoriza_estadistica'] as bool? ?? false,
  );

  Json aJson() => {
    'nombre': nombre,
    'tipo_documento': tipoDocumento,
    'documento': documento,
    'nacimiento': _fecha(nacimiento),
    'autorizo_servicio_el': autorizoServicioEl?.toUtc().toIso8601String(),
    'autoriza_estadistica': autorizaEstadistica,
    'version_autorizacion': autorizo ? versionAutorizacion : null,
  };
}

class Persona {
  const Persona({
    required this.id,
    required this.nombre,
    required this.esTitular,
    this.eps,
  });

  final String id;
  final String nombre;

  /// Verdadero cuando el tratamiento es de quien usa la app.
  final bool esTitular;
  final String? eps;

  String get primerNombre => nombre.trim().split(RegExp(r'\s+')).first;

  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    final letras = partes.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return letras.toUpperCase();
  }

  factory Persona.deJson(Json j) => Persona(
    id: j['id'] as String,
    nombre: j['nombre'] as String,
    esTitular: j['es_titular'] as bool? ?? false,
    eps: j['eps'] as String?,
  );

  Json aJson() => {
    'id': id,
    'nombre': nombre,
    'es_titular': esTitular,
    'eps': eps,
  };
}

class Tratamiento {
  const Tratamiento({
    required this.id,
    required this.personaId,
    required this.nombre,
    required this.concentracion,
    required this.presentacion,
    required this.porToma,
    required this.frecuencia,
    required this.enCasa,
    required this.contadoEl,
    required this.creadoEl,
    this.vigenciaHasta,
    this.fotoFormula,
    this.pausado = false,
  });

  final String id;
  final String personaId;
  final String nombre;
  final String concentracion;
  final Presentacion presentacion;
  final double porToma;
  final Frecuencia frecuencia;

  /// Unidades que había en casa el día [contadoEl].
  final double enCasa;
  final DateTime contadoEl;
  final DateTime creadoEl;
  final DateTime? vigenciaHasta;
  final String? fotoFormula;
  final bool pausado;

  String get titulo =>
      concentracion.isEmpty ? nombre : '$nombre $concentracion';
  double get consumoDiario => porToma * frecuencia.tomasAlDia;
  String get posologia =>
      '${presentacion.contar(porToma)} ${frecuencia.enFrase}';

  Tratamiento con({
    String? nombre,
    String? concentracion,
    Presentacion? presentacion,
    double? porToma,
    Frecuencia? frecuencia,
    double? enCasa,
    DateTime? contadoEl,
    DateTime? vigenciaHasta,
    String? fotoFormula,
    bool? pausado,
  }) => Tratamiento(
    id: id,
    personaId: personaId,
    nombre: nombre ?? this.nombre,
    concentracion: concentracion ?? this.concentracion,
    presentacion: presentacion ?? this.presentacion,
    porToma: porToma ?? this.porToma,
    frecuencia: frecuencia ?? this.frecuencia,
    enCasa: enCasa ?? this.enCasa,
    contadoEl: contadoEl ?? this.contadoEl,
    creadoEl: creadoEl,
    vigenciaHasta: vigenciaHasta ?? this.vigenciaHasta,
    fotoFormula: fotoFormula ?? this.fotoFormula,
    pausado: pausado ?? this.pausado,
  );

  factory Tratamiento.deJson(Json j) => Tratamiento(
    id: j['id'] as String,
    personaId: j['persona_id'] as String,
    nombre: j['nombre'] as String,
    concentracion: j['concentracion'] as String? ?? '',
    presentacion: Presentacion.values.byName(j['presentacion'] as String),
    porToma: (j['por_toma'] as num).toDouble(),
    frecuencia: Frecuencia.values.byName(j['frecuencia'] as String),
    enCasa: (j['en_casa'] as num).toDouble(),
    contadoEl: _leerFecha(j['contado_el'] as String),
    creadoEl: _leerInstante(j['creado_el']) ?? DateTime.now(),
    vigenciaHasta: _leerFechaOpc(j['vigencia_hasta']),
    fotoFormula: j['foto_formula'] as String?,
    pausado: j['pausado'] as bool? ?? false,
  );

  Json aJson() => {
    'id': id,
    'persona_id': personaId,
    'nombre': nombre,
    'concentracion': concentracion,
    'presentacion': presentacion.name,
    'por_toma': porToma,
    'frecuencia': frecuencia.name,
    'en_casa': enCasa,
    'contado_el': _fecha(contadoEl),
    'creado_el': creadoEl.toUtc().toIso8601String(),
    'vigencia_hasta': vigenciaHasta == null ? null : _fecha(vigenciaHasta!),
    'foto_formula': fotoFormula,
    'pausado': pausado,
  };
}

enum EstadoCiclo { abierto, asegurado, cerrado }

enum OrigenEntrega {
  eps('EPS'),
  particular('Compra particular');

  const OrigenEntrega(this.rotulo);
  final String rotulo;
}

/// Un ciclo de reposición: se abre diez días antes del agotamiento y se
/// cierra cuando el medicamento llega a casa.
class Ciclo {
  const Ciclo({
    required this.id,
    required this.tratamientoId,
    required this.abiertoEl,
    this.estado = EstadoCiclo.abierto,
    this.nota,
    this.origen,
    this.cantidad,
    this.punto,
    this.cerradoEl,
  });

  final String id;
  final String tratamientoId;
  final DateTime abiertoEl;
  final EstadoCiclo estado;

  /// Lo que el equipo averiguó, en una frase para el cuidador.
  final String? nota;
  final OrigenEntrega? origen;
  final double? cantidad;
  final String? punto;
  final DateTime? cerradoEl;

  bool get enCurso => estado != EstadoCiclo.cerrado;

  Ciclo cerrar({
    required OrigenEntrega origen,
    required double cantidad,
    required DateTime fecha,
    String? punto,
  }) => Ciclo(
    id: id,
    tratamientoId: tratamientoId,
    abiertoEl: abiertoEl,
    estado: EstadoCiclo.cerrado,
    nota: nota,
    origen: origen,
    cantidad: cantidad,
    punto: punto,
    cerradoEl: fecha,
  );

  factory Ciclo.deJson(Json j) => Ciclo(
    id: j['id'] as String,
    tratamientoId: j['tratamiento_id'] as String,
    abiertoEl: _leerFecha(j['abierto_el'] as String),
    estado: EstadoCiclo.values.byName(j['estado'] as String),
    nota: j['nota'] as String?,
    origen: j['origen'] == null
        ? null
        : OrigenEntrega.values.byName(j['origen'] as String),
    cantidad: _num(j['cantidad']),
    punto: j['punto'] as String?,
    cerradoEl: _leerFechaOpc(j['cerrado_el']),
  );

  Json aJson() => {
    'id': id,
    'tratamiento_id': tratamientoId,
    'abierto_el': _fecha(abiertoEl),
    'estado': estado.name,
    'nota': nota,
    'origen': origen?.name,
    'cantidad': cantidad,
    'punto': punto,
    'cerrado_el': cerradoEl == null ? null : _fecha(cerradoEl!),
  };
}

enum TipoOpcion { eps, drogueria }

/// Un punto donde el equipo verificó que el medicamento está disponible.
class Opcion {
  const Opcion({
    required this.id,
    required this.cicloId,
    required this.tipo,
    required this.nombre,
    this.direccion,
    this.precio,
    this.distanciaKm,
    this.telefono,
    this.verificadoEl,
  });

  final String id;
  final String cicloId;
  final TipoOpcion tipo;
  final String nombre;
  final String? direccion;

  /// Pesos colombianos; nulo cuando lo entrega la EPS.
  final int? precio;
  final double? distanciaKm;
  final String? telefono;
  final DateTime? verificadoEl;

  factory Opcion.deJson(Json j) => Opcion(
    id: j['id'] as String,
    cicloId: j['ciclo_id'] as String,
    tipo: TipoOpcion.values.byName(j['tipo'] as String),
    nombre: j['nombre'] as String,
    direccion: j['direccion'] as String?,
    precio: (j['precio'] as num?)?.toInt(),
    distanciaKm: _num(j['distancia_km']),
    telefono: j['telefono'] as String?,
    verificadoEl: _leerInstante(j['verificado_el']),
  );

  Json aJson() => {
    'id': id,
    'ciclo_id': cicloId,
    'tipo': tipo.name,
    'nombre': nombre,
    'direccion': direccion,
    'precio': precio,
    'distancia_km': distanciaKm,
    'telefono': telefono,
    'verificado_el': verificadoEl?.toUtc().toIso8601String(),
  };
}

/// Lo que la EPS no entregó: la evidencia para reclamar después.
class Pendiente {
  const Pendiente({
    required this.id,
    required this.tratamientoId,
    required this.fecha,
    required this.punto,
    this.faltante,
    this.nota,
  });

  final String id;
  final String tratamientoId;
  final DateTime fecha;
  final String punto;
  final double? faltante;
  final String? nota;

  factory Pendiente.deJson(Json j) => Pendiente(
    id: j['id'] as String,
    tratamientoId: j['tratamiento_id'] as String,
    fecha: _leerFecha(j['fecha'] as String),
    punto: j['punto'] as String,
    faltante: _num(j['faltante']),
    nota: j['nota'] as String?,
  );

  Json aJson() => {
    'id': id,
    'tratamiento_id': tratamientoId,
    'fecha': _fecha(fecha),
    'punto': punto,
    'faltante': faltante,
    'nota': nota,
  };
}
