import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'boton.dart';
import 'icono.dart';

/// Estructura común: encabezado de 52 px, contenido desplazable con el margen
/// del sistema y un pie fijo para las acciones.
class Pantalla extends StatelessWidget {
  const Pantalla({
    super.key,
    required this.hijos,
    this.pie = const [],
    this.contexto,
    this.accion,
    this.alVolver,
    this.conVolver = true,
    this.iconoVolver = Icono.volver,
    this.barraInferior,
  });

  final List<Widget> hijos;
  final List<Widget> pie;

  /// Texto pequeño junto a la flecha, p. ej. «Losartán 50 mg».
  final String? contexto;
  final Widget? accion;
  final VoidCallback? alVolver;
  final bool conVolver;
  final Icono iconoVolver;
  final Widget? barraInferior;

  @override
  Widget build(BuildContext context) {
    final puedeVolver = conVolver && (alVolver != null || Navigator.canPop(context));
    final conEncabezado = puedeVolver || contexto != null || accion != null;

    return Scaffold(
      bottomNavigationBar: barraInferior,
      body: SafeArea(
        child: Column(
          children: [
            if (conEncabezado)
              SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, right: 12),
                  child: Row(
                    children: [
                      if (puedeVolver)
                        BotonIcono(
                          iconoVolver,
                          etiqueta: iconoVolver == Icono.cerrar
                              ? 'Cerrar'
                              : 'Volver',
                          alPulsar:
                              alVolver ?? () => Navigator.maybePop(context),
                        )
                      else
                        const SizedBox(width: 14),
                      Expanded(
                        child: contexto == null
                            ? const SizedBox.shrink()
                            : Text(
                                contexto!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Letra.secundario,
                              ),
                      ),
                      if (accion != null) accion!,
                    ],
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  margen,
                  conEncabezado ? 4 : 24,
                  margen,
                  24,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: hijos,
                ),
              ),
            ),
            if (pie.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(margen, 8, margen, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, w) in pie.indexed) ...[
                      if (i > 0) const SizedBox(height: 8),
                      w,
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Título de pantalla con su bajada.
class Cabecera extends StatelessWidget {
  const Cabecera(this.titulo, {super.key, this.bajada});
  final String titulo;
  final String? bajada;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(titulo, style: Letra.titulo)),
        if (bajada != null) ...[
          const SizedBox(height: 8),
          Text(bajada!, style: Letra.cuerpo.copyWith(color: Tinta.suave)),
        ],
      ],
    );
  }
}

class Separador extends StatelessWidget {
  const Separador({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: Tinta.linea);
}

/// Par rótulo–valor de las fichas de plan y detalle.
class Dato extends StatelessWidget {
  const Dato(this.rotulo, this.valor, {super.key, this.accion});
  final String rotulo;
  final String valor;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(rotulo, style: Letra.secundario),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(valor, style: Letra.cuerpo.tabular)),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}
