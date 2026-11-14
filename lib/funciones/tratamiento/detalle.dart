import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tema.dart';
import '../../datos/formato.dart';
import '../../datos/hogar.dart';
import '../../datos/modelos.dart';
import '../../datos/repositorio.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/campo.dart';
import '../../nucleo/widgets/estado_visual.dart';
import '../../nucleo/widgets/filas.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/nota.dart';
import '../../nucleo/widgets/pantalla.dart';
import '../../nucleo/widgets/tira_dosis.dart';
import '../inicio/inicio.dart';
import 'visor_formula.dart';

/// B-02: todo lo que se sabe de un tratamiento.
class DetalleTratamiento extends ConsumerWidget {
  const DetalleTratamiento({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hogar = ref.watch(hogarProvider).value;
    final t = hogar?.tratamiento(id);
    if (hogar == null || t == null) return const Pantalla(hijos: []);

    final v = vistasDe(
      hogar,
      ref.watch(hoyProvider),
    ).firstWhere((v) => v.t.id == id);
    final p = v.proyeccion;
    final ciclos = hogar.ciclosDe(id);

    Future<void> pausar() async {
      try {
        await ref
            .read(hogarProvider.notifier)
            .guardarTratamiento(t.con(pausado: !t.pausado));
      } on Fallo catch (f) {
        if (context.mounted) _aviso(context, f.mensaje);
      }
    }

    Future<void> eliminar() async {
      final seguro = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Eliminar ${t.titulo}?', style: Letra.seccion),
          content: const Text(
            'Dejaremos de calcular su fecha y de avisarte. Esto no se puede '
            'deshacer.',
            style: Letra.cuerpo,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Tinta.riesgo),
              ),
            ),
          ],
        ),
      );
      if (seguro != true) return;
      try {
        await ref.read(hogarProvider.notifier).eliminarTratamiento(id);
        if (context.mounted) context.go('/inicio');
      } on Fallo catch (f) {
        if (context.mounted) _aviso(context, f.mensaje);
      }
    }

    return Pantalla(
      accion: BotonTexto(
        'Editar',
        icono: Icono.lapiz,
        alPulsar: () => context.push('/tratamiento/$id/editar'),
      ),
      hijos: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(t.titulo, style: Letra.titulo),
              ),
            ),
            SelloDeTratamiento(v.estado),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${v.persona?.nombre ?? ''} · ${t.posologia}',
          style: Letra.secundario,
        ),
        const SizedBox(height: 20),
        TiraDosis(
          diasRestantes: p.diasRestantes,
          fechaAgotamiento: fechaMinima(p.agotamiento),
          asegurada: v.asegurada,
        ),
        const SizedBox(height: 8),
        Dato(
          'Se acaba',
          '${fechaCorta(p.agotamiento)} · ${enCuanto(p.diasRestantes)}',
        ),
        const Separador(),
        if (t.vigenciaHasta != null) ...[
          Dato('Fórmula vigente hasta', fechaConAnio(t.vigenciaHasta!)),
          const Separador(),
        ],
        if (v.persona?.eps != null) ...[
          Dato('EPS', v.persona!.eps!),
          const Separador(),
        ],
        Dato('En casa hoy', _unidades(t, p.enCasaHoy)),
        if (v.formulaVencida) ...[
          const SizedBox(height: 20),
          Nota(
            tono: TonoNota.aviso,
            titulo: '${t.nombre} necesita una fórmula nueva',
            texto: v.contexto,
            accion: BotonTexto(
              'Subir la fórmula nueva',
              icono: Icono.camara,
              alPulsar: () => context.push('/tratamiento/nuevo'),
            ),
          ),
        ] else if (v.ciclo != null && v.ciclo!.enCurso) ...[
          const SizedBox(height: 20),
          Nota(
            titulo: 'Ciclo de ${mes(v.ciclo!.abiertoEl)} en gestión',
            texto: v.contexto,
            accion: BotonTexto(
              v.opciones.isEmpty ? 'Ver cómo va' : 'Ver mis opciones',
              alPulsar: () => context.push('/ciclo/${v.ciclo!.id}'),
            ),
          ),
        ],
        if (ciclos.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Rotulo('Ciclos'),
          const SizedBox(height: 4),
          for (final c in ciclos) _FilaCiclo(c),
        ],
        if (t.fotoFormula != null) ...[
          const SizedBox(height: 12),
          FilaEnlace(
            'Ver la fórmula',
            icono: Icono.documento,
            alPulsar: () => verFormula(context, t.fotoFormula!),
          ),
        ],
        const SizedBox(height: 12),
        FilaEnlace(
          t.pausado ? 'Reanudar el tratamiento' : 'Pausar el tratamiento',
          icono: t.pausado ? Icono.reanudar : Icono.pausa,
          conFlecha: false,
          alPulsar: pausar,
        ),
        FilaEnlace(
          'Eliminar el tratamiento',
          icono: Icono.papelera,
          color: Tinta.riesgo,
          conFlecha: false,
          alPulsar: eliminar,
        ),
      ],
      pie: [
        Boton(
          'Marcar entrega recibida',
          icono: Icono.caja,
          alPulsar: () => context.push('/entrega/$id'),
        ),
      ],
    );
  }

  String _unidades(Tratamiento t, double n) =>
      t.presentacion.contar(double.parse(n.toStringAsFixed(1)));

  void _aviso(BuildContext context, String texto) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(texto)));
}

class _FilaCiclo extends StatelessWidget {
  const _FilaCiclo(this.ciclo);
  final Ciclo ciclo;

  @override
  Widget build(BuildContext context) {
    final c = ciclo;
    final cerrado = c.estado == EstadoCiclo.cerrado;
    final como = cerrado
        ? '${c.origen?.rotulo ?? 'Entrega'}${c.punto == null ? '' : ': ${c.punto}'}'
              ' · ${cantidad(c.cantidad ?? 0)} recibidas el ${fechaMinima(c.cerradoEl ?? c.abiertoEl)}'
        : c.estado == EstadoCiclo.asegurado
        ? 'Entrega asegurada'
        : 'Abierto el ${fechaMinima(c.abiertoEl)}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Tinta.linea)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              mayusculaInicial(mes(c.abiertoEl).substring(0, 3)),
              style: Letra.cuerpoFuerte,
            ),
          ),
          Expanded(
            child: Text(
              como,
              style: Letra.secundario.copyWith(color: Tinta.suave),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            cerrado
                ? 'Cerrado'
                : c.estado == EstadoCiclo.asegurado
                ? 'Asegurado'
                : 'Abierto',
            style: Letra.secundario.copyWith(
              color: cerrado ? Tinta.ok : Tinta.espera,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
