import 'package:flutter/material.dart';

/// El logo es un dibujo de línea con fondo transparente, así que va bien
/// sobre cualquier superficie.
class Logo extends StatelessWidget {
  const Logo({super.key, this.tam = 44});
  final double tam;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/img/logo.png',
      width: tam,
      height: tam,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
}
