import 'package:flutter/material.dart';

import '../../datos/calculo_agotamiento.dart';
import 'sello_estado.dart';

TonoEstado tonoDe(EstadoTratamiento estado) => switch (estado) {
  EstadoTratamiento.enRiesgo || EstadoTratamiento.agotado => TonoEstado.riesgo,
  EstadoTratamiento.enGestion => TonoEstado.espera,
  EstadoTratamiento.cubierto => TonoEstado.ok,
  EstadoTratamiento.pausado => TonoEstado.neutro,
};

class SelloDeTratamiento extends StatelessWidget {
  const SelloDeTratamiento(this.estado, {super.key});
  final EstadoTratamiento estado;

  @override
  Widget build(BuildContext context) =>
      SelloEstado(estado.rotulo, tono: tonoDe(estado));
}
