import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'icono.dart';

enum EstiloBoton { primario, secundario, peligro, peligroSuave }

class Boton extends StatefulWidget {
  const Boton(
    this.texto, {
    super.key,
    required this.alPulsar,
    this.estilo = EstiloBoton.primario,
    this.icono,
    this.iconoAlFinal,
    this.ocupado = false,
    this.ancho = true,
  });

  final String texto;
  final VoidCallback? alPulsar;
  final EstiloBoton estilo;
  final Icono? icono;
  final Icono? iconoAlFinal;
  final bool ocupado;
  final bool ancho;

  @override
  State<Boton> createState() => _BotonState();
}

class _BotonState extends State<Boton> {
  bool _hundido = false;

  bool get _activo => widget.alPulsar != null && !widget.ocupado;

  /// Un botón se reconoce de lejos: el principal es azul macizo con un borde
  /// inferior que lo hace parecer pulsable; el secundario, azul claro con
  /// contorno azul. El deshabilitado se ve apagado, no desaparece.
  (Color fondo, Color texto, Color borde) get _colores {
    if (widget.alPulsar == null) {
      return (Tinta.superficie, Tinta.apagada, Tinta.linea);
    }
    return switch (widget.estilo) {
      EstiloBoton.primario => (
        _hundido ? Tinta.azulHondo : Tinta.azul,
        Colors.white,
        _hundido ? Tinta.azulHondo : Tinta.azul,
      ),
      EstiloBoton.secundario => (
        _hundido ? Tinta.azulLinea : Tinta.azulSuave,
        Tinta.azulHondo,
        Tinta.azul,
      ),
      EstiloBoton.peligro => (
        _hundido ? const Color(0xFF8E2A24) : Tinta.riesgo,
        Colors.white,
        _hundido ? const Color(0xFF8E2A24) : Tinta.riesgo,
      ),
      EstiloBoton.peligroSuave => (
        _hundido ? const Color(0xFFF1CFCB) : Tinta.riesgoSuave,
        Tinta.riesgo,
        Tinta.riesgo,
      ),
    };
  }

  bool get _conRelieve =>
      widget.alPulsar != null &&
      (widget.estilo == EstiloBoton.primario ||
          widget.estilo == EstiloBoton.peligro);

  void _hundir(bool valor) {
    if (_activo && _hundido != valor) setState(() => _hundido = valor);
  }

  @override
  Widget build(BuildContext context) {
    final (fondo, texto, borde) = _colores;

    final contenido = Row(
      mainAxisSize: widget.ancho ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.ocupado)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: texto),
          )
        else if (widget.icono != null)
          Trazo(widget.icono!, tam: 20, color: texto),
        if (widget.ocupado || widget.icono != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Letra.cuerpoFuerte.copyWith(
              color: texto,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (widget.iconoAlFinal != null) ...[
          const SizedBox(width: 8),
          Trazo(widget.iconoAlFinal!, tam: 20, color: texto),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: _activo,
      label: widget.ocupado ? '${widget.texto}, en curso' : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _hundir(true),
        onTapCancel: () => _hundir(false),
        onTapUp: (_) => _hundir(false),
        onTap: _activo ? widget.alPulsar : null,
        child: AnimatedScale(
          scale: _hundido ? 0.985 : 1,
          duration: Ritmo.micro,
          curve: Ritmo.salida,
          child: AnimatedContainer(
            duration: Ritmo.micro,
            curve: Ritmo.salida,
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: radioBoton,
              border: Border.all(
                color: borde,
                width:
                    widget.estilo == EstiloBoton.secundario ||
                        widget.estilo == EstiloBoton.peligroSuave
                    ? 1.5
                    : 1,
              ),
              boxShadow: _conRelieve
                  ? [
                      BoxShadow(
                        color: widget.estilo == EstiloBoton.peligro
                            ? const Color(0xFF8E2A24)
                            : Tinta.azulHondo,
                        offset: Offset(0, _hundido ? 0 : 3),
                      ),
                    ]
                  : null,
            ),
            alignment: widget.ancho ? Alignment.center : null,
            child: contenido,
          ),
        ),
      ),
    );
  }
}

/// Botón de solo texto, azul, para acciones secundarias dentro del contenido.
class BotonTexto extends StatelessWidget {
  const BotonTexto(
    this.texto, {
    super.key,
    required this.alPulsar,
    this.icono,
    this.color = Tinta.azul,
  });

  final String texto;
  final VoidCallback? alPulsar;
  final Icono? icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tinta = alPulsar == null ? Tinta.apagada : color;
    return Semantics(
      button: true,
      enabled: alPulsar != null,
      child: InkWell(
        onTap: alPulsar,
        borderRadius: radio,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icono != null) ...[
                Trazo(icono!, tam: 20, color: tinta),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  texto,
                  style: Letra.cuerpoFuerte.copyWith(
                    color: tinta,
                    fontWeight: FontWeight.w600,
                    decoration: alPulsar == null
                        ? TextDecoration.none
                        : TextDecoration.underline,
                    decorationColor: Tinta.azulLinea,
                    decorationThickness: 1.5,
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

class BotonIcono extends StatelessWidget {
  const BotonIcono(
    this.icono, {
    super.key,
    required this.etiqueta,
    required this.alPulsar,
    this.color,
  });

  final Icono icono;
  final String etiqueta;
  final VoidCallback? alPulsar;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: etiqueta,
      child: InkWell(
        onTap: alPulsar,
        borderRadius: radio,
        highlightColor: Tinta.superficie,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: Trazo(icono, color: color ?? Tinta.tinta)),
        ),
      ),
    );
  }
}
