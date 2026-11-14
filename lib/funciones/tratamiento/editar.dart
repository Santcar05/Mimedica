import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../datos/hogar.dart';
import 'formulario_tratamiento.dart';

/// B-03: corregir posología o lo que hay en casa; la fecha se recalcula.
class EditarTratamiento extends ConsumerWidget {
  const EditarTratamiento({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hogar = ref.watch(hogarProvider).value;
    final t = hogar?.tratamiento(id);
    final persona = t == null ? null : hogar!.persona(t.personaId);
    if (t == null || persona == null) return const SizedBox.shrink();

    return FormularioTratamiento(
      persona: persona,
      existente: t,
      alGuardar: (_) => context.pop(),
    );
  }
}
