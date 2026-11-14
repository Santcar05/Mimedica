import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tema.dart';
import '../../datos/hogar.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/icono.dart';

final _fotoProvider = FutureProvider.family<Uint8List?, String>(
  (ref, ruta) => ref.read(repositorioProvider).descargarFormula(ruta),
);

Future<void> verFormula(BuildContext context, String ruta) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog.fullscreen(
      backgroundColor: Tinta.tinta,
      child: _Visor(ruta: ruta),
    ),
  );
}

class _Visor extends ConsumerWidget {
  const _Visor({required this.ruta});
  final String ruta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foto = ref.watch(_fotoProvider(ruta));
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: foto.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Tinta.papel,
                ),
              ),
              error: (_, _) => _Mensaje(
                'No pudimos abrir la foto. Revisa tu conexión.',
                alReintentar: () => ref.invalidate(_fotoProvider(ruta)),
              ),
              data: (bytes) => bytes == null
                  ? const _Mensaje('La foto ya no está guardada.')
                  : InteractiveViewer(
                      maxScale: 5,
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: BotonIcono(
              Icono.cerrar,
              etiqueta: 'Cerrar',
              color: Tinta.papel,
              alPulsar: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje(this.texto, {this.alReintentar});
  final String texto;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Letra.cuerpo.copyWith(color: Tinta.papel),
            ),
            if (alReintentar != null) ...[
              const SizedBox(height: 16),
              Boton(
                'Intentar de nuevo',
                ancho: false,
                estilo: EstiloBoton.secundario,
                alPulsar: alReintentar,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
