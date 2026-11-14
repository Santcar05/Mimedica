import 'package:flutter/material.dart';

import '../../app/tema.dart';

/// El logo es un dibujo de línea sobre blanco; multiplicarlo con el papel
/// funde el fondo, así que solo va sobre superficies claras.
class Logo extends StatelessWidget {
  const Logo({super.key, this.tam = 44});
  final double tam;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/img/logo.jpeg',
      width: tam,
      height: tam,
      color: Tinta.papel,
      colorBlendMode: BlendMode.multiply,
      excludeFromSemantics: true,
    );
  }
}
