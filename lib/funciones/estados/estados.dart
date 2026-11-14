import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../datos/repositorio.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/pantalla.dart';
import '../../nucleo/widgets/tira_dosis.dart';

/// H-02: la tira sin datos, mientras llegan.
class EstadoCargando extends StatelessWidget {
  const EstadoCargando({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando tus tratamientos',
      liveRegion: true,
      child: const Pantalla(
        conVolver: false,
        hijos: [
          SizedBox(height: 40),
          _Esqueleto(ancho: 220, alto: 14),
          SizedBox(height: 16),
          _Esqueleto(ancho: 300, alto: 30),
          SizedBox(height: 40),
          _Fila(),
          SizedBox(height: 32),
          _Fila(),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Esqueleto(ancho: 160, alto: 18),
        SizedBox(height: 14),
        _Esqueleto(ancho: 120, alto: 34),
        SizedBox(height: 16),
        _Esqueleto(ancho: double.infinity, alto: 3),
      ],
    );
  }
}

class _Esqueleto extends StatelessWidget {
  const _Esqueleto({required this.ancho, required this.alto});
  final double ancho;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: alto,
      decoration: const BoxDecoration(
        color: Tinta.superficie,
        borderRadius: radio,
      ),
    );
  }
}

/// H-01: todavía no hay ningún tratamiento.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({super.key, required this.alAgregar});
  final VoidCallback alAgregar;

  @override
  Widget build(BuildContext context) {
    return Pantalla(
      conVolver: false,
      hijos: [
        const SizedBox(height: 32),
        const Opacity(
          opacity: .6,
          child: TiraDosis(diasRestantes: 0, compacta: true, ventana: 0),
        ),
        const SizedBox(height: 32),
        Semantics(
          header: true,
          child: const Text(
            'Todavía no sabemos cuándo se acaba ningún medicamento',
            style: Letra.display,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sube la fórmula y te decimos hasta qué día te alcanza. Toma menos '
          'de cinco minutos.',
          style: Letra.cuerpo.copyWith(color: Tinta.suave),
        ),
      ],
      pie: [
        Boton(
          'Subir la primera fórmula',
          icono: Icono.camara,
          alPulsar: alAgregar,
        ),
      ],
    );
  }
}

/// H-03 y H-04: algo falló al cargar; siempre con una salida.
class EstadoError extends StatelessWidget {
  const EstadoError(this.error, {super.key, required this.alReintentar});
  final Object error;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final fallo = error is Fallo ? error as Fallo : null;
    final sinRed = fallo?.sinRed ?? false;

    return Pantalla(
      conVolver: false,
      hijos: [
        const SizedBox(height: 56),
        Trazo(
          sinRed ? Icono.sinRed : Icono.alerta,
          tam: 32,
          color: Tinta.apagada,
        ),
        const SizedBox(height: 16),
        Cabecera(
          sinRed ? 'No hay conexión' : 'No pudimos cargar tus tratamientos',
          bajada: sinRed
              ? 'Revisa el wifi o los datos. Tus medicamentos siguen guardados.'
              : 'Es un problema nuestro, no tuyo. Tus datos están a salvo; '
                    'inténtalo de nuevo.',
        ),
      ],
      pie: [
        Boton(
          'Intentar de nuevo',
          icono: Icono.reintentar,
          alPulsar: alReintentar,
        ),
      ],
    );
  }
}
