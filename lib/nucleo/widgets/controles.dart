import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'icono.dart';

class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, this.azul = false});
  final String texto;
  final bool azul;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 3),
      decoration: BoxDecoration(
        color: azul ? Tinta.azulSuave : null,
        borderRadius: radio,
        border: Border.all(color: azul ? Tinta.azulLinea : Tinta.lineaFuerte),
      ),
      child: Text(
        texto.toUpperCase(),
        style: Letra.rotulo.copyWith(color: azul ? Tinta.azul : Tinta.suave),
      ),
    );
  }
}

/// Interruptor cuadrado del sistema. Si [fijo] es verdadero se muestra
/// encendido y no se puede cambiar (autorización necesaria).
class Interruptor extends StatelessWidget {
  const Interruptor({
    super.key,
    required this.titulo,
    required this.detalle,
    required this.valor,
    this.alCambiar,
    this.etiqueta,
    this.fijo = false,
  });

  final String titulo;
  final String detalle;
  final bool valor;
  final ValueChanged<bool>? alCambiar;
  final String? etiqueta;
  final bool fijo;

  @override
  Widget build(BuildContext context) {
    final encendido = valor || fijo;
    final fondo = !encendido
        ? Tinta.papel
        : fijo
        ? Tinta.azulHondo
        : Tinta.azul;

    return MergeSemantics(
      child: Semantics(
        toggled: encendido,
        enabled: !fijo,
        child: InkWell(
          onTap: fijo || alCambiar == null ? null : () => alCambiar!(!valor),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(titulo, style: Letra.cuerpoFuerte),
                          if (etiqueta != null) Etiqueta(etiqueta!),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detalle,
                        style: Letra.secundario.copyWith(color: Tinta.suave),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                AnimatedContainer(
                  duration: Ritmo.ui,
                  curve: Ritmo.entraSale,
                  width: 44,
                  height: 26,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: fondo,
                    borderRadius: radio,
                    border: Border.all(color: encendido ? fondo : Tinta.tenue),
                  ),
                  child: AnimatedAlign(
                    duration: Ritmo.ui,
                    curve: Ritmo.entraSale,
                    alignment: encendido
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: Ritmo.ui,
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: encendido ? Tinta.papel : Tinta.apagada,
                        borderRadius: radio,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Casilla extends StatelessWidget {
  const Casilla({
    super.key,
    required this.valor,
    required this.alCambiar,
    required this.child,
  });

  final bool valor;
  final ValueChanged<bool> alCambiar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        checked: valor,
        child: InkWell(
          onTap: () => alCambiar(!valor),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: Ritmo.micro,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: valor ? Tinta.azul : Tinta.papel,
                    borderRadius: radio,
                    border: Border.all(color: valor ? Tinta.azul : Tinta.tenue),
                  ),
                  child: valor
                      ? const Trazo(Icono.check, tam: 16, color: Tinta.papel)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector de una opción entre pocas, en fila (origen de la entrega, etc.).
class Segmentos<T> extends StatelessWidget {
  const Segmentos({
    super.key,
    required this.opciones,
    required this.valor,
    required this.alCambiar,
  });

  final Map<T, String> opciones;
  final T valor;
  final ValueChanged<T> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, e) in opciones.entries.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              button: true,
              selected: e.key == valor,
              child: InkWell(
                onTap: () => alCambiar(e.key),
                borderRadius: radio,
                child: AnimatedContainer(
                  duration: Ritmo.micro,
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: e.key == valor ? Tinta.azulSuave : Tinta.papel,
                    borderRadius: radio,
                    border: Border.all(
                      color: e.key == valor ? Tinta.azul : Tinta.lineaFuerte,
                      width: e.key == valor ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    style: Letra.cuerpoFuerte.copyWith(
                      color: e.key == valor ? Tinta.azulHondo : Tinta.tinta,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
