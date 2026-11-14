import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tema.dart';
import '../../datos/hogar.dart';
import '../../datos/repositorio.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/pantalla.dart';
import 'logo.dart';

/// Pantalla de paso mientras se carga el hogar al abrir la app. El router la
/// reemplaza por la pantalla que corresponde en cuanto hay datos.
class Entrada extends ConsumerWidget {
  const Entrada({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hogar = ref.watch(hogarProvider);
    final error = hogar.hasError ? hogar.error : null;

    if (error == null) {
      return Scaffold(
        body: Center(
          child: Semantics(
            label: 'Cargando Mimedica',
            liveRegion: true,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Logo(tam: 176),
                SizedBox(height: 40),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    color: Tinta.azul,
                    backgroundColor: Tinta.azulSuave,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final fallo = error is Fallo ? error : null;
    final sinRed = fallo?.sinRed ?? false;
    final vencida = fallo?.sesionVencida ?? false;

    return Pantalla(
      conVolver: false,
      hijos: [
        const SizedBox(height: 64),
        Trazo(
          sinRed ? Icono.sinRed : Icono.alerta,
          tam: 32,
          color: Tinta.apagada,
        ),
        const SizedBox(height: 16),
        Cabecera(
          vencida
              ? 'Tu sesión venció'
              : sinRed
              ? 'No hay conexión'
              : 'No pudimos abrir tus datos',
          bajada:
              fallo?.mensaje ??
              'Tus datos siguen guardados. Inténtalo de nuevo en un momento.',
        ),
      ],
      pie: [
        if (vencida)
          Boton(
            'Entrar de nuevo',
            alPulsar: () => ref.read(accesoProvider).cerrar(),
          )
        else
          Boton(
            'Intentar de nuevo',
            icono: Icono.reintentar,
            alPulsar: () => ref.invalidate(hogarProvider),
          ),
      ],
    );
  }
}
