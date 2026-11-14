import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tema.dart';
import '../../datos/calculo_agotamiento.dart';
import '../../datos/formato.dart';
import '../../datos/hogar.dart';
import '../../datos/identificador.dart';
import '../../datos/modelos.dart';
import '../../datos/repositorio.dart';
import '../../nucleo/entradas.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/campo.dart';
import '../../nucleo/widgets/controles.dart';
import '../../nucleo/widgets/fecha_agotamiento.dart';
import '../../nucleo/widgets/filas.dart';
import '../../nucleo/widgets/nota.dart';
import '../../nucleo/widgets/pantalla.dart';

/// Formulario del plan. Sirve para confirmar un medicamento nuevo a partir de
/// la fórmula (A-10) y para corregirlo después (B-03): la fecha de
/// agotamiento se recalcula mientras se escribe.
class FormularioTratamiento extends ConsumerStatefulWidget {
  const FormularioTratamiento({
    super.key,
    required this.persona,
    required this.alGuardar,
    this.existente,
    this.rutaFoto,
    this.foto,
  });

  final Persona persona;
  final Tratamiento? existente;
  final String? rutaFoto;

  /// Foto de la fórmula para tenerla a la vista mientras se escribe.
  final Uint8List? foto;
  final ValueChanged<Tratamiento> alGuardar;

  @override
  ConsumerState<FormularioTratamiento> createState() => _FormularioState();
}

class _FormularioState extends ConsumerState<FormularioTratamiento> {
  late final String _id = widget.existente?.id ?? nuevoId();
  late final TextEditingController _nombre;
  late final TextEditingController _concentracion;
  late final TextEditingController _porToma;
  late final TextEditingController _enCasa;
  late final TextEditingController _vigencia;
  late Presentacion _presentacion;
  late Frecuencia _frecuencia;
  bool _guardando = false;
  final _errores = <String, String>{};
  String? _errorGeneral;

  List<TextEditingController> get _controladores => [
    _nombre,
    _concentracion,
    _porToma,
    _enCasa,
    _vigencia,
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.existente;
    final hoy = ref.read(hoyProvider);
    _nombre = TextEditingController(text: t?.nombre);
    _concentracion = TextEditingController(text: t?.concentracion);
    _porToma = TextEditingController(text: cantidad(t?.porToma ?? 1));
    _enCasa = TextEditingController(
      text: t == null ? '' : cantidad(proyectar(t, hoy).enCasaHoy),
    );
    _vigencia = TextEditingController(
      text: t?.vigenciaHasta == null ? '' : fechaNumerica(t!.vigenciaHasta!),
    );
    _presentacion = t?.presentacion ?? Presentacion.tableta;
    _frecuencia = t?.frecuencia ?? Frecuencia.cada12;
    for (final c in _controladores) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controladores) {
      c.dispose();
    }
    super.dispose();
  }

  Tratamiento? get _tentativo {
    final porToma = leerCantidad(_porToma.text);
    final enCasa = leerCantidad(_enCasa.text);
    if (porToma == null || porToma <= 0 || enCasa == null) return null;
    final base = widget.existente;
    return Tratamiento(
      id: _id,
      personaId: widget.persona.id,
      nombre: _nombre.text.trim(),
      concentracion: _concentracion.text.trim(),
      presentacion: _presentacion,
      porToma: porToma,
      frecuencia: _frecuencia,
      enCasa: enCasa,
      contadoEl: ref.read(hoyProvider),
      creadoEl: base?.creadoEl ?? DateTime.now(),
      vigenciaHasta: leerFecha(_vigencia.text),
      fotoFormula: base?.fotoFormula ?? widget.rutaFoto,
      pausado: base?.pausado ?? false,
    );
  }

  bool _validar() {
    _errores.clear();
    if (_nombre.text.trim().length < 3) {
      _errores['nombre'] =
          'Escribe el nombre del medicamento como aparece en la fórmula.';
    }
    final porToma = leerCantidad(_porToma.text);
    if (porToma == null || porToma <= 0) {
      _errores['porToma'] =
          'Escribe cuánto toma cada vez, por ejemplo 1 o 0,5.';
    }
    if (leerCantidad(_enCasa.text) == null) {
      _errores['enCasa'] =
          'Cuenta lo que hay en casa hoy. Si no queda nada, escribe 0.';
    }
    if (_vigencia.text.isNotEmpty && leerFecha(_vigencia.text) == null) {
      _errores['vigencia'] =
          'Escribe la fecha completa, o déjala vacía si no la sabes.';
    }
    setState(() {});
    return _errores.isEmpty;
  }

  Future<void> _guardar() async {
    if (!_validar()) return;
    final tratamiento = _tentativo!;
    setState(() {
      _guardando = true;
      _errorGeneral = null;
    });
    try {
      await ref.read(hogarProvider.notifier).guardarTratamiento(tratamiento);
      if (mounted) widget.alGuardar(tratamiento);
    } on Fallo catch (fallo) {
      if (mounted) setState(() => _errorGeneral = fallo.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _elegirFrecuencia() async {
    final elegida = await elegirEnHoja<Frecuencia>(
      context,
      titulo: 'Cada cuánto lo toma',
      opciones: {for (final f in Frecuencia.values) f: f.rotulo},
      actual: _frecuencia,
    );
    if (elegida != null) setState(() => _frecuencia = elegida);
  }

  void _verFoto() {
    final foto = widget.foto;
    if (foto == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Tinta.tinta,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Image.memory(foto, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Semantics(
                  button: true,
                  label: 'Cerrar',
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Tinta.papel),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nuevo = widget.existente == null;
    final tentativo = _tentativo;
    final hoy = ref.watch(hoyProvider);
    final nombre = widget.persona.primerNombre;
    final unidades = _presentacion.plural;
    final nombreEscrito = _nombre.text.trim();

    return Pantalla(
      contexto: nuevo ? 'Fórmula de $nombre' : widget.existente!.titulo,
      hijos: [
        Cabecera(
          nuevo ? 'Arma el plan con tu fórmula' : 'Ajusta el plan de $nombre',
          bajada: nuevo
              ? 'Copia de la fórmula un medicamento a la vez. Todo se puede '
                    'corregir después.'
              : null,
        ),
        if (widget.foto != null) ...[
          const SizedBox(height: 16),
          _MiniaturaFormula(foto: widget.foto!, alPulsar: _verFoto),
        ],
        const SizedBox(height: 24),
        Campo(
          rotulo: 'Medicamento',
          controlador: _nombre,
          mayusculas: TextCapitalization.sentences,
          pista: 'Losartán',
          accion: TextInputAction.next,
          error: _errores['nombre'],
        ),
        const SizedBox(height: 18),
        Campo(
          rotulo: 'Concentración',
          controlador: _concentracion,
          pista: '50 mg',
          accion: TextInputAction.next,
        ),
        const SizedBox(height: 18),
        const Rotulo('Presentación'),
        const SizedBox(height: 8),
        Segmentos<Presentacion>(
          opciones: {for (final p in Presentacion.values) p: p.rotulo},
          valor: _presentacion,
          alCambiar: (p) => setState(() => _presentacion = p),
        ),
        const SizedBox(height: 18),
        Campo(
          rotulo: '${mayusculaInicial(unidades)} por toma',
          controlador: _porToma,
          teclado: const TextInputType.numberWithOptions(decimal: true),
          formato: [soloCantidad],
          sufijo: leerCantidad(_porToma.text) == 1
              ? _presentacion.singular
              : unidades,
          error: _errores['porToma'],
        ),
        const SizedBox(height: 18),
        CampoSelector(
          rotulo: 'Frecuencia',
          valor: _frecuencia.rotulo,
          alPulsar: _elegirFrecuencia,
        ),
        const SizedBox(height: 18),
        Campo(
          rotulo: '${mayusculaInicial(unidades)} en casa hoy',
          controlador: _enCasa,
          teclado: const TextInputType.numberWithOptions(decimal: true),
          formato: [soloCantidad],
          sufijo: unidades,
          ayuda: 'Cuéntalas si puedes. Es lo que más afina la fecha.',
          error: _errores['enCasa'],
        ),
        const SizedBox(height: 18),
        Campo(
          rotulo: 'Fórmula vigente hasta (opcional)',
          controlador: _vigencia,
          teclado: TextInputType.number,
          formato: const [FormatoFecha()],
          pista: 'día / mes / año',
          error: _errores['vigencia'],
        ),
        const SizedBox(height: 24),
        if (tentativo != null)
          FechaAgotamiento(
            proyeccion: proyectar(tentativo, hoy),
            propio: widget.persona.esTitular,
          ),
        const SizedBox(height: 16),
        const Nota(
          texto:
              'Esto no reemplaza lo que dijo el médico. Si algo no coincide '
              'con la fórmula, corrígelo.',
        ),
        if (_errorGeneral != null) MensajeError(_errorGeneral!),
      ],
      pie: [
        if (tentativo != null) _ResumenPie(proyectar(tentativo, hoy)),
        Boton(
          nuevo
              ? 'Activar el plan${nombreEscrito.isEmpty ? '' : ' de $nombreEscrito'}'
              : 'Guardar y recalcular',
          ocupado: _guardando,
          alPulsar: _guardar,
        ),
      ],
    );
  }
}

/// La fecha siempre a la vista, aunque el formulario esté desplazado.
class _ResumenPie extends StatelessWidget {
  const _ResumenPie(this.proyeccion);
  final Proyeccion proyeccion;

  @override
  Widget build(BuildContext context) {
    final sinDosis = proyeccion.diasRestantes <= 0;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text.rich(
          TextSpan(
            text: sinDosis ? 'Hoy no queda una dosis completa' : 'Se acaba el ',
            children: [
              if (!sinDosis)
                TextSpan(
                  text:
                      '${fechaCorta(proyeccion.agotamiento)} · '
                      '${dias(proyeccion.diasRestantes)} de dosis',
                  style: Letra.cuerpoFuerte.tabular,
                ),
            ],
          ),
          textAlign: TextAlign.center,
          style: Letra.secundario.copyWith(
            color: sinDosis ? Tinta.riesgo : Tinta.suave,
          ),
        ),
      ),
    );
  }
}

class _MiniaturaFormula extends StatelessWidget {
  const _MiniaturaFormula({required this.foto, required this.alPulsar});
  final Uint8List foto;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ver la foto de la fórmula en grande',
      child: InkWell(
        onTap: alPulsar,
        borderRadius: radio,
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: Tinta.superficie,
            borderRadius: radio,
            border: Border.all(color: Tinta.linea),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(2),
                ),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: Image.memory(foto, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Toca para ver la fórmula en grande mientras escribes.',
                  style: Letra.secundario,
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}
