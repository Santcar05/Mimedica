import 'package:flutter_test/flutter_test.dart';
import 'package:mimedica_app/datos/calculo_agotamiento.dart';
import 'package:mimedica_app/datos/modelos.dart';

Tratamiento _losartan({
  double enCasa = 60,
  DateTime? contadoEl,
  double porToma = 1,
  Frecuencia frecuencia = Frecuencia.cada12,
  bool pausado = false,
}) => Tratamiento(
  id: 't1',
  personaId: 'p1',
  nombre: 'Losartán',
  concentracion: '50 mg',
  presentacion: Presentacion.tableta,
  porToma: porToma,
  frecuencia: frecuencia,
  enCasa: enCasa,
  contadoEl: contadoEl ?? DateTime(2026, 9, 3),
  creadoEl: DateTime(2026, 9, 3),
  pausado: pausado,
);

void main() {
  group('proyectar', () {
    test('60 tabletas cada 12 horas alcanzan 30 días', () {
      final p = proyectar(_losartan(), DateTime(2026, 9, 3));
      expect(p.diasRestantes, 30);
      expect(p.agotamiento, DateTime(2026, 10, 3));
      expect(p.inicioGestion, DateTime(2026, 9, 23));
    });

    test('descuenta los días que pasaron desde el conteo', () {
      final p = proyectar(_losartan(), DateTime(2026, 10, 1));
      expect(p.diasRestantes, 2);
      expect(p.enCasaHoy, 4);
      expect(p.agotamiento, DateTime(2026, 10, 3));
    });

    test('media tableta al día duplica la duración', () {
      final t = _losartan(
        enCasa: 15,
        porToma: 0.5,
        frecuencia: Frecuencia.cada24,
      );
      expect(proyectar(t, DateTime(2026, 9, 3)).diasRestantes, 30);
    });

    test('una dosis incompleta no cuenta como día cubierto', () {
      final p = proyectar(_losartan(enCasa: 5), DateTime(2026, 9, 3));
      expect(p.diasRestantes, 2);
    });

    test('después del agotamiento quedan cero días, nunca negativos', () {
      final p = proyectar(_losartan(), DateTime(2026, 11, 1));
      expect(p.diasRestantes, 0);
      expect(p.enCasaHoy, 0);
    });

    test('una cantidad absurda no rompe la fecha: se limita a diez años', () {
      final p = proyectar(_losartan(enCasa: 1e30), DateTime(2026, 9, 3));
      expect(p.diasRestantes, 3650);
      expect(p.agotamiento.year, lessThan(2040));
    });

    test('un consumo nulo no produce fechas infinitas', () {
      final p = proyectar(
        _losartan(enCasa: 60, porToma: 0),
        DateTime(2026, 9, 3),
      );
      expect(p.diasRestantes, 0);
    });

    test('la hora del día no mueve la fecha', () {
      final manana = proyectar(_losartan(), DateTime(2026, 10, 1, 0, 5));
      final noche = proyectar(_losartan(), DateTime(2026, 10, 1, 23, 55));
      expect(manana.diasRestantes, noche.diasRestantes);
    });
  });

  group('estadoDe', () {
    EstadoTratamiento estado(
      DateTime hoy, {
      Ciclo? ciclo,
      bool pausado = false,
    }) {
      final t = _losartan(pausado: pausado);
      return estadoDe(t, proyectar(t, hoy), ciclo: ciclo);
    }

    test('cubierto mientras falten más de diez días', () {
      expect(estado(DateTime(2026, 9, 10)), EstadoTratamiento.cubierto);
    });

    test('en gestión desde el día D-10', () {
      expect(estado(DateTime(2026, 9, 23)), EstadoTratamiento.enGestion);
    });

    test('en riesgo con tres días o menos', () {
      expect(estado(DateTime(2026, 9, 30)), EstadoTratamiento.enRiesgo);
    });

    test('sin dosis el día del agotamiento', () {
      expect(estado(DateTime(2026, 10, 3)), EstadoTratamiento.agotado);
    });

    test('una entrega asegurada lo devuelve a cubierto', () {
      final ciclo = Ciclo(
        id: 'c1',
        tratamientoId: 't1',
        abiertoEl: DateTime(2026, 9, 23),
        estado: EstadoCiclo.asegurado,
      );
      expect(
        estado(DateTime(2026, 9, 30), ciclo: ciclo),
        EstadoTratamiento.cubierto,
      );
    });

    test('la pausa manda sobre todo lo demás', () {
      expect(
        estado(DateTime(2026, 10, 3), pausado: true),
        EstadoTratamiento.pausado,
      );
    });
  });

  test('una entrega suma a lo que quedaba ese día', () {
    final t = _losartan();
    expect(enCasaTrasEntrega(t, 60, DateTime(2026, 10, 1)), 64);
    expect(enCasaTrasEntrega(t, 60, DateTime(2026, 10, 20)), 60);
  });

  test('el tratamiento sobrevive a ir y volver de JSON', () {
    final t = _losartan().con(vigenciaHasta: DateTime(2027, 2, 4));
    final copia = Tratamiento.deJson(t.aJson());
    expect(copia.titulo, 'Losartán 50 mg');
    expect(copia.contadoEl, t.contadoEl);
    expect(copia.vigenciaHasta, DateTime(2027, 2, 4));
    expect(copia.frecuencia, Frecuencia.cada12);
  });
}
