import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mimedica_app/datos/calculo_agotamiento.dart';
import 'package:mimedica_app/datos/hogar.dart';
import 'package:mimedica_app/datos/modelos.dart';
import 'package:mimedica_app/datos/repositorio_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _hoy = DateTime(2026, 11, 13);

Future<ProviderContainer> _contenedor() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final acceso = AccesoLocal(prefs);
  await acceso.verificar('camila@correo.com', AccesoLocal.codigoDemo);

  final contenedor = ProviderContainer(
    overrides: [
      repositorioProvider.overrideWithValue(RepositorioLocal(prefs)),
      accesoProvider.overrideWithValue(acceso),
      hoyProvider.overrideWithValue(_hoy),
    ],
  );
  addTearDown(contenedor.dispose);
  await contenedor.read(hogarProvider.future);

  final notificador = contenedor.read(hogarProvider.notifier);
  await notificador.guardarPerfil(
    Perfil(
      nombre: 'Camila Ramírez Ortiz',
      tipoDocumento: 'Cédula de ciudadanía',
      documento: '1020745318',
      nacimiento: DateTime(1991, 3, 14),
    ),
  );
  await notificador.autorizar(estadistica: false);
  await notificador.guardarPersona(
    const Persona(id: 'p1', nombre: 'Elena Ramírez', esTitular: false),
  );
  return contenedor;
}

Tratamiento _losartan({required DateTime contadoEl, double enCasa = 60}) =>
    Tratamiento(
      id: 't1',
      personaId: 'p1',
      nombre: 'Losartán',
      concentracion: '50 mg',
      presentacion: Presentacion.tableta,
      porToma: 1,
      frecuencia: Frecuencia.cada12,
      enCasa: enCasa,
      contadoEl: contadoEl,
      creadoEl: contadoEl,
    );

void main() {
  test('no abre ciclo mientras falten más de diez días', () async {
    final c = await _contenedor();
    await c
        .read(hogarProvider.notifier)
        .guardarTratamiento(_losartan(contadoEl: DateTime(2026, 11, 10)));

    final hogar = c.read(hogarProvider).requireValue;
    expect(hogar.ciclos, isEmpty);
    expect(hogar.activado, isTrue);
  });

  test('abre el ciclo cuando el tratamiento entra a los diez días', () async {
    final c = await _contenedor();
    await c
        .read(hogarProvider.notifier)
        .guardarTratamiento(_losartan(contadoEl: DateTime(2026, 10, 20)));

    final hogar = c.read(hogarProvider).requireValue;
    expect(hogar.ciclos, hasLength(1));
    expect(hogar.cicloEnCurso('t1')?.estado, EstadoCiclo.abierto);
  });

  test('no duplica el ciclo si se guarda otra vez', () async {
    final c = await _contenedor();
    final notificador = c.read(hogarProvider.notifier);
    final t = _losartan(contadoEl: DateTime(2026, 10, 20));
    await notificador.guardarTratamiento(t);
    await notificador.guardarTratamiento(t.con(pausado: false));

    expect(c.read(hogarProvider).requireValue.ciclos, hasLength(1));
  });

  test('una entrega cierra el ciclo y recalcula la fecha', () async {
    final c = await _contenedor();
    final notificador = c.read(hogarProvider.notifier);
    await notificador.guardarTratamiento(
      _losartan(contadoEl: DateTime(2026, 10, 20)),
    );

    await notificador.registrarEntrega(
      tratamientoId: 't1',
      origen: OrigenEntrega.eps,
      cantidad: 60,
      fecha: _hoy,
      punto: 'Compensar',
    );

    final hogar = c.read(hogarProvider).requireValue;
    final t = hogar.tratamiento('t1')!;
    // Quedaban 12 tabletas el 13 de noviembre; con las 60 nuevas son 72.
    expect(t.enCasa, 72);
    expect(proyectar(t, _hoy).agotamiento, DateTime(2026, 12, 19));
    expect(hogar.cicloEnCurso('t1'), isNull);
    expect(hogar.ciclosDe('t1').single.estado, EstadoCiclo.cerrado);
  });

  test('eliminar un tratamiento borra sus ciclos', () async {
    final c = await _contenedor();
    final notificador = c.read(hogarProvider.notifier);
    await notificador.guardarTratamiento(
      _losartan(contadoEl: DateTime(2026, 10, 20)),
    );
    await notificador.eliminarTratamiento('t1');

    final hogar = c.read(hogarProvider).requireValue;
    expect(hogar.tratamientos, isEmpty);
    expect(hogar.ciclos, isEmpty);
  });

  test('revocar la autorización deja el hogar sin activar', () async {
    final c = await _contenedor();
    final notificador = c.read(hogarProvider.notifier);
    await notificador.guardarTratamiento(
      _losartan(contadoEl: DateTime(2026, 11, 10)),
    );
    await notificador.revocarAutorizacion();

    expect(c.read(hogarProvider).requireValue.activado, isFalse);
  });
}
