import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tema.dart';
import '../../datos/formato.dart';
import '../../datos/hogar.dart';
import '../../datos/modelos.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/pantalla.dart';
import '../estados/estados.dart';

/// D-02: lo que la EPS no entregó, con fecha y punto. Es la evidencia para
/// reclamar si el faltante se repite.
class Pendientes extends ConsumerWidget {
  const Pendientes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hogar = ref.watch(hogarProvider);
    return hogar.when(
      loading: () => const EstadoCargando(),
      error: (e, _) =>
          EstadoError(e, alReintentar: () => ref.invalidate(hogarProvider)),
      data: (h) {
        final lista = [...h.pendientes]
          ..sort((a, b) => b.fecha.compareTo(a.fecha));

        return Pantalla(
          conVolver: false,
          accion: lista.isEmpty
              ? null
              : BotonTexto(
                  'Registrar',
                  icono: Icono.mas,
                  alPulsar: () => context.push('/pendientes/nuevo'),
                ),
          hijos: [
            const Cabecera(
              'Pendientes',
              bajada:
                  'Cada vez que la EPS no te entregue algo completo, '
                  'regístralo aquí. Con fecha y punto, es la prueba para '
                  'reclamar.',
            ),
            const SizedBox(height: 24),
            if (lista.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Tinta.papelHondo,
                  borderRadius: radio,
                  border: Border.all(color: Tinta.linea),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No tienes pendientes registrados',
                      style: Letra.seccion,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Qué bueno. Si algún día te dicen «está pendiente», '
                      'anótalo aquí en un minuto.',
                      style: Letra.cuerpo.copyWith(color: Tinta.suave),
                    ),
                    const SizedBox(height: 16),
                    Boton(
                      'Registrar un pendiente',
                      ancho: false,
                      estilo: EstiloBoton.secundario,
                      alPulsar: () => context.push('/pendientes/nuevo'),
                    ),
                  ],
                ),
              )
            else
              for (final (i, p) in lista.indexed) ...[
                if (i > 0) const Separador(),
                _FilaPendiente(pendiente: p, hogar: h),
              ],
          ],
        );
      },
    );
  }
}

class _FilaPendiente extends StatelessWidget {
  const _FilaPendiente({required this.pendiente, required this.hogar});
  final Pendiente pendiente;
  final Hogar hogar;

  @override
  Widget build(BuildContext context) {
    final p = pendiente;
    final t = hogar.tratamiento(p.tratamientoId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(t?.titulo ?? 'Medicamento', style: Letra.seccion),
              ),
              Text(fechaCorta(p.fecha), style: Letra.secundario.tabular),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              p.punto,
              if (p.faltante != null)
                'faltaron ${cantidad(p.faltante!)} '
                    '${t?.presentacion.plural ?? 'unidades'}',
            ].join(' · '),
            style: Letra.secundario,
          ),
          if (p.nota != null && p.nota!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '«${p.nota}»',
              style: Letra.cuerpo.copyWith(color: Tinta.suave),
            ),
          ],
        ],
      ),
    );
  }
}
