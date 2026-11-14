import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../datos/hogar.dart';
import '../funciones/ingreso/bienvenida.dart';
import '../funciones/ingreso/ingreso_codigo.dart';
import '../funciones/ingreso/ingreso_correo.dart';

/// Rutas que se pueden ver sin sesión.
const _publicas = {'/', '/ingreso', '/ingreso/codigo'};

final routerProvider = Provider<GoRouter>((ref) {
  final cambios = ValueNotifier<int>(0);
  ref.listen(sesionProvider, (_, _) => cambios.value++);
  ref.listen(hogarProvider, (_, _) => cambios.value++);
  ref.onDispose(cambios.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: cambios,
    redirect: (context, estado) {
      final ruta = estado.matchedLocation;
      final conSesion = ref.read(sesionProvider);

      if (!conSesion) return _publicas.contains(ruta) ? null : '/';
      if (_publicas.contains(ruta)) return '/inicio';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Bienvenida()),
      GoRoute(
        path: '/ingreso',
        builder: (_, _) => const IngresoCorreo(),
        routes: [
          GoRoute(
            path: 'codigo',
            builder: (_, estado) =>
                IngresoCodigo(correo: estado.extra as String),
          ),
        ],
      ),
      GoRoute(
        path: '/inicio',
        builder: (_, _) => const Scaffold(body: Center(child: Text('Inicio'))),
      ),
    ],
  );
});
