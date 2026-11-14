import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'icono.dart';

enum TonoNota { info, aviso, riesgo }

class Nota extends StatelessWidget {
  const Nota({
    super.key,
    this.titulo,
    required this.texto,
    this.tono = TonoNota.info,
    this.accion,
  });

  final String? titulo;
  final String texto;
  final TonoNota tono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final (color, fondo, icono) = switch (tono) {
      TonoNota.info => (Tinta.azul, Tinta.azulSuave, Icono.info),
      TonoNota.aviso => (Tinta.espera, Tinta.esperaSuave, Icono.alerta),
      TonoNota.riesgo => (Tinta.riesgo, Tinta.riesgoSuave, Icono.alerta),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(color: fondo, borderRadius: radio),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Trazo(icono, tam: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titulo != null) ...[
                  Text(titulo!, style: Letra.cuerpoFuerte),
                  const SizedBox(height: 2),
                ],
                Text(
                  texto,
                  style: Letra.secundario.copyWith(color: Tinta.suave),
                ),
                if (accion != null) accion!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de afirmaciones con visto bueno (A-05).
class ListaVistos extends StatelessWidget {
  const ListaVistos(this.lineas, {super.key});
  final List<String> lineas;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final linea in lineas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Trazo(Icono.check, tam: 18, color: Tinta.ok),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    linea,
                    style: Letra.cuerpo.copyWith(color: Tinta.suave),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
