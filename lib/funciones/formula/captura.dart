import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/tema.dart';
import '../../datos/hogar.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/nota.dart';
import '../../nucleo/widgets/pantalla.dart';
import '../activacion/borrador.dart';

/// A-07. La captura la hace la cámara del teléfono: aquí solo se explica
/// cómo tomar la foto para que la fórmula se lea completa.
class CapturaFormula extends ConsumerStatefulWidget {
  const CapturaFormula({super.key});

  @override
  ConsumerState<CapturaFormula> createState() => _CapturaFormulaState();
}

class _CapturaFormulaState extends ConsumerState<CapturaFormula> {
  bool _sinPermiso = false;
  bool _abriendo = false;

  Future<void> _tomar(ImageSource fuente) async {
    if (_abriendo) return;
    setState(() {
      _abriendo = true;
      _sinPermiso = false;
    });
    try {
      final archivo = await ImagePicker().pickImage(
        source: fuente,
        imageQuality: 82,
        maxWidth: 1800,
      );
      if (archivo == null || !mounted) return;
      final bytes = await archivo.readAsBytes();
      ref.read(borradorProvider.notifier).foto(bytes);
      if (mounted) context.push('/formula/previa');
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code.contains('denied') || e.code.contains('permission')) {
        setState(() => _sinPermiso = true);
      }
    } finally {
      if (mounted) setState(() => _abriendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borrador = ref.watch(borradorProvider);
    final nombre =
        borrador.persona?.primerNombre ??
        ref.watch(hogarProvider).value?.personas.lastOrNull?.primerNombre;

    return Pantalla(
      contexto: nombre == null ? null : 'Fórmula de $nombre',
      hijos: [
        const Cabecera(
          'Toma una foto de la fórmula',
          bajada:
              'La necesitamos para que tengas a mano los datos mientras armas '
              'el plan, y para que nuestro equipo pueda revisarla.',
        ),
        const SizedBox(height: 24),
        const _GuiaEncuadre(),
        const SizedBox(height: 24),
        const ListaVistos([
          'Con buena luz y sin sombras sobre el papel.',
          'Que se vean el nombre de cada medicamento, la dosis y la firma.',
          'Si tiene más de una hoja, súbelas después como páginas aparte.',
        ]),
        if (_sinPermiso) ...[
          const SizedBox(height: 16),
          Nota(
            tono: TonoNota.aviso,
            titulo: 'Mimedica no tiene acceso a la cámara',
            texto:
                'Actívalo en los ajustes del teléfono, o sube una foto que '
                'ya tengas en la galería.',
            accion: BotonTexto(
              'Subir una foto de la galería',
              alPulsar: () => _tomar(ImageSource.gallery),
            ),
          ),
        ],
      ],
      pie: [
        Boton(
          _sinPermiso ? 'Intentar con la cámara otra vez' : 'Tomar la foto',
          icono: Icono.camara,
          ocupado: _abriendo,
          alPulsar: () => _tomar(ImageSource.camera),
        ),
        if (!_sinPermiso)
          Boton(
            'Subir una foto de la galería',
            icono: Icono.galeria,
            estilo: EstiloBoton.secundario,
            alPulsar: _abriendo ? null : () => _tomar(ImageSource.gallery),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Solo tú y nuestro equipo ven la foto. No se comparte con nadie '
            'más sin tu permiso.',
            textAlign: TextAlign.center,
            style: Letra.secundario,
          ),
        ),
      ],
    );
  }
}

class _GuiaEncuadre extends StatelessWidget {
  const _GuiaEncuadre();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ejemplo: la fórmula completa dentro del marco',
      image: true,
      child: AspectRatio(
        aspectRatio: 1.45,
        child: Container(
          decoration: const BoxDecoration(
            color: Tinta.tinta,
            borderRadius: radio,
          ),
          padding: const EdgeInsets.all(20),
          child: CustomPaint(painter: _Marco()),
        ),
      ),
    );
  }
}

class _Marco extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final papel = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * .12, 0, size.width * .76, size.height),
      const Radius.circular(2),
    );
    canvas.drawRRect(papel, Paint()..color = Tinta.papel);

    final linea = Paint()
      ..color = Tinta.lineaFuerte
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final x0 = papel.left + 16;
    final ancho = papel.width - 32;
    var y = 20.0;
    for (final f in [.55, 1.0, .8, 1.0, .7, 1.0, .9, .6]) {
      canvas.drawLine(Offset(x0, y), Offset(x0 + ancho * f, y), linea);
      y += size.height / 9.5;
    }

    final guia = Paint()
      ..color = Tinta.azulLinea
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const largo = 22.0;
    final r = papel.outerRect.inflate(-6);
    for (final (a, b, c) in [
      (r.topLeft, const Offset(largo, 0), const Offset(0, largo)),
      (r.topRight, const Offset(-largo, 0), const Offset(0, largo)),
      (r.bottomLeft, const Offset(largo, 0), const Offset(0, -largo)),
      (r.bottomRight, const Offset(-largo, 0), const Offset(0, -largo)),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(a.dx + b.dx, a.dy + b.dy)
          ..lineTo(a.dx, a.dy)
          ..lineTo(a.dx + c.dx, a.dy + c.dy),
        guia,
      );
    }
  }

  @override
  bool shouldRepaint(_Marco o) => false;
}
