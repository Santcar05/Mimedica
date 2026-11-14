import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/tema.dart';
import '../../datos/calculo_agotamiento.dart';
import '../../datos/formato.dart';
import '../../datos/hogar.dart';
import '../../datos/modelos.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/campo.dart';
import '../../nucleo/widgets/controles.dart';
import '../../nucleo/widgets/estado_visual.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/nota.dart';
import '../../nucleo/widgets/pantalla.dart';
import '../../nucleo/widgets/sello_estado.dart';

enum _Orden { cercania, precio }

/// C-02 a C-06: el ciclo de reposición de un medicamento. Muestra qué se ha
/// averiguado y, cuando el equipo ya verificó puntos con existencias, las
/// opciones para que el cuidador decida. Mimedica no recomienda ninguna.
class CicloVista extends ConsumerStatefulWidget {
  const CicloVista({super.key, required this.id});
  final String id;

  @override
  ConsumerState<CicloVista> createState() => _CicloVistaState();
}

class _CicloVistaState extends ConsumerState<CicloVista> {
  _Orden _orden = _Orden.cercania;

  Future<void> _abrir(Uri uri) async {
    var abierto = false;
    try {
      abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!abierto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrirlo desde este teléfono.'),
        ),
      );
    }
  }

  List<Opcion> _ordenadas(List<Opcion> opciones) {
    final lista = [...opciones];
    lista.sort(
      (a, b) => switch (_orden) {
        _Orden.cercania => (a.distanciaKm ?? 99).compareTo(b.distanciaKm ?? 99),
        _Orden.precio => (a.precio ?? 0).compareTo(b.precio ?? 0),
      },
    );
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final hogar = ref.watch(hogarProvider).value;
    final ciclo = hogar?.ciclo(widget.id);
    final t = ciclo == null ? null : hogar!.tratamiento(ciclo.tratamientoId);
    if (hogar == null || ciclo == null || t == null) {
      return const Pantalla(hijos: []);
    }

    final hoy = ref.watch(hoyProvider);
    final persona = hogar.persona(t.personaId);
    final propio = persona?.esTitular ?? false;
    final p = proyectar(t, hoy);
    final opciones = _ordenadas(hogar.opcionesDe(ciclo.id));
    final eps = persona?.eps ?? 'la EPS';
    final estado = estadoDe(t, p, ciclo: ciclo);
    final de = propio ? 'tuyo' : 'de ${persona?.primerNombre}';

    return Pantalla(
      contexto: t.titulo,
      hijos: [
        if (ciclo.estado == EstadoCiclo.cerrado)
          const SelloEstado('Ciclo cerrado', tono: TonoEstado.ok)
        else
          SelloDeTratamiento(estado),
        const SizedBox(height: 12),
        Cabecera(
          opciones.isEmpty
              ? 'Seguimos buscándolo'
              : 'Opciones para el ${t.nombre} $de',
          bajada: opciones.isEmpty
              ? 'Estamos averiguando dónde está. Aquí te contamos en cuanto '
                    'sepamos algo.'
              : 'Verificamos que estos puntos lo tienen. No recomendamos '
                    'ninguno: decides tú.',
        ),
        const SizedBox(height: 24),
        _Seguimiento(ciclo: ciclo, eps: eps, opciones: opciones.length),
        if (opciones.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Rotulo('Ordenar por'),
          const SizedBox(height: 8),
          Segmentos<_Orden>(
            opciones: const {
              _Orden.cercania: 'Cercanía',
              _Orden.precio: 'Precio',
            },
            valor: _orden,
            alCambiar: (o) => setState(() => _orden = o),
          ),
          const SizedBox(height: 8),
          for (final o in opciones) ...[
            const Separador(),
            _FilaOpcion(
              opcion: o,
              hoy: hoy,
              alLlegar: o.direccion == null
                  ? null
                  : () => _abrir(
                      Uri.https('www.google.com', '/maps/search/', {
                        'api': '1',
                        'query': '${o.nombre} ${o.direccion}',
                      }),
                    ),
              alLlamar: o.telefono == null
                  ? null
                  : () => _abrir(Uri(scheme: 'tel', path: o.telefono)),
            ),
          ],
        ],
        if (ciclo.enCurso && opciones.isEmpty && p.diasRestantes <= 5) ...[
          const SizedBox(height: 24),
          Nota(
            tono: TonoNota.aviso,
            titulo: 'Quedan ${dias(p.diasRestantes)} de dosis',
            texto:
                'Si ya fuiste y no te lo entregaron, déjalo registrado. Es la '
                'prueba que necesitas para reclamar.',
            accion: BotonTexto(
              'Registrar lo que no entregaron',
              alPulsar: () => context.push('/pendientes/nuevo', extra: t.id),
            ),
          ),
        ],
      ],
      pie: [
        if (ciclo.enCurso)
          Boton(
            'Ya lo conseguí',
            icono: Icono.check,
            alPulsar: () => context.push(
              '/entrega/${t.id}',
              extra: opciones.firstOrNull?.tipo == TipoOpcion.drogueria
                  ? OrigenEntrega.particular
                  : OrigenEntrega.eps,
            ),
          )
        else
          Boton('Volver al tratamiento', alPulsar: () => context.pop()),
      ],
    );
  }
}

class _Seguimiento extends StatelessWidget {
  const _Seguimiento({
    required this.ciclo,
    required this.eps,
    required this.opciones,
  });

  final Ciclo ciclo;
  final String eps;
  final int opciones;

  @override
  Widget build(BuildContext context) {
    final pasos = <(String, String, bool)>[
      (
        'Abrimos el ciclo',
        'El ${fechaCorta(ciclo.abiertoEl)}.',
        true,
      ),
      (
        'Consulta a $eps',
        ciclo.nota ?? 'En curso. Todavía no tenemos respuesta.',
        ciclo.nota != null,
      ),
      (
        'Opciones verificadas',
        opciones == 0
            ? 'Aún no hay puntos confirmados con existencias.'
            : '$opciones ${opciones == 1 ? 'punto confirmado' : 'puntos confirmados'}.',
        opciones > 0,
      ),
    ];

    return Column(
      children: [
        for (final (i, (titulo, texto, hecho)) in pasos.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: hecho ? Tinta.azul : Tinta.papel,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: hecho ? Tinta.azul : Tinta.lineaFuerte,
                            width: 1.5,
                          ),
                        ),
                      ),
                      if (i < pasos.length - 1)
                        const Expanded(
                          child: VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: Tinta.lineaFuerte,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: Letra.cuerpoFuerte),
                        const SizedBox(height: 2),
                        Text(
                          texto,
                          style: Letra.secundario.copyWith(color: Tinta.suave),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FilaOpcion extends StatelessWidget {
  const _FilaOpcion({
    required this.opcion,
    required this.hoy,
    this.alLlegar,
    this.alLlamar,
  });

  final Opcion opcion;
  final DateTime hoy;
  final VoidCallback? alLlegar;
  final VoidCallback? alLlamar;

  @override
  Widget build(BuildContext context) {
    final o = opcion;
    final detalle = [
      if (o.direccion != null) o.direccion!,
      if (o.distanciaKm != null) distancia(o.distanciaKm!),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.nombre, style: Letra.seccion),
                    if (detalle.isNotEmpty)
                      Text(detalle, style: Letra.secundario),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    o.precio == null ? 'Sin costo' : pesos(o.precio!),
                    style: Letra.seccion.tabular,
                  ),
                  Text(
                    o.tipo == TipoOpcion.eps ? 'EPS' : 'Droguería',
                    style: Letra.secundario,
                  ),
                ],
              ),
            ],
          ),
          if (o.verificadoEl != null) ...[
            const SizedBox(height: 6),
            Text(
              'Verificado ${cuando(o.verificadoEl!, hoy)}',
              style: Letra.secundario.copyWith(color: Tinta.ok),
            ),
          ],
          if (alLlegar != null || alLlamar != null)
            Row(
              children: [
                if (alLlegar != null)
                  BotonTexto(
                    'Cómo llegar',
                    icono: Icono.ruta,
                    alPulsar: alLlegar,
                  ),
                if (alLlegar != null && alLlamar != null)
                  const SizedBox(width: 16),
                if (alLlamar != null)
                  BotonTexto(
                    'Llamar',
                    icono: Icono.telefono,
                    alPulsar: alLlamar,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
