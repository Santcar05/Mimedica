import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../datos/calculo_agotamiento.dart';
import '../../datos/formato.dart';
import 'tira_dosis.dart';

/// El momento de valor: «le alcanza hasta el sábado 3 de octubre» con su tira.
class FechaAgotamiento extends StatelessWidget {
  const FechaAgotamiento({
    super.key,
    required this.proyeccion,
    this.propio = false,
    this.asegurada = false,
  });

  final Proyeccion proyeccion;

  /// Verdadero si el tratamiento es de quien usa la app («te alcanza»).
  final bool propio;
  final bool asegurada;

  @override
  Widget build(BuildContext context) {
    final sinDosis = proyeccion.diasRestantes <= 0;
    final intro = propio
        ? 'Con lo que tienes en casa, te alcanza hasta el'
        : 'Con lo que tiene en casa, le alcanza hasta el';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Tinta.papelHondo,
        borderRadius: radio,
        border: Border.all(color: Tinta.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sinDosis)
            Text(
              propio
                  ? 'Hoy ya no te queda una dosis completa'
                  : 'Hoy ya no queda una dosis completa en casa',
              style: Letra.seccion.copyWith(color: Tinta.riesgo),
            )
          else ...[
            Text(intro, style: Letra.secundario),
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Text(
                fechaLarga(proyeccion.agotamiento),
                style: Letra.titulo.tabular,
              ),
            ),
          ],
          const SizedBox(height: 18),
          TiraDosis(
            diasRestantes: proyeccion.diasRestantes,
            fechaAgotamiento: fechaMinima(proyeccion.agotamiento),
            asegurada: asegurada,
          ),
        ],
      ),
    );
  }
}
