import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/modelos.dart';

/// Lo que se va armando mientras el usuario sube una fórmula: para quién es,
/// la foto y la ruta donde quedó guardada.
class Borrador {
  const Borrador({this.persona, this.foto, this.rutaFoto});

  final Persona? persona;
  final Uint8List? foto;
  final String? rutaFoto;
}

class BorradorNotifier extends Notifier<Borrador> {
  @override
  Borrador build() => const Borrador();

  void empezar(Persona persona) => state = Borrador(persona: persona);

  void foto(Uint8List bytes) =>
      state = Borrador(persona: state.persona, foto: bytes);

  void guardada(String ruta) => state = Borrador(
    persona: state.persona,
    foto: state.foto,
    rutaFoto: ruta,
  );

  void limpiar() => state = const Borrador();
}

final borradorProvider = NotifierProvider<BorradorNotifier, Borrador>(
  BorradorNotifier.new,
);
