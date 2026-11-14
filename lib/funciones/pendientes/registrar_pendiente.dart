import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../datos/formato.dart';
import '../../datos/hogar.dart';
import '../../datos/identificador.dart';
import '../../datos/modelos.dart';
import '../../datos/repositorio.dart';
import '../../nucleo/entradas.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/campo.dart';
import '../../nucleo/widgets/filas.dart';
import '../../nucleo/widgets/pantalla.dart';

/// D-01: dejar constancia de lo que la EPS no entregó.
class RegistrarPendiente extends ConsumerStatefulWidget {
  const RegistrarPendiente({super.key, this.tratamientoId});
  final String? tratamientoId;

  @override
  ConsumerState<RegistrarPendiente> createState() => _RegistrarPendienteState();
}

class _RegistrarPendienteState extends ConsumerState<RegistrarPendiente> {
  String? _tratamientoId;
  final _fecha = TextEditingController();
  final _punto = TextEditingController();
  final _faltante = TextEditingController();
  final _nota = TextEditingController();
  final _errores = <String, String>{};
  bool _guardando = false;
  String? _errorGeneral;

  @override
  void initState() {
    super.initState();
    final hogar = ref.read(hogarProvider).value;
    _tratamientoId =
        widget.tratamientoId ??
        (hogar?.tratamientos.length == 1 ? hogar!.tratamientos.first.id : null);
    _fecha.text = fechaNumerica(ref.read(hoyProvider));
    final t = _tratamientoId == null
        ? null
        : hogar?.tratamiento(_tratamientoId!);
    _punto.text = (t == null ? null : hogar!.persona(t.personaId)?.eps) ?? '';
  }

  @override
  void dispose() {
    for (final c in [_fecha, _punto, _faltante, _nota]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirMedicamento(Hogar hogar) async {
    final id = await elegirEnHoja<String>(
      context,
      titulo: '¿Qué medicamento no te entregaron?',
      opciones: {for (final t in hogar.tratamientos) t.id: t.titulo},
      actual: _tratamientoId,
    );
    if (id != null) setState(() => _tratamientoId = id);
  }

  Future<void> _guardar() async {
    final hoy = ref.read(hoyProvider);
    _errores.clear();
    final fecha = leerFecha(_fecha.text);
    if (_tratamientoId == null) {
      _errores['tratamiento'] = 'Elige el medicamento que no te entregaron.';
    }
    if (fecha == null) {
      _errores['fecha'] =
          'Escribe la fecha completa, por ejemplo 13 / 11 / 2026.';
    } else if (fecha.isAfter(hoy)) {
      _errores['fecha'] = 'Esa fecha todavía no llega.';
    }
    if (_punto.text.trim().isEmpty) {
      _errores['punto'] =
          'Escribe dónde te dijeron que estaba pendiente, por ejemplo el '
          'dispensario de tu EPS.';
    }
    final faltante = leerCantidad(_faltante.text);
    if (_faltante.text.isNotEmpty && faltante == null) {
      _errores['faltante'] = 'Escribe solo el número, por ejemplo 30.';
    }
    setState(() {});
    if (_errores.isNotEmpty) return;

    setState(() {
      _guardando = true;
      _errorGeneral = null;
    });
    try {
      await ref
          .read(hogarProvider.notifier)
          .registrarPendiente(
            Pendiente(
              id: nuevoId(),
              tratamientoId: _tratamientoId!,
              fecha: fecha!,
              punto: _punto.text.trim(),
              faltante: faltante,
              nota: _nota.text.trim().isEmpty ? null : _nota.text.trim(),
            ),
          );
      if (mounted) context.go('/pendientes');
    } on Fallo catch (fallo) {
      if (mounted) setState(() => _errorGeneral = fallo.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hogar = ref.watch(hogarProvider).value;
    if (hogar == null) return const SizedBox.shrink();
    final t = _tratamientoId == null
        ? null
        : hogar.tratamiento(_tratamientoId!);

    return Pantalla(
      hijos: [
        const Cabecera(
          'Registra lo que no te entregaron',
          bajada: 'Un minuto ahora te ahorra explicaciones después.',
        ),
        const SizedBox(height: 24),
        CampoSelector(
          rotulo: 'Medicamento',
          valor: t?.titulo,
          pista: 'Elige el medicamento',
          error: _errores['tratamiento'],
          alPulsar: () => _elegirMedicamento(hogar),
        ),
        const SizedBox(height: 18),
        Campo(
          rotulo: 'Fecha',
          controlador: _fecha,
          teclado: TextInputType.number,
          formato: const [FormatoFecha()],
          error: _errores['fecha'],
        ),
        const SizedBox(height: 18),
        Campo(
          rotulo: 'Dónde te dijeron que estaba pendiente',
          controlador: _punto,
          mayusculas: TextCapitalization.words,
          pista: 'Dispensario de la EPS',
          error: _errores['punto'],
        ),
        const SizedBox(height: 18),
        Campo(
          rotulo: 'Cuántas faltaron (opcional)',
          controlador: _faltante,
          teclado: const TextInputType.numberWithOptions(decimal: true),
          formato: [soloCantidad],
          sufijo: t?.presentacion.plural,
          error: _errores['faltante'],
        ),
        const SizedBox(height: 18),
        Campo(
          rotulo: 'Qué te dijeron (opcional)',
          controlador: _nota,
          mayusculas: TextCapitalization.sentences,
          pista: 'Que llegaba en ocho días',
        ),
        if (_errorGeneral != null) MensajeError(_errorGeneral!),
      ],
      pie: [
        Boton('Guardar el pendiente', ocupado: _guardando, alPulsar: _guardar),
      ],
    );
  }
}
