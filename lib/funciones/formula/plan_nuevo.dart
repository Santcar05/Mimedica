import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../datos/hogar.dart';
import '../activacion/borrador.dart';
import '../tratamiento/formulario_tratamiento.dart';

/// A-10: confirmar el medicamento que se copió de la fórmula.
class PlanNuevo extends ConsumerWidget {
  const PlanNuevo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borrador = ref.watch(borradorProvider);
    final persona =
        borrador.persona ?? ref.watch(hogarProvider).value?.personas.lastOrNull;
    if (persona == null) return const SizedBox.shrink();

    return FormularioTratamiento(
      persona: persona,
      foto: borrador.foto,
      rutaFoto: borrador.rutaFoto,
      alGuardar: (t) =>
          context.pushReplacement('/activacion/plan-activo', extra: t.id),
    );
  }
}
