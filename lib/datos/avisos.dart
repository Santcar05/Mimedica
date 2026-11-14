import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as zonas;
import 'package:timezone/timezone.dart' as tz;

import 'calculo_agotamiento.dart';
import 'hogar.dart';

/// Avisos del teléfono: uno el día D-10, cuando empieza la gestión, y otro
/// tres días antes del agotamiento si el ciclo sigue abierto.
///
/// Son notificaciones locales programadas: funcionan sin servidor y sin
/// conexión, pero solo existen mientras el teléfono las conserve.
class Avisos {
  Avisos._();
  static final instancia = Avisos._();

  static const _hora = 9;
  static const _canal = AndroidNotificationDetails(
    'ciclos',
    'Avisos de reposición',
    channelDescription:
        'Te avisamos cuando empezamos a gestionar un medicamento.',
    importance: Importance.high,
    priority: Priority.high,
  );

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _listo = false;

  /// Se llama con la ruta de la pantalla a la que lleva el aviso.
  void Function(String ruta)? alTocar;

  bool get _disponible => _listo && !kIsWeb;

  Future<void> iniciar() async {
    if (kIsWeb) return;
    zonas.initializeTimeZones();
    // Colombia no tiene cambio de hora: UTC-5 todo el año.
    tz.setLocalLocation(tz.getLocation('America/Bogota'));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (respuesta) {
        final ruta = respuesta.payload;
        if (ruta != null) alTocar?.call(ruta);
      },
    );
    _listo = true;
  }

  /// Pide permiso para avisar. Conviene hacerlo cuando el usuario ya entendió
  /// para qué: justo después de activar el primer plan.
  Future<bool> pedirPermiso() async {
    if (!_disponible) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  /// Deja programados exactamente los avisos que corresponden al estado
  /// actual del hogar.
  Future<void> sincronizar(Hogar hogar, DateTime hoy) async {
    if (!_disponible) return;
    await _plugin.cancelAllPendingNotifications();

    final ahora = tz.TZDateTime.now(tz.local);
    for (final t in hogar.tratamientos) {
      if (t.pausado) continue;
      final persona = hogar.persona(t.personaId);
      final de = (persona?.esTitular ?? false)
          ? ''
          : ' de ${persona?.primerNombre}';
      final p = proyectar(t, hoy);
      final base = (t.id.hashCode & 0x1fffffff) * 2;
      final ruta = '/tratamiento/${t.id}';

      final inicio = _a(p.inicioGestion);
      if (inicio.isAfter(ahora)) {
        await _programar(
          base,
          inicio,
          'Faltan $diasDeGestion días de ${t.nombre}$de',
          'Ya empezamos a gestionarlo. Abre Mimedica para ver cómo va.',
          ruta,
        );
      }

      final riesgo = _a(p.agotamiento.subtract(const Duration(days: 3)));
      if (riesgo.isAfter(ahora)) {
        await _programar(
          base + 1,
          riesgo,
          'Quedan 3 días de ${t.nombre}$de',
          'Revisa tus opciones para conseguirlo a tiempo.',
          ruta,
        );
      }
    }
  }

  tz.TZDateTime _a(DateTime dia) =>
      tz.TZDateTime(tz.local, dia.year, dia.month, dia.day, _hora);

  Future<void> _programar(
    int id,
    tz.TZDateTime cuando,
    String titulo,
    String cuerpo,
    String ruta,
  ) {
    return _plugin.zonedSchedule(
      id: id,
      title: titulo,
      body: cuerpo,
      scheduledDate: cuando,
      notificationDetails: const NotificationDetails(
        android: _canal,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: ruta,
    );
  }

  Future<void> cancelarTodo() async {
    if (_disponible) await _plugin.cancelAllPendingNotifications();
  }
}
