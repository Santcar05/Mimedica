import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tema.dart';
import '../../datos/calculo_agotamiento.dart';
import '../../datos/formato.dart';
import '../../datos/hogar.dart';
import '../../datos/modelos.dart';
import '../../datos/repositorio.dart';
import '../../nucleo/entradas.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/campo.dart';
import '../../nucleo/widgets/controles.dart';
import '../../nucleo/widgets/fecha_agotamiento.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/pantalla.dart';

/// B-05 y C-06: cuánto llegó, cuándo y de dónde. Con eso se recalcula la fecha
/// y se cierra el ciclo abierto.
class Entrega extends ConsumerStatefulWidget {
  const Entrega({super.key, required this.tratamientoId, this.origen});
  final String tratamientoId;
  final OrigenEntrega? origen;

  @override
  ConsumerState<Entrega> createState() => _EntregaState();
}

class _EntregaState extends ConsumerState<Entrega> {
  late OrigenEntrega _origen = widget.origen ?? OrigenEntrega.eps;
  final _cantidad = TextEditingController();
  final _fecha = TextEditingController();
  final _punto = TextEditingController();
  final _errores = <String, String>{};
  bool _guardando = false;
  String? _errorGeneral;

  @override
  void initState() {
    super.initState();
    _fecha.text = fechaNumerica(ref.read(hoyProvider));
  }

  @override
  void dispose() {
    _cantidad.dispose();
    _fecha.dispose();
    _punto.dispose();
    super.dispose();
  }

  bool _validar(DateTime hoy) {
    _errores.clear();
    final n = leerCantidad(_cantidad.text);
    if (n == null || n <= 0) {
      _errores['cantidad'] = 'Escribe cuántas llegaron, por ejemplo 60.';
    }
    final f = leerFecha(_fecha.text);
    if (f == null) {
      _errores['fecha'] =
          'Escribe la fecha completa, por ejemplo 13 / 11 / 2026.';
    } else if (f.isAfter(hoy)) {
      _errores['fecha'] =
          'Esa fecha todavía no llega. Escribe el día en que lo recibiste.';
    } else if (hoy.difference(f).inDays > 120) {
      _errores['fecha'] = 'Esa fecha es de hace más de cuatro meses. Revísala.';
    }
    setState(() {});
    return _errores.isEmpty;
  }

  Future<void> _guardar() async {
    final hoy = ref.read(hoyProvider);
    if (!_validar(hoy)) return;
    setState(() {
      _guardando = true;
      _errorGeneral = null;
    });
    try {
      await ref
          .read(hogarProvider.notifier)
          .registrarEntrega(
            tratamientoId: widget.tratamientoId,
            origen: _origen,
            cantidad: leerCantidad(_cantidad.text)!,
            fecha: leerFecha(_fecha.text)!,
            punto: _punto.text.trim().isEmpty ? null : _punto.text.trim(),
          );
      if (mounted) {
        context.pushReplacement('/entrega/${widget.tratamientoId}/listo');
      }
    } on Fallo catch (fallo) {
      if (mounted) setState(() => _errorGeneral = fallo.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hogar = ref.watch(hogarProvider).value;
    final t = hogar?.tratamiento(widget.tratamientoId);
    if (t == null) return const SizedBox.shrink();
    final persona = hogar!.persona(t.personaId);
    final ciclo = hogar.cicloEnCurso(t.id);
    final propio = persona?.esTitular ?? false;

    return Pantalla(
      contexto: t.titulo,
      hijos: [
        Cabecera(
          propio ? '¿Qué recibiste?' : '¿Qué recibió ${persona?.primerNombre}?',
          bajada: ciclo == null
              ? 'Con esto recalculamos la fecha en que se acaba.'
              : 'Con esto recalculamos la fecha y cerramos el ciclo de '
                    '${mes(ciclo.abiertoEl)}.',
        ),
        const SizedBox(height: 24),
        const Rotulo('De dónde llegó'),
        const SizedBox(height: 8),
        Segmentos<OrigenEntrega>(
          opciones: {for (final o in OrigenEntrega.values) o: o.rotulo},
          valor: _origen,
          alCambiar: (o) => setState(() => _origen = o),
        ),
        const SizedBox(height: 18),
        Campo(
          rotulo: 'Cantidad',
          controlador: _cantidad,
          teclado: const TextInputType.numberWithOptions(decimal: true),
          formato: [soloCantidad],
          sufijo: t.presentacion.plural,
          error: _errores['cantidad'],
          autofoco: true,
          alCambiar: (_) => setState(() => _errores.remove('cantidad')),
        ),
        const SizedBox(height: 18),
        Campo(
          rotulo: 'Fecha',
          controlador: _fecha,
          teclado: TextInputType.number,
          formato: const [FormatoFecha()],
          error: _errores['fecha'],
          alCambiar: (_) => setState(() => _errores.remove('fecha')),
        ),
        const SizedBox(height: 18),
        Campo(
          rotulo: 'Punto de entrega (opcional)',
          controlador: _punto,
          mayusculas: TextCapitalization.words,
          pista: _origen == OrigenEntrega.eps
              ? (persona?.eps ?? 'Dispensario de la EPS')
              : 'Droguería',
          accion: TextInputAction.done,
        ),
        if (_errorGeneral != null) MensajeError(_errorGeneral!),
      ],
      pie: [
        Boton('Guardar la entrega', ocupado: _guardando, alPulsar: _guardar),
      ],
    );
  }
}

/// Muestra la fecha nueva: el momento en que el cuidador ve que la
/// entrega sirvió.
class EntregaGuardada extends ConsumerWidget {
  const EntregaGuardada({super.key, required this.tratamientoId});
  final String tratamientoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hogar = ref.watch(hogarProvider).value;
    final t = hogar?.tratamiento(tratamientoId);
    if (t == null) return const SizedBox.shrink();
    final persona = hogar!.persona(t.personaId);
    final p = proyectar(t, ref.watch(hoyProvider));
    final propio = persona?.esTitular ?? false;

    return Pantalla(
      conVolver: false,
      hijos: [
        const SizedBox(height: 8),
        const Row(
          children: [
            Trazo(Icono.check, tam: 20, color: Tinta.ok),
            SizedBox(width: 8),
            Text(
              'Entrega registrada',
              style: TextStyle(
                fontFamily: 'General Sans',
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Tinta.ok,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            propio
                ? 'Tu ${t.nombre} tiene una fecha nueva'
                : 'El ${t.nombre} de ${persona?.primerNombre} tiene una fecha '
                      'nueva',
            style: Letra.display,
          ),
        ),
        const SizedBox(height: 24),
        FechaAgotamiento(proyeccion: p, propio: propio),
        const SizedBox(height: 20),
        Text(
          'Cerramos el ciclo. Te avisamos $diasDeGestion días antes de que se '
          'acabe, el ${fechaCorta(p.inicioGestion)}.',
          style: Letra.cuerpo.copyWith(color: Tinta.suave),
        ),
      ],
      pie: [Boton('Ir al inicio', alPulsar: () => context.go('/inicio'))],
    );
  }
}
