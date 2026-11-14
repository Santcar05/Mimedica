import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../datos/hogar.dart';
import '../../datos/modelos.dart';
import '../../datos/repositorio.dart';
import '../../nucleo/entradas.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/campo.dart';
import '../../nucleo/widgets/filas.dart';
import '../../nucleo/widgets/pantalla.dart';

const tiposDocumento = {
  'Cédula de ciudadanía': 'Cédula de ciudadanía',
  'Cédula de extranjería': 'Cédula de extranjería',
  'Pasaporte': 'Pasaporte',
};

class DatosBasicos extends ConsumerStatefulWidget {
  const DatosBasicos({super.key});

  @override
  ConsumerState<DatosBasicos> createState() => _DatosBasicosState();
}

class _DatosBasicosState extends ConsumerState<DatosBasicos> {
  final _nombre = TextEditingController();
  final _documento = TextEditingController();
  final _nacimiento = TextEditingController();
  String _tipo = tiposDocumento.keys.first;
  bool _guardando = false;
  String? _errorGeneral;
  final _errores = <String, String>{};

  @override
  void dispose() {
    _nombre.dispose();
    _documento.dispose();
    _nacimiento.dispose();
    super.dispose();
  }

  DateTime? _validar() {
    _errores.clear();
    if (_nombre.text.trim().split(RegExp(r'\s+')).length < 2) {
      _errores['nombre'] =
          'Escribe tu nombre y tu apellido, como aparece en la cédula.';
    }
    if (_documento.text.replaceAll(RegExp(r'\D'), '').length < 5) {
      _errores['documento'] = 'Revisa el número: parece que le faltan dígitos.';
    }
    final nacimiento = leerFecha(_nacimiento.text);
    if (nacimiento == null) {
      _errores['nacimiento'] =
          'Escribe la fecha con día, mes y año, por ejemplo 14 / 03 / 1991.';
    } else if (nacimiento.isAfter(
      DateTime.now().subtract(const Duration(days: 365 * 18)),
    )) {
      _errores['nacimiento'] =
          'Para usar Mimedica por tu cuenta necesitas ser mayor de 18 años.';
    } else if (nacimiento.year < 1900) {
      _errores['nacimiento'] = 'Revisa el año: parece demasiado antiguo.';
    }
    setState(() {});
    return _errores.isEmpty ? nacimiento : null;
  }

  Future<void> _guardar() async {
    final nacimiento = _validar();
    if (nacimiento == null) return;
    setState(() {
      _guardando = true;
      _errorGeneral = null;
    });
    try {
      await ref
          .read(hogarProvider.notifier)
          .guardarPerfil(
            Perfil(
              nombre: _nombre.text.trim(),
              tipoDocumento: _tipo,
              documento: _documento.text.replaceAll(RegExp(r'\D'), ''),
              nacimiento: nacimiento,
            ),
          );
      if (mounted) context.go('/activacion/consentimiento');
    } on Fallo catch (fallo) {
      if (mounted) setState(() => _errorGeneral = fallo.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _elegirTipo() async {
    final elegido = await elegirEnHoja(
      context,
      titulo: 'Tipo de documento',
      opciones: tiposDocumento,
      actual: _tipo,
    );
    if (elegido != null) setState(() => _tipo = elegido);
  }

  @override
  Widget build(BuildContext context) {
    return Pantalla(
      conVolver: false,
      hijos: [
        const Cabecera(
          'Cuéntanos quién eres',
          bajada:
              'Lo usamos para que tu EPS y la droguería reconozcan la fórmula '
              'a tu nombre.',
        ),
        const SizedBox(height: 24),
        Campo(
          rotulo: 'Nombre completo',
          controlador: _nombre,
          mayusculas: TextCapitalization.words,
          accion: TextInputAction.next,
          autocompletar: const [AutofillHints.name],
          error: _errores['nombre'],
          alCambiar: (_) => setState(() => _errores.remove('nombre')),
        ),
        const SizedBox(height: 18),
        CampoSelector(
          rotulo: 'Tipo de documento',
          valor: _tipo,
          alPulsar: _elegirTipo,
        ),
        const SizedBox(height: 18),
        Campo(
          rotulo: 'Número de documento',
          controlador: _documento,
          teclado: TextInputType.number,
          formato: [FilteringTextInputFormatter.digitsOnly],
          accion: TextInputAction.next,
          error: _errores['documento'],
          alCambiar: (_) => setState(() => _errores.remove('documento')),
        ),
        const SizedBox(height: 18),
        Campo(
          rotulo: 'Fecha de nacimiento',
          controlador: _nacimiento,
          teclado: TextInputType.number,
          formato: const [FormatoFecha()],
          pista: 'día / mes / año',
          ayuda: 'Día, mes y año.',
          error: _errores['nacimiento'],
          alCambiar: (_) => setState(() => _errores.remove('nacimiento')),
          alEnviar: (_) => _guardar(),
        ),
        if (_errorGeneral != null) MensajeError(_errorGeneral!),
      ],
      pie: [
        Boton('Guardar mis datos', ocupado: _guardando, alPulsar: _guardar),
      ],
    );
  }
}
