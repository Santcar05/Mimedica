import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tema.dart';
import '../../datos/calculo_agotamiento.dart';
import '../../datos/formato.dart';
import '../../datos/hogar.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/campo.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/pantalla.dart';
import 'borrador.dart';

/// A-11: cierra la activación y dice qué pasa ahora y cuándo se vuelve a saber
/// de Mimedica.
class PlanActivo extends ConsumerWidget {
  const PlanActivo({super.key, required this.tratamientoId});
  final String tratamientoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hogar = ref.watch(hogarProvider).value;
    final t = hogar?.tratamiento(tratamientoId);
    final persona = t == null ? null : hogar!.persona(t.personaId);
    if (t == null || persona == null) return const SizedBox.shrink();

    final p = proyectar(t, ref.watch(hoyProvider));
    final eps = persona.eps ?? 'tu EPS';

    void irAlInicio() {
      ref.read(borradorProvider.notifier).limpiar();
      context.go('/inicio');
    }

    return Pantalla(
      conVolver: false,
      hijos: [
        const SizedBox(height: 8),
        const Row(
          children: [
            Trazo(Icono.check, tam: 20, color: Tinta.ok),
            SizedBox(width: 8),
            Text(
              'Plan activo',
              style: TextStyle(
                fontFamily: 'General Sans',
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Tinta.ok,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            persona.esTitular
                ? 'Tu ${t.nombre} ya tiene fecha'
                : 'El ${t.nombre} de ${persona.primerNombre} ya tiene fecha',
            style: Letra.display,
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            text: 'Se acaba el ',
            children: [
              TextSpan(
                text: fechaCorta(p.agotamiento),
                style: Letra.cuerpoFuerte.tabular,
              ),
              const TextSpan(text: '. Desde ahí contamos hacia atrás.'),
            ],
          ),
          style: Letra.cuerpo.copyWith(color: Tinta.suave),
        ),
        const SizedBox(height: 32),
        const Rotulo('Qué pasa ahora'),
        const SizedBox(height: 12),
        _Paso(
          1,
          p.enVentana
              ? 'Ya estamos a menos de diez días: empezamos a gestionarlo '
                    'ahora mismo. Abre el inicio para ver cómo va.'
              : 'El ${fechaMinima(p.inicioGestion)}, diez días antes, '
                    'empezamos a gestionarlo. Te avisamos ese día.',
        ),
        _Paso(
          2,
          'Preguntamos a $eps si lo tiene. Si no, vemos cuánto cuesta en '
          'droguerías cerca.',
        ),
        const _Paso(
          3,
          'Te mostramos las opciones con precio y distancia para que elijas '
          'la que te sirva.',
        ),
        const _Paso(
          4,
          'Si no aparece en ningún lado, te lo decimos a tiempo y te ayudamos '
          'a reclamarlo.',
        ),
      ],
      pie: [
        Boton(
          'Agregar otro medicamento',
          estilo: EstiloBoton.secundario,
          icono: Icono.mas,
          alPulsar: () => context.pushReplacement('/formula/plan'),
        ),
        Boton('Ir al inicio', alPulsar: irAlInicio),
      ],
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso(this.n, this.texto);
  final int n;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radio,
              border: Border.all(color: Tinta.lineaFuerte),
            ),
            child: Text(
              '$n',
              style: Letra.secundario.tabular.copyWith(height: 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: Letra.cuerpo.copyWith(color: Tinta.suave),
            ),
          ),
        ],
      ),
    );
  }
}
