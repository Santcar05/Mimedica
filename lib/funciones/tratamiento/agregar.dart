import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../datos/formato.dart';
import '../../datos/hogar.dart';
import '../../nucleo/widgets/filas.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/pantalla.dart';
import '../activacion/borrador.dart';

/// B-04: dos rutas, una fórmula nueva o un medicamento más de una que ya se
/// cargó (sin volver a fotografiarla).
class AgregarTratamiento extends ConsumerWidget {
  const AgregarTratamiento({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hogar = ref.watch(hogarProvider).value;
    final persona = hogar?.personas.firstOrNull;
    if (hogar == null || persona == null) return const SizedBox.shrink();

    final conFoto =
        hogar.tratamientos
            .where((t) => t.personaId == persona.id && t.fotoFormula != null)
            .toList()
          ..sort((a, b) => b.creadoEl.compareTo(a.creadoEl));
    final ultima = conFoto.firstOrNull;

    void nueva() {
      ref.read(borradorProvider.notifier).empezar(persona);
      context.pushReplacement('/formula/captura');
    }

    void deLaUltima() {
      ref.read(borradorProvider.notifier)
        ..empezar(persona)
        ..guardada(ultima!.fotoFormula!);
      context.pushReplacement('/formula/plan');
    }

    return Pantalla(
      hijos: [
        const Cabecera('¿De dónde sale el nuevo tratamiento?'),
        const SizedBox(height: 24),
        TarjetaOpcion(
          icono: Icono.camara,
          titulo: 'Una fórmula nueva',
          detalle: 'Le tomas la foto y armas el plan en un par de minutos.',
          alPulsar: nueva,
        ),
        if (ultima != null) ...[
          const SizedBox(height: 12),
          TarjetaOpcion(
            icono: Icono.documento,
            titulo: 'La fórmula que ya subiste',
            detalle:
                'Agregas otro medicamento de la fórmula del '
                '${fechaMinima(ultima.creadoEl)}, sin tomar otra foto.',
            alPulsar: deLaUltima,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Para ${persona.nombre}.',
          style: const TextStyle(fontFamily: 'General Sans', fontSize: 13.5),
        ),
      ],
    );
  }
}
