import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mimedica_app/app/router.dart';
import 'package:mimedica_app/datos/hogar.dart';
import 'package:mimedica_app/datos/modelos.dart';
import 'package:mimedica_app/datos/repositorio_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repositorio que tarda en responder, como una conexión lenta.
class _Lento extends RepositorioLocal {
  _Lento(super.prefs, this.espera);
  final Completer<void> espera;

  @override
  Future<Perfil?> perfil() async {
    await espera.future;
    return super.perfil();
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets(
    'después del código se muestra la carga y no los pasos de registro',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final espera = Completer<void>();
      final acceso = AccesoLocal(prefs);

      final contenedor = ProviderContainer(
        overrides: [
          repositorioProvider.overrideWithValue(_Lento(prefs, espera)),
          accesoProvider.overrideWithValue(acceso),
          hoyProvider.overrideWithValue(DateTime(2026, 11, 14)),
        ],
      );
      addTearDown(contenedor.dispose);

      final router = contenedor.read(routerProvider);
      String ruta() => router.routerDelegate.currentConfiguration.uri.path;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: contenedor,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(ruta(), '/');

      await acceso.verificar('camila@correo.com', AccesoLocal.codigoDemo);
      await tester.pump();
      // La rueda gira sin parar: se avanza el tiempo en vez de esperar a que
      // todo se detenga.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Los datos todavía no llegan: debe verse la carga, nada más.
      expect(ruta(), '/entrada');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cuéntanos quién eres'), findsNothing);

      espera.complete();
      await tester.pumpAndSettle();

      // Con los datos ya cargados, una persona nueva va a sus datos básicos.
      expect(ruta(), '/activacion/datos');
      expect(find.text('Cuéntanos quién eres'), findsOneWidget);
    },
  );
}
