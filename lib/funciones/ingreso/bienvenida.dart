import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tema.dart';
import '../../datos/formato.dart';
import '../../datos/hogar.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/pantalla.dart';
import '../../nucleo/widgets/tira_dosis.dart';
import 'logo.dart';

class Bienvenida extends ConsumerWidget {
  const Bienvenida({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agotamiento = ref.watch(hoyProvider).add(const Duration(days: 10));

    return Pantalla(
      conVolver: false,
      hijos: [
        const Row(
          children: [
            Logo(),
            SizedBox(width: 10),
            Text('Mimedica', style: Letra.seccion),
          ],
        ),
        const SizedBox(height: 40),
        Text(
          'Por ejemplo: Losartán 50 mg · se acaba el ${fechaCorta(agotamiento)}',
          style: Letra.secundario.tabular,
        ),
        const SizedBox(height: 10),
        TiraDosis(
          diasRestantes: 10,
          fechaAgotamiento: fechaMinima(agotamiento),
          asegurada: true,
        ),
        const SizedBox(height: 8),
        const ExcludeSemantics(
          child: Opacity(
            opacity: 0.55,
            child: Column(
              children: [
                TiraDosis(diasRestantes: 22, compacta: true),
                TiraDosis(diasRestantes: 16, compacta: true, asegurada: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Semantics(
          header: true,
          child: const Text(
            'Sabemos cuándo se acaba tu medicamento y empezamos a '
            'conseguirlo 10 días antes.',
            style: Letra.display,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Subes la fórmula una vez. Consultamos a tu EPS y, si no te lo '
          'entrega, te mostramos dónde está y cuánto cuesta.',
          style: Letra.cuerpo.copyWith(color: Tinta.suave),
        ),
      ],
      pie: [
        Boton(
          'Empezar',
          iconoAlFinal: Icono.flecha,
          alPulsar: () => context.push('/ingreso'),
        ),
        Boton(
          'Ya tengo cuenta',
          estilo: EstiloBoton.secundario,
          alPulsar: () => context.push('/ingreso'),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Gestionamos la continuidad; no garantizamos que el medicamento '
            'siempre aparezca.',
            textAlign: TextAlign.center,
            style: Letra.secundario,
          ),
        ),
      ],
    );
  }
}
