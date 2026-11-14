import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tema.dart';
import '../../datos/formato.dart';
import '../../datos/hogar.dart';
import '../../datos/repositorio.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/campo.dart';
import '../../nucleo/widgets/casillas_codigo.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/pantalla.dart';

const _esperaReenvio = 45;

class IngresoCodigo extends ConsumerStatefulWidget {
  const IngresoCodigo({super.key, required this.correo});
  final String correo;

  @override
  ConsumerState<IngresoCodigo> createState() => _IngresoCodigoState();
}

class _IngresoCodigoState extends ConsumerState<IngresoCodigo> {
  final _codigo = TextEditingController();
  Timer? _reloj;
  int _faltan = _esperaReenvio;
  bool _verificando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _arrancarReloj();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _codigo.dispose();
    super.dispose();
  }

  void _arrancarReloj() {
    _reloj?.cancel();
    setState(() => _faltan = _esperaReenvio);
    _reloj = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_faltan <= 1) t.cancel();
      if (mounted) setState(() => _faltan--);
    });
  }

  Future<void> _verificar([String? codigo]) async {
    final valor = codigo ?? _codigo.text;
    if (valor.length != CasillasCodigo.largo || _verificando) return;
    setState(() {
      _verificando = true;
      _error = null;
    });
    try {
      await ref.read(accesoProvider).verificar(widget.correo, valor);
      // El router reacciona a la sesión y lleva a la pantalla que toca.
    } on Fallo catch (fallo) {
      if (!mounted) return;
      _codigo.clear();
      setState(() => _error = fallo.mensaje);
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  Future<void> _reenviar() async {
    try {
      await ref.read(accesoProvider).pedirCodigo(widget.correo);
      _codigo.clear();
      setState(() => _error = null);
      _arrancarReloj();
    } on Fallo catch (fallo) {
      if (mounted) setState(() => _error = fallo.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutos =
        '${_faltan ~/ 60}:${(_faltan % 60).toString().padLeft(2, '0')}';
    return Pantalla(
      hijos: [
        Cabecera(
          'Escribe el código que te enviamos',
          bajada:
              'Llegó a ${correoVelado(widget.correo)}. Revisa también la '
              'carpeta de spam.',
        ),
        const SizedBox(height: 32),
        CasillasCodigo(
          controlador: _codigo,
          conError: _error != null,
          habilitado: !_verificando,
          alCompletar: _verificar,
        ),
        if (_error != null) MensajeError(_error!),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(
            _faltan > 0
                ? 'Puedes pedir otro en $minutos'
                : 'Si no llegó, puedes pedir otro.',
            style: Letra.secundario.tabular,
          ),
        ),
        const SizedBox(height: 8),
        BotonTexto(
          'Reenviar el código',
          icono: Icono.reintentar,
          alPulsar: _faltan > 0 ? null : _reenviar,
        ),
        BotonTexto(
          'Cambiar el correo',
          icono: Icono.lapiz,
          alPulsar: () => context.pop(),
        ),
      ],
      pie: [
        Boton(
          'Entrar',
          ocupado: _verificando,
          alPulsar: _codigo.text.length == CasillasCodigo.largo
              ? _verificar
              : null,
        ),
      ],
    );
  }
}
