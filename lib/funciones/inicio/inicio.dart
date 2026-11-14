import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tema.dart';
import '../../datos/calculo_agotamiento.dart';
import '../../datos/formato.dart';
import '../../datos/hogar.dart';
import '../../datos/modelos.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/estado_visual.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/pantalla.dart';
import '../../nucleo/widgets/tira_dosis.dart';
import '../estados/estados.dart';

/// Un tratamiento con todo lo que hace falta para pintarlo.
class VistaTratamiento {
  VistaTratamiento(
    this.t,
    this.persona,
    this.proyeccion,
    this.ciclo,
    this.opciones,
    this.hoy,
  ) : estado = estadoDe(t, proyeccion, ciclo: ciclo);

  final Tratamiento t;
  final Persona? persona;
  final Proyeccion proyeccion;
  final Ciclo? ciclo;
  final List<Opcion> opciones;
  final DateTime hoy;
  final EstadoTratamiento estado;

  /// H-08: la fórmula ya no está vigente y no se puede seguir gestionando.
  bool get formulaVencida =>
      t.vigenciaHasta != null && t.vigenciaHasta!.isBefore(hoy);

  bool get porDecidir =>
      !t.pausado &&
      ciclo != null &&
      ciclo!.estado == EstadoCiclo.abierto &&
      (opciones.isNotEmpty ||
          estado == EstadoTratamiento.enRiesgo ||
          estado == EstadoTratamiento.agotado);

  bool get asegurada => ciclo?.estado == EstadoCiclo.asegurado;

  /// La frase que explica qué pasa con este tratamiento ahora mismo.
  String get contexto {
    final eps = persona?.eps ?? 'la EPS';
    if (t.pausado) return 'En pausa: no te avisaremos de este medicamento.';
    if (formulaVencida) {
      return 'La fórmula venció el ${fechaCorta(t.vigenciaHasta!)}. Pídele a '
          'su médico una nueva para seguir gestionándolo.';
    }
    final c = ciclo;
    if (c == null) {
      return proyeccion.enVentana
          ? 'Estamos por abrir la gestión.'
          : 'Empezamos a gestionarlo el ${fechaMinima(proyeccion.inicioGestion)}.';
    }
    if (c.estado == EstadoCiclo.asegurado) {
      return c.nota ?? 'La entrega está asegurada. No tienes que hacer nada.';
    }
    if (opciones.isNotEmpty) {
      final n = opciones.length;
      return 'Encontramos $n ${n == 1 ? 'opción' : 'opciones'} para conseguirlo.';
    }
    return c.nota ??
        'Estamos consultando con $eps. Te contamos aquí en cuanto sepamos.';
  }
}

List<VistaTratamiento> vistasDe(Hogar hogar, DateTime hoy) {
  final vistas = [
    for (final t in hogar.tratamientos)
      VistaTratamiento(
        t,
        hogar.persona(t.personaId),
        proyectar(t, hoy),
        hogar.cicloEnCurso(t.id),
        hogar.cicloEnCurso(t.id) == null
            ? const []
            : hogar.opcionesDe(hogar.cicloEnCurso(t.id)!.id),
        hoy,
      ),
  ];
  int peso(VistaTratamiento v) => v.t.pausado ? 2 : (v.porDecidir ? 0 : 1);
  vistas.sort((a, b) {
    final p = peso(a).compareTo(peso(b));
    return p != 0
        ? p
        : a.proyeccion.diasRestantes.compareTo(b.proyeccion.diasRestantes);
  });
  return vistas;
}

class Inicio extends ConsumerWidget {
  const Inicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hogar = ref.watch(hogarProvider);
    final hoy = ref.watch(hoyProvider);

    return hogar.when(
      loading: () => const EstadoCargando(),
      error: (e, _) =>
          EstadoError(e, alReintentar: () => ref.invalidate(hogarProvider)),
      data: (h) => _Contenido(hogar: h, hoy: hoy),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.hogar, required this.hoy});
  final Hogar hogar;
  final DateTime hoy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vistas = vistasDe(hogar, hoy);
    final decidir = vistas.where((v) => v.porDecidir).length;
    final persona = hogar.personas.firstOrNull;
    final nombre = hogar.perfil?.primerNombre ?? '';

    if (vistas.isEmpty) {
      return EstadoVacio(alAgregar: () => context.push('/tratamiento/nuevo'));
    }

    final titular = vistas.length == 1 && persona != null
        ? persona.primerNombre
        : 'tu familia';
    final titulo = decidir > 0
        ? (decidir == 1
              ? 'Un tratamiento de $titular necesita que decidas hoy'
              : '$decidir tratamientos necesitan que decidas hoy')
        : vistas.every((v) => v.estado == EstadoTratamiento.cubierto)
        ? 'Todo al día. Seguimos pendientes.'
        : 'Estamos gestionando tus medicamentos';

    return Pantalla(
      conVolver: false,
      accion: BotonTexto(
        'Agregar',
        icono: Icono.mas,
        alPulsar: () => context.push('/tratamiento/nuevo'),
      ),
      contexto: persona?.nombre,
      hijos: [
        Text('Hola, $nombre · ${fechaLarga(hoy)}', style: Letra.secundario),
        const SizedBox(height: 12),
        Semantics(header: true, child: Text(titulo, style: Letra.display)),
        const SizedBox(height: 24),
        for (final (i, v) in vistas.indexed) ...[
          if (i > 0) const Separador(),
          _Fila(vista: v),
        ],
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.vista});
  final VistaTratamiento vista;

  @override
  Widget build(BuildContext context) {
    final v = vista;
    final p = v.proyeccion;
    final sinDosis = p.diasRestantes <= 0;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => context.push('/tratamiento/${v.t.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: v.t.nombre,
                        children: [
                          if (v.t.concentracion.isNotEmpty)
                            TextSpan(
                              text: ' ${v.t.concentracion}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                color: Tinta.apagada,
                              ),
                            ),
                        ],
                      ),
                      style: Letra.seccion,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SelloDeTratamiento(v.estado),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${p.diasRestantes}',
                    style: Letra.display.tabular.copyWith(
                      color: sinDosis ? Tinta.riesgo : Tinta.tinta,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p.diasRestantes == 1
                          ? 'día de dosis · hasta el ${fechaCorta(p.agotamiento)}'
                          : 'días de dosis · hasta el ${fechaCorta(p.agotamiento)}',
                      style: Letra.secundario.tabular,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ExcludeSemantics(
                child: TiraDosis(
                  diasRestantes: p.diasRestantes,
                  fechaAgotamiento: fechaMinima(p.agotamiento),
                  asegurada: v.asegurada,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                v.contexto,
                style: Letra.secundario.copyWith(color: Tinta.suave),
              ),
              if (v.porDecidir && v.ciclo != null) ...[
                const SizedBox(height: 14),
                Boton(
                  v.opciones.isEmpty ? 'Ver cómo va' : 'Ver mis opciones',
                  ancho: false,
                  alPulsar: () => context.push('/ciclo/${v.ciclo!.id}'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
