import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/tema.dart';
import 'icono.dart';

class Rotulo extends StatelessWidget {
  const Rotulo(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) =>
      Text(texto.toUpperCase(), style: Letra.rotulo);
}

/// Caja de 48 px con rótulo, ayuda y un error que dice qué hacer.
class Campo extends StatefulWidget {
  const Campo({
    super.key,
    required this.rotulo,
    this.controlador,
    this.ayuda,
    this.error,
    this.prefijo,
    this.sufijo,
    this.pista,
    this.teclado,
    this.formato,
    this.alCambiar,
    this.alEnviar,
    this.accion,
    this.autofoco = false,
    this.mayusculas = TextCapitalization.none,
    this.autocompletar,
  });

  final String rotulo;
  final TextEditingController? controlador;
  final String? ayuda;
  final String? error;
  final String? prefijo;
  final String? sufijo;
  final String? pista;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formato;
  final ValueChanged<String>? alCambiar;
  final ValueChanged<String>? alEnviar;
  final TextInputAction? accion;
  final bool autofoco;
  final TextCapitalization mayusculas;
  final Iterable<String>? autocompletar;

  @override
  State<Campo> createState() => _CampoState();
}

class _CampoState extends State<Campo> {
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _foco.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conError = widget.error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Rotulo(widget.rotulo),
        const SizedBox(height: 8),
        CajaCampo(
          enfocada: _foco.hasFocus,
          conError: conError,
          child: Row(
            children: [
              if (widget.prefijo != null) _Adorno(widget.prefijo!, inicio: true),
              Expanded(
                child: TextField(
                  controller: widget.controlador,
                  focusNode: _foco,
                  autofocus: widget.autofoco,
                  keyboardType: widget.teclado,
                  inputFormatters: widget.formato,
                  textInputAction: widget.accion,
                  textCapitalization: widget.mayusculas,
                  autofillHints: widget.autocompletar,
                  onChanged: widget.alCambiar,
                  onSubmitted: widget.alEnviar,
                  style: Letra.entrada,
                  cursorWidth: 1.5,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.pista,
                    hintStyle: Letra.entrada.copyWith(color: Tinta.apagada),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    semanticCounterText: '',
                  ),
                ),
              ),
              if (widget.sufijo != null) _Adorno(widget.sufijo!, inicio: false),
            ],
          ),
        ),
        if (conError)
          MensajeError(widget.error!)
        else if (widget.ayuda != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(widget.ayuda!, style: Letra.secundario),
          ),
      ],
    );
  }
}

class CajaCampo extends StatelessWidget {
  const CajaCampo({
    super.key,
    required this.child,
    this.enfocada = false,
    this.conError = false,
  });

  final Widget child;
  final bool enfocada;
  final bool conError;

  @override
  Widget build(BuildContext context) {
    final color = conError
        ? Tinta.riesgo
        : enfocada
        ? Tinta.azul
        : Tinta.tenue;
    final grueso = conError || enfocada ? 2.0 : 1.0;
    return AnimatedContainer(
      duration: Ritmo.micro,
      curve: Ritmo.salida,
      constraints: const BoxConstraints(minHeight: 48),
      // El borde crece hacia dentro para que la caja no salte al enfocar.
      padding: EdgeInsets.all(2 - grueso),
      decoration: BoxDecoration(
        color: Tinta.papel,
        borderRadius: radio,
        border: Border.all(color: color, width: grueso),
      ),
      child: child,
    );
  }
}

class _Adorno extends StatelessWidget {
  const _Adorno(this.texto, {required this.inicio});
  final String texto;
  final bool inicio;

  @override
  Widget build(BuildContext context) {
    const lado = BorderSide(color: Tinta.linea);
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: EdgeInsets.fromLTRB(inicio ? 14 : 12, 0, inicio ? 12 : 14, 0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          right: inicio ? lado : BorderSide.none,
          left: inicio ? BorderSide.none : lado,
        ),
      ),
      child: Text(
        texto,
        style: inicio
            ? Letra.entrada.copyWith(color: Tinta.suave)
            : Letra.secundario,
      ),
    );
  }
}

class MensajeError extends StatelessWidget {
  const MensajeError(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Trazo(Icono.alerta, tam: 16, color: Tinta.riesgo),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                texto,
                style: Letra.secundario.copyWith(
                  color: Tinta.riesgo,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo que abre una selección (lista o fecha) en vez de teclado.
class CampoSelector extends StatelessWidget {
  const CampoSelector({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.alPulsar,
    this.pista,
    this.ayuda,
    this.error,
    this.icono = Icono.abajo,
  });

  final String rotulo;
  final String? valor;
  final String? pista;
  final String? ayuda;
  final String? error;
  final VoidCallback alPulsar;
  final Icono icono;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Rotulo(rotulo),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: '$rotulo: ${valor ?? pista ?? 'sin elegir'}',
          excludeSemantics: true,
          child: InkWell(
            onTap: alPulsar,
            borderRadius: radio,
            child: CajaCampo(
              conError: error != null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        valor ?? pista ?? '',
                        style: Letra.entrada.copyWith(
                          color: valor == null ? Tinta.apagada : Tinta.tinta,
                        ),
                      ),
                    ),
                    Trazo(icono, tam: 20, color: Tinta.apagada),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (error != null)
          MensajeError(error!)
        else if (ayuda != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(ayuda!, style: Letra.secundario),
          ),
      ],
    );
  }
}
