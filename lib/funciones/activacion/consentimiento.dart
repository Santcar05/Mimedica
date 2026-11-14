import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tema.dart';
import '../../datos/hogar.dart';
import '../../datos/repositorio.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/controles.dart';
import '../../nucleo/widgets/nota.dart';
import '../../nucleo/widgets/pantalla.dart';
import '../ingreso/documento_legal.dart';

/// Dos autorizaciones separadas: la del servicio es necesaria; la estadística
/// es opcional, llega apagada y rechazarla no bloquea nada.
class Consentimiento extends ConsumerStatefulWidget {
  const Consentimiento({super.key});

  @override
  ConsumerState<Consentimiento> createState() => _ConsentimientoState();
}

class _ConsentimientoState extends ConsumerState<Consentimiento> {
  bool _estadistica = false;
  bool _guardando = false;
  String? _error;

  Future<void> _autorizar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref
          .read(hogarProvider.notifier)
          .autorizar(estadistica: _estadistica);
      if (mounted) context.go('/activacion/quien');
    } on Fallo catch (fallo) {
      if (mounted) setState(() => _error = fallo.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Pantalla(
      conVolver: false,
      hijos: [
        const Cabecera(
          'Antes de leer la fórmula, necesitamos tu permiso',
          bajada:
              'Una fórmula dice qué enfermedad tratas. La ley la considera un '
              'dato sensible, así que te contamos qué hacemos con ella.',
        ),
        const SizedBox(height: 16),
        const ListaVistos([
          'La usamos para armar el plan y calcular cuándo se acaba cada '
              'medicamento.',
          'Se la mostramos solo a tu EPS y a la droguería que tú elijas.',
          'No la vendemos ni la usamos para publicidad.',
        ]),
        const SizedBox(height: 12),
        const Interruptor(
          titulo: 'Usar mis datos para prestar el servicio',
          etiqueta: 'Necesaria',
          detalle: 'Sin esto no podemos calcular fechas ni consultar a tu EPS.',
          valor: true,
          fijo: true,
        ),
        const Separador(),
        Interruptor(
          titulo: 'Usarlos sin mi nombre para estadísticas',
          etiqueta: 'Opcional',
          detalle:
              'Nos ayuda a medir qué medicamentos faltan en Bogotá. Si la '
              'dejas apagada, el servicio funciona igual.',
          valor: _estadistica,
          alCambiar: (v) => setState(() => _estadistica = v),
        ),
        const SizedBox(height: 4),
        BotonTexto(
          'Leer la política de datos completa',
          alPulsar: () => abrirDocumento(context, Legal.datos),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Nota(texto: _error!, tono: TonoNota.riesgo),
        ],
      ],
      pie: [
        Boton(
          'Autorizar y subir la fórmula',
          ocupado: _guardando,
          alPulsar: _autorizar,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Puedes revocar ambas en Cuenta › Privacidad.',
            textAlign: TextAlign.center,
            style: Letra.secundario,
          ),
        ),
      ],
    );
  }
}
