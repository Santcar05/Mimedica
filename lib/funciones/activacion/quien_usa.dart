import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../datos/hogar.dart';
import '../../datos/identificador.dart';
import '../../datos/modelos.dart';
import '../../datos/repositorio.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/campo.dart';
import '../../nucleo/widgets/filas.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/nota.dart';
import '../../nucleo/widgets/pantalla.dart';
import 'borrador.dart';

const epsComunes = [
  'Compensar',
  'Sura',
  'Sanitas',
  'Nueva EPS',
  'Salud Total',
  'Famisanar',
  'Coosalud',
  'Otra',
];

/// Bifurca el flujo: tratamiento propio o de un familiar.
class QuienUsa extends ConsumerStatefulWidget {
  const QuienUsa({super.key});

  @override
  ConsumerState<QuienUsa> createState() => _QuienUsaState();
}

class _QuienUsaState extends ConsumerState<QuienUsa> {
  bool? _paraMi;
  final _nombre = TextEditingController();
  String? _eps;
  bool _guardando = false;
  String? _errorNombre;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _elegirEps() async {
    final elegida = await elegirEnHoja(
      context,
      titulo: 'EPS',
      opciones: {for (final e in epsComunes) e: e},
      actual: _eps,
    );
    if (elegida != null) setState(() => _eps = elegida);
  }

  Future<void> _seguir() async {
    final perfil = ref.read(hogarProvider).value!.perfil!;
    final nombre = _paraMi! ? perfil.nombre : _nombre.text.trim();
    if (nombre.split(RegExp(r'\s+')).length < 2) {
      setState(
        () => _errorNombre =
            'Escribe su nombre y su apellido, como aparece en la fórmula.',
      );
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final persona = Persona(
        id: nuevoId(),
        nombre: nombre,
        esTitular: _paraMi!,
        eps: _eps,
      );
      await ref.read(hogarProvider.notifier).guardarPersona(persona);
      ref.read(borradorProvider.notifier).empezar(persona);
      if (mounted) context.go('/formula/captura');
    } on Fallo catch (fallo) {
      if (mounted) setState(() => _error = fallo.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paraMi = _paraMi;
    return Pantalla(
      conVolver: false,
      hijos: [
        const Cabecera(
          '¿Para quién es este tratamiento?',
          bajada: 'Puedes gestionar hasta tres personas en la misma cuenta.',
        ),
        const SizedBox(height: 32),
        TarjetaOpcion(
          icono: Icono.persona,
          titulo: 'Es para mí',
          detalle: 'Recibes los avisos y decides dónde conseguirlo.',
          elegida: paraMi == true,
          alPulsar: () => setState(() => _paraMi = true),
        ),
        const SizedBox(height: 12),
        TarjetaOpcion(
          icono: Icono.familia,
          titulo: 'Es para un familiar',
          detalle: 'Tú lo gestionas. Es su fórmula y son sus datos de salud.',
          elegida: paraMi == false,
          alPulsar: () => setState(() => _paraMi = false),
        ),
        if (paraMi == false) ...[
          const SizedBox(height: 24),
          Campo(
            rotulo: 'Nombre de tu familiar',
            controlador: _nombre,
            mayusculas: TextCapitalization.words,
            error: _errorNombre,
            alCambiar: (_) => setState(() => _errorNombre = null),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Nota(
              titulo: 'Sus datos de salud son suyos',
              texto:
                  'Pídele permiso a tu familiar antes de subir su fórmula, '
                  'aunque seas tú quien lo cuida.',
            ),
          ),
        ],
        if (paraMi != null) ...[
          const SizedBox(height: 24),
          CampoSelector(
            rotulo: 'EPS (opcional)',
            valor: _eps,
            pista: 'Elige la EPS',
            alPulsar: _elegirEps,
          ),
        ],
        if (_error != null) MensajeError(_error!),
      ],
      pie: [
        Boton(
          paraMi == false
              ? 'Subir la fórmula de mi familiar'
              : 'Subir mi fórmula',
          ocupado: _guardando,
          alPulsar: paraMi == null ? null : _seguir,
        ),
      ],
    );
  }
}
