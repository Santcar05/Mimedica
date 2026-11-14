import 'dart:math';

import 'modelos.dart';

/// Días antes del agotamiento en que empieza la gestión.
const diasDeGestion = 10;

/// Por debajo de este margen el tratamiento se muestra en riesgo.
const diasDeRiesgo = 3;

enum EstadoTratamiento {
  enRiesgo('En riesgo'),
  agotado('Sin dosis'),
  enGestion('En gestión'),
  cubierto('Cubierto'),
  pausado('En pausa');

  const EstadoTratamiento(this.rotulo);
  final String rotulo;
}

class Proyeccion {
  const Proyeccion({
    required this.diasRestantes,
    required this.agotamiento,
    required this.enCasaHoy,
  });

  /// Días completos de dosis contando desde hoy.
  final int diasRestantes;

  /// Primer día sin dosis completa: «le alcanza hasta el…».
  final DateTime agotamiento;
  final double enCasaHoy;

  DateTime get inicioGestion =>
      agotamiento.subtract(const Duration(days: diasDeGestion));

  bool get enVentana => diasRestantes <= diasDeGestion;
}

int _diasEntre(DateTime desde, DateTime hasta) => DateTime.utc(
  hasta.year,
  hasta.month,
  hasta.day,
).difference(DateTime.utc(desde.year, desde.month, desde.day)).inDays;

/// Proyecta el agotamiento a partir de lo que había en casa el día del conteo.
///
/// Las cuentas se hacen sobre días de calendario para que el cambio de hora
/// o la hora del día no muevan la fecha.
Proyeccion proyectar(Tratamiento t, DateTime hoy) {
  final consumo = t.consumoDiario;
  if (consumo <= 0) {
    return Proyeccion(
      diasRestantes: 0,
      agotamiento: soloDia(hoy),
      enCasaHoy: t.enCasa,
    );
  }

  final diasCubiertos = (t.enCasa / consumo + 1e-9).floor();
  final conteo = soloDia(t.contadoEl);
  final agotamiento = DateTime(
    conteo.year,
    conteo.month,
    conteo.day + diasCubiertos,
  );

  final transcurridos = max(0, _diasEntre(conteo, hoy));
  final quedan = (t.enCasa - consumo * transcurridos).clamp(0.0, t.enCasa);

  return Proyeccion(
    diasRestantes: max(0, _diasEntre(hoy, agotamiento)),
    agotamiento: agotamiento,
    enCasaHoy: quedan,
  );
}

EstadoTratamiento estadoDe(Tratamiento t, Proyeccion p, {Ciclo? ciclo}) {
  if (t.pausado) return EstadoTratamiento.pausado;
  if (p.diasRestantes <= 0) return EstadoTratamiento.agotado;
  if (ciclo?.estado == EstadoCiclo.asegurado) return EstadoTratamiento.cubierto;
  if (p.diasRestantes <= diasDeRiesgo) return EstadoTratamiento.enRiesgo;
  if (p.enVentana) return EstadoTratamiento.enGestion;
  return EstadoTratamiento.cubierto;
}

/// Lo que queda en casa después de una entrega recibida el día [fecha].
double enCasaTrasEntrega(Tratamiento t, double recibido, DateTime fecha) =>
    proyectar(t, fecha).enCasaHoy + recibido;
