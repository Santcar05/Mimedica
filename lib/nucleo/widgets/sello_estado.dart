import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/tema.dart';

enum TonoEstado { ok, espera, riesgo, neutro }

/// Estado de un tratamiento: color, forma y texto, nunca solo color.
class SelloEstado extends StatelessWidget {
  const SelloEstado(this.texto, {super.key, required this.tono});
  final String texto;
  final TonoEstado tono;

  Color get _color => switch (tono) {
    TonoEstado.ok => Tinta.ok,
    TonoEstado.espera => Tinta.espera,
    TonoEstado.riesgo => Tinta.riesgo,
    TonoEstado.neutro => Tinta.apagada,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: const Size(12, 12), painter: _Punto(tono, _color)),
        const SizedBox(width: 6),
        Text(
          texto,
          style: Letra.secundario.copyWith(
            color: _color,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _Punto extends CustomPainter {
  _Punto(this.tono, this.color);
  final TonoEstado tono;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    const r = 5.0;
    final linea = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final relleno = Paint()..color = color;
    final caja = Rect.fromCircle(center: centro, radius: r);

    switch (tono) {
      case TonoEstado.ok:
        canvas.drawCircle(centro, r, relleno);
      case TonoEstado.espera:
        canvas.drawCircle(centro, r, linea);
        canvas.drawArc(caja, -math.pi / 2, math.pi, true, relleno);
      case TonoEstado.riesgo:
        const tramos = 6;
        const paso = 2 * math.pi / tramos;
        for (var i = 0; i < tramos; i++) {
          canvas.drawArc(caja, i * paso, paso * 0.55, false, linea);
        }
      case TonoEstado.neutro:
        canvas.drawCircle(centro, r, linea);
    }
  }

  @override
  bool shouldRepaint(_Punto o) => o.tono != tono || o.color != color;
}
