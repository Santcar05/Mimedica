import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../datos/hogar.dart';
import '../funciones/activacion/consentimiento.dart';
import '../funciones/activacion/datos_basicos.dart';
import '../funciones/activacion/plan_activo.dart';
import '../funciones/activacion/quien_usa.dart';
import '../funciones/formula/captura.dart';
import '../funciones/formula/plan_nuevo.dart';
import '../funciones/formula/previsualizacion.dart';
import '../funciones/ingreso/bienvenida.dart';
import '../funciones/inicio/cascaron.dart';
import '../funciones/inicio/inicio.dart';
import '../funciones/tratamiento/agregar.dart';
import '../funciones/tratamiento/detalle.dart';
import '../funciones/tratamiento/editar.dart';
import '../funciones/ingreso/entrada.dart';
import '../funciones/ingreso/ingreso_codigo.dart';
import '../funciones/ingreso/ingreso_correo.dart';

/// Rutas que se pueden ver sin sesión.
const _publicas = {'/', '/ingreso', '/ingreso/codigo'};

/// Pasos de la activación que no tienen sentido una vez completada.
const _soloActivacion = {
  '/activacion/datos',
  '/activacion/consentimiento',
  '/activacion/quien',
};

/// Primer paso de la activación que falta, o nulo si ya terminó.
String? _pasoPendiente(Hogar hogar) {
  final perfil = hogar.perfil;
  if (perfil == null) return '/activacion/datos';
  if (!perfil.autorizo) return '/activacion/consentimiento';
  if (hogar.tratamientos.isEmpty) {
    return hogar.personas.isEmpty ? '/activacion/quien' : '/formula/captura';
  }
  return null;
}

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

      if (!ref.read(sesionProvider)) {
        return _publicas.contains(ruta) ? null : '/';
      }

      final hogar = ref.read(hogarProvider);
      if (!hogar.hasValue) return ruta == '/entrada' ? null : '/entrada';

      final pendiente = _pasoPendiente(hogar.requireValue);
      if (pendiente != null) {
        final enActivacion =
            ruta.startsWith('/activacion') || ruta.startsWith('/formula');
        return enActivacion ? null : pendiente;
      }

      final sobra =
          _publicas.contains(ruta) ||
          ruta == '/entrada' ||
          _soloActivacion.contains(ruta);
      return sobra ? '/inicio' : null;
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
      GoRoute(path: '/entrada', builder: (_, _) => const Entrada()),
      GoRoute(
        path: '/activacion/datos',
        builder: (_, _) => const DatosBasicos(),
      ),
      GoRoute(
        path: '/activacion/consentimiento',
        builder: (_, _) => const Consentimiento(),
      ),
      GoRoute(path: '/activacion/quien', builder: (_, _) => const QuienUsa()),
      GoRoute(
        path: '/activacion/plan-activo',
        builder: (_, estado) =>
            PlanActivo(tratamientoId: estado.extra as String),
      ),
      GoRoute(
        path: '/formula/captura',
        builder: (_, _) => const CapturaFormula(),
      ),
      GoRoute(
        path: '/formula/previa',
        builder: (_, _) => const Previsualizacion(),
      ),
      GoRoute(path: '/formula/plan', builder: (_, _) => const PlanNuevo()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, pestanas) => Cascaron(pestanas: pestanas),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/inicio', builder: (_, _) => const Inicio()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/pendientes', builder: (_, _) => const Scaffold()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/cuenta', builder: (_, _) => const Scaffold()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/tratamiento/nuevo',
        builder: (_, _) => const AgregarTratamiento(),
      ),
      GoRoute(
        path: '/tratamiento/:id',
        builder: (_, estado) =>
            DetalleTratamiento(id: estado.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'editar',
            builder: (_, estado) =>
                EditarTratamiento(id: estado.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
