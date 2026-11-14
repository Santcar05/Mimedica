import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tema.dart';
import '../../datos/hogar.dart';
import '../../datos/repositorio.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/nota.dart';
import '../../nucleo/widgets/pantalla.dart';
import '../activacion/borrador.dart';

/// A-08: comprobar que la foto se lee antes de guardarla.
class Previsualizacion extends ConsumerStatefulWidget {
  const Previsualizacion({super.key});

  @override
  ConsumerState<Previsualizacion> createState() => _PrevisualizacionState();
}

class _PrevisualizacionState extends ConsumerState<Previsualizacion> {
  bool _subiendo = false;
  Fallo? _fallo;

  Future<void> _usar() async {
    final foto = ref.read(borradorProvider).foto;
    if (foto == null) return;
    setState(() {
      _subiendo = true;
      _fallo = null;
    });
    try {
      final ruta = await ref.read(hogarProvider.notifier).subirFormula(foto);
      ref.read(borradorProvider.notifier).guardada(ruta);
      if (mounted) context.pushReplacement('/formula/plan');
    } on Fallo catch (fallo) {
      if (mounted) setState(() => _fallo = fallo);
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foto = ref.watch(borradorProvider).foto;

    return Pantalla(
      contexto: 'Página 1 de 1',
      hijos: [
        const Cabecera(
          '¿Se lee todo?',
          bajada:
              'Revisa que se vean el nombre de cada medicamento, la dosis y la '
              'firma.',
        ),
        const SizedBox(height: 20),
        if (foto != null)
          Semantics(
            image: true,
            label: 'Foto de la fórmula',
            child: Container(
              constraints: const BoxConstraints(maxHeight: 420),
              decoration: BoxDecoration(
                color: Tinta.superficie,
                borderRadius: radio,
                border: Border.all(color: Tinta.linea),
              ),
              child: ClipRRect(
                borderRadius: radio,
                child: Image.memory(foto, fit: BoxFit.contain),
              ),
            ),
          ),
        if (_fallo != null) ...[
          const SizedBox(height: 16),
          Nota(
            tono: TonoNota.riesgo,
            titulo: _fallo!.sinRed ? 'No hay conexión' : 'No se pudo guardar',
            texto: _fallo!.mensaje,
          ),
        ],
      ],
      pie: [
        Boton(
          _fallo == null ? 'Usar esta foto' : 'Intentar de nuevo',
          ocupado: _subiendo,
          alPulsar: _usar,
        ),
        Boton(
          'Tomar otra vez',
          icono: Icono.camara,
          estilo: EstiloBoton.secundario,
          alPulsar: _subiendo ? null : () => context.pop(),
        ),
      ],
    );
  }
}
