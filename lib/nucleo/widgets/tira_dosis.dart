import 'package:flutter/material.dart';

import '../../app/tema.dart';

/// La tira de dosis: una marca por día. Azul mientras hay dosis de sobra,
/// ámbar durante los diez días de gestión y, después del agotamiento, verde
/// si la siguiente entrega está asegurada o gris corto si todavía no.
class TiraDosis extends StatefulWidget {
  const TiraDosis({
    super.key,
    required this.diasRestantes,
    this.fechaAgotamiento,
    this.asegurada = false,
    this.compacta = false,
    this.ventana = 10,
  });

  static const marcas = 40;
  static const diasPrevios = 4;

  final int diasRestantes;

  /// Texto corto bajo el marcador de agotamiento, p. ej. «3 oct».
  final String? fechaAgotamiento;
  final bool asegurada;
  final bool compacta;
  final int ventana;

  @override
  State<TiraDosis> createState() => _TiraDosisState();
}

class _TiraDosisState extends State<TiraDosis>
    with SingleTickerProviderStateMixin {
  late final _entrada = AnimationController(
    vsync: this,
    duration: Ritmo.pagina,
  );
  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrada.value = 1;
    } else {
      _entrada.forward();
    }
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  String get _descripcion {
    final dias = widget.diasRestantes;
    final quedan = dias <= 0
        ? 'Ya no quedan dosis'
        : 'Quedan $dias ${dias == 1 ? 'día' : 'días'} de dosis';
    final fecha = widget.fechaAgotamiento == null
        ? ''
        : '; se agota el ${widget.fechaAgotamiento}';
    final gestion = dias <= widget.ventana
        ? 'La gestión ya empezó.'
        : 'La gestión empieza ${widget.ventana} días antes.';
    final entrega = widget.asegurada
        ? 'La siguiente entrega ya está asegurada.'
        : 'La siguiente entrega todavía no está asegurada.';
    return '$quedan$fecha. $gestion $entrega';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: _descripcion,
      child: AnimatedBuilder(
        animation: _entrada,
        builder: (context, _) => CustomPaint(
          size: Size(double.infinity, widget.compacta ? 30 : 54),
          painter: _PintorTira(
            dias: widget.diasRestantes,
            ventana: widget.ventana,
            asegurada: widget.asegurada,
            compacta: widget.compacta,
            fecha: widget.fechaAgotamiento,
            avance: Ritmo.salida.transform(_entrada.value),
            escala: MediaQuery.textScalerOf(context),
          ),
        ),
      ),
    );
  }
}

class _PintorTira extends CustomPainter {
  _PintorTira({
    required this.dias,
    required this.ventana,
    required this.asegurada,
    required this.compacta,
    required this.fecha,
    required this.avance,
    required this.escala,
  });

  final int dias;
  final int ventana;
  final bool asegurada;
  final bool compacta;
  final String? fecha;
  final double avance;
  final TextScaler escala;

  @override
  void paint(Canvas canvas, Size size) {
    const n = TiraDosis.marcas;
    const hoy = TiraDosis.diasPrevios;
    final paso = size.width / n;
    final eje = compacta ? 14.0 : 26.0;
    double x(int i) => paso * i + paso / 2;

    canvas.drawLine(
      Offset(0, eje),
      Offset(size.width, eje),
      Paint()
        ..color = Tinta.lineaFuerte
        ..strokeWidth = 1,
    );

    final agotamiento = hoy + dias.clamp(-hoy, n);
    final inicioGestion = agotamiento - ventana;
    final visibles = (n * avance).ceil();

    for (var i = 0; i < visibles; i++) {
      final Color color;
      var alto = 8.0;
      if (i >= agotamiento) {
        if (asegurada) {
          color = Tinta.ok;
        } else {
          color = Tinta.tenue;
          alto = 4;
        }
      } else if (i >= inicioGestion) {
        color = Tinta.espera;
      } else {
        color = Tinta.azul;
      }
      final pasada = i < hoy && i < agotamiento;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x(i), eje), width: 1.6, height: alto),
        Paint()..color = pasada ? color.withValues(alpha: 0.62) : color,
      );
    }

    if (avance < 1) return;

    final arriba = eje - 13;
    final abajo = eje + 9;

    if (inicioGestion >= 0 && inicioGestion < n) {
      final px = x(inicioGestion);
      final trazo = Paint()
        ..color = Tinta.espera
        ..strokeWidth = 1;
      for (var y = arriba; y < abajo; y += 4) {
        canvas.drawLine(Offset(px, y), Offset(px, y + 2), trazo);
      }
      if (!compacta) {
        _texto(
          canvas,
          'D-10',
          Offset(px, 0),
          size.width,
          Letra.rotulo.copyWith(color: Tinta.espera, letterSpacing: 0.66),
        );
      }
    }

    final agotamientoVisible = agotamiento >= 0 && agotamiento < n;
    if (agotamientoVisible) {
      final px = x(agotamiento);
      canvas.drawLine(
        Offset(px, arriba),
        Offset(px, abajo),
        Paint()
          ..color = Tinta.tinta
          ..strokeWidth = 1.25,
      );
    }

    if (compacta) return;

    final hx = x(hoy);
    canvas.drawPath(
      Path()
        ..moveTo(hx, eje + 7)
        ..lineTo(hx - 3, eje + 11.5)
        ..lineTo(hx + 3, eje + 11.5)
        ..close(),
      Paint()..color = Tinta.tinta,
    );

    final base = Letra.secundario.copyWith(fontSize: 12, height: 1).tabular;
    final pie = Offset(0, eje + 15);
    final cercaDeHoy = agotamientoVisible && (agotamiento - hoy).abs() < 5;
    if (!cercaDeHoy || fecha == null) {
      _texto(canvas, 'hoy', pie.translate(hx, 0), size.width, base);
    }
    if (agotamientoVisible && fecha != null) {
      _texto(
        canvas,
        fecha!,
        pie.translate(x(agotamiento), 0),
        size.width,
        base.copyWith(color: Tinta.tinta, fontWeight: FontWeight.w500),
      );
    }
  }

  void _texto(
    Canvas canvas,
    String texto,
    Offset centro,
    double ancho,
    TextStyle estilo,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: texto, style: estilo),
      textDirection: TextDirection.ltr,
      textScaler: escala.clamp(maxScaleFactor: 1.3),
    )..layout();
    final dx = (centro.dx - tp.width / 2).clamp(0.0, ancho - tp.width);
    tp.paint(canvas, Offset(dx, centro.dy));
  }

  @override
  bool shouldRepaint(_PintorTira o) =>
      o.dias != dias ||
      o.asegurada != asegurada ||
      o.avance != avance ||
      o.fecha != fecha ||
      o.compacta != compacta;
}
