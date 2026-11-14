import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tema.dart';
import '../../datos/hogar.dart';
import '../../nucleo/widgets/icono.dart';

/// Marco de las tres pestañas: Inicio, Pendientes y Cuenta.
class Cascaron extends ConsumerWidget {
  const Cascaron({super.key, required this.pestanas});
  final StatefulNavigationShell pestanas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendientes = ref.watch(
      hogarProvider.select((h) => h.value?.pendientes.length ?? 0),
    );

    return Scaffold(
      body: pestanas,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 56,
          decoration: const BoxDecoration(
            color: Tinta.papel,
            border: Border(top: BorderSide(color: Tinta.linea)),
          ),
          child: Row(
            children: [
              for (final (i, p) in [
                (Icono.inicio, 'Inicio', 0),
                (Icono.pendientes, 'Pendientes', pendientes),
                (Icono.persona, 'Cuenta', 0),
              ].indexed)
                Expanded(
                  child: _Pestana(
                    icono: p.$1,
                    texto: p.$2,
                    avisos: p.$3,
                    activa: pestanas.currentIndex == i,
                    alPulsar: () => pestanas.goBranch(
                      i,
                      initialLocation: i == pestanas.currentIndex,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pestana extends StatelessWidget {
  const _Pestana({
    required this.icono,
    required this.texto,
    required this.avisos,
    required this.activa,
    required this.alPulsar,
  });

  final Icono icono;
  final String texto;
  final int avisos;
  final bool activa;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    final color = activa ? Tinta.azul : Tinta.apagada;
    return Semantics(
      button: true,
      selected: activa,
      label: avisos > 0 ? '$texto, $avisos' : texto,
      excludeSemantics: true,
      child: InkWell(
        onTap: alPulsar,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (activa)
              const Positioned(
                top: 0,
                child: SizedBox(
                  width: 24,
                  height: 2,
                  child: ColoredBox(color: Tinta.azul),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Trazo(icono, tam: 22, color: color),
                const SizedBox(height: 3),
                Text(
                  texto,
                  style: Letra.rotulo.copyWith(
                    color: color,
                    letterSpacing: 0.2,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (avisos > 0)
              Positioned(
                top: 5,
                left: MediaQuery.sizeOf(context).width / 6 + 8,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Tinta.riesgo,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '$avisos',
                    style: Letra.rotulo.copyWith(
                      color: Tinta.papel,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
