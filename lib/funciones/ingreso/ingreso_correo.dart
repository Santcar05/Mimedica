import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/entorno.dart';
import '../../app/tema.dart';
import '../../datos/hogar.dart';
import '../../datos/repositorio.dart';
import '../../datos/repositorio_local.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/campo.dart';
import '../../nucleo/widgets/controles.dart';
import '../../nucleo/widgets/nota.dart';
import '../../nucleo/widgets/pantalla.dart';
import 'documento_legal.dart';

final _formaCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

class IngresoCorreo extends ConsumerStatefulWidget {
  const IngresoCorreo({super.key});

  @override
  ConsumerState<IngresoCorreo> createState() => _IngresoCorreoState();
}

class _IngresoCorreoState extends ConsumerState<IngresoCorreo> {
  final _correo = TextEditingController();
  bool _acepta = false;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  String get _valor => _correo.text.trim().toLowerCase();

  Future<void> _pedirCodigo() async {
    if (!_formaCorreo.hasMatch(_valor)) {
      setState(
        () => _error = _valor.contains('@')
            ? 'Revisa lo que va después de la @: falta el dominio, como gmail.com.'
            : 'A ese correo le falta la @. Debe verse como nombre@gmail.com.',
      );
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref.read(accesoProvider).pedirCodigo(_valor);
      if (mounted) context.push('/ingreso/codigo', extra: _valor);
    } on Fallo catch (fallo) {
      if (mounted) setState(() => _error = fallo.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listo = _valor.isNotEmpty && _acepta;
    const enlace = TextStyle(
      color: Tinta.azul,
      decoration: TextDecoration.underline,
      decorationColor: Tinta.azulLinea,
    );

    return Pantalla(
      hijos: [
        const Cabecera(
          '¿A qué correo te escribimos?',
          bajada:
              'Te mandamos un código de 6 dígitos. Así entras: no necesitas '
              'contraseña.',
        ),
        const SizedBox(height: 32),
        Campo(
          rotulo: 'Correo',
          controlador: _correo,
          pista: 'nombre@correo.com',
          teclado: TextInputType.emailAddress,
          autocompletar: const [AutofillHints.email],
          accion: TextInputAction.done,
          autofoco: true,
          error: _error,
          alCambiar: (_) => setState(() => _error = null),
          alEnviar: (_) => listo ? _pedirCodigo() : null,
        ),
        const SizedBox(height: 16),
        Casilla(
          valor: _acepta,
          alCambiar: (v) => setState(() => _acepta = v),
          child: Text.rich(
            TextSpan(
              text: 'Acepto los ',
              children: [
                TextSpan(
                  text: 'términos del servicio',
                  style: enlace,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => abrirDocumento(context, Legal.terminos),
                ),
                const TextSpan(text: ' y la '),
                TextSpan(
                  text: 'política de datos',
                  style: enlace,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => abrirDocumento(context, Legal.datos),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            style: Letra.cuerpo,
          ),
        ),
        if (!Entorno.conServidor) ...[
          const SizedBox(height: 24),
          const Nota(
            titulo: 'Versión de prueba sin servidor',
            texto:
                'No se envía ningún correo. En la pantalla siguiente escribe '
                'el código ${AccesoLocal.codigoDemo}.',
          ),
        ],
      ],
      pie: [
        Boton(
          'Recibir mi código',
          ocupado: _enviando,
          alPulsar: listo ? _pedirCodigo : null,
        ),
      ],
    );
  }
}
