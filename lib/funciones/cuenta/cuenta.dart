import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/entorno.dart';
import '../../app/tema.dart';
import '../../datos/avisos.dart';
import '../../datos/formato.dart';
import '../../datos/hogar.dart';
import '../../datos/repositorio.dart';
import '../../nucleo/widgets/boton.dart';
import '../../nucleo/widgets/controles.dart';
import '../../nucleo/widgets/filas.dart';
import '../../nucleo/widgets/icono.dart';
import '../../nucleo/widgets/nota.dart';
import '../../nucleo/widgets/pantalla.dart';
import '../estados/estados.dart';
import '../ingreso/documento_legal.dart';

const _version = '0.1.1';

/// G-01 a G-06 reunidos: perfil, privacidad, avisos, ayuda y salida.
class Cuenta extends ConsumerWidget {
  const Cuenta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hogar = ref.watch(hogarProvider);
    return hogar.when(
      loading: () => const EstadoCargando(),
      error: (e, _) =>
          EstadoError(e, alReintentar: () => ref.invalidate(hogarProvider)),
      data: (h) => _Contenido(hogar: h),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.hogar});
  final Hogar hogar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = hogar.perfil;
    final correo = ref.watch(accesoProvider).correo;

    Future<void> cerrarSesion() async {
      try {
        await ref.read(accesoProvider).cerrar();
      } on Fallo catch (f) {
        if (context.mounted) _aviso(context, f.mensaje);
      }
    }

    return Pantalla(
      conVolver: false,
      hijos: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Tinta.azulSuave,
                borderRadius: radio,
                border: Border.all(color: Tinta.azulLinea),
              ),
              child: Text(
                perfil?.iniciales ?? '',
                style: Letra.seccion.copyWith(color: Tinta.azulHondo),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      perfil?.nombre ?? 'Tu cuenta',
                      style: Letra.titulo,
                    ),
                  ),
                  if (correo != null) Text(correo, style: Letra.secundario),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilaEnlace(
          'Privacidad y datos',
          icono: Icono.escudo,
          alPulsar: () =>
              abrirHoja(context, constructor: (_) => const _HojaPrivacidad()),
        ),
        FilaEnlace(
          'Notificaciones',
          icono: Icono.campana,
          alPulsar: () =>
              abrirHoja(context, constructor: (_) => const _HojaAvisos()),
        ),
        FilaEnlace(
          'Ayuda y soporte',
          icono: Icono.info,
          alPulsar: () =>
              abrirHoja(context, constructor: (_) => const _HojaAyuda()),
        ),
        FilaEnlace(
          'Qué hacemos y qué no',
          icono: Icono.documento,
          alPulsar: () => abrirDocumento(context, Legal.terminos),
        ),
        FilaEnlace(
          'Cerrar sesión',
          icono: Icono.salir,
          conFlecha: false,
          alPulsar: cerrarSesion,
        ),
        FilaEnlace(
          'Eliminar mi cuenta y mis datos',
          icono: Icono.papelera,
          color: Tinta.riesgo,
          conFlecha: false,
          alPulsar: () => _eliminar(context, ref),
        ),
        const SizedBox(height: 24),
        Text(
          'Mimedica $_version · versión piloto'
          '${Entorno.conServidor ? '' : ' · modo de prueba sin servidor'}',
          style: Letra.secundario,
        ),
      ],
    );
  }

  void _aviso(BuildContext context, String texto) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _eliminar(BuildContext context, WidgetRef ref) async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Eliminar tu cuenta y tus datos?',
          style: Letra.seccion,
        ),
        content: const Text(
          'Borramos tus datos, los de las personas que cuidas y las fotos '
          'de las fórmulas. No se puede deshacer.',
          style: Letra.cuerpo,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sí, eliminar todo',
              style: TextStyle(color: Tinta.riesgo),
            ),
          ),
        ],
      ),
    );
    if (seguro != true) return;
    try {
      await Avisos.instancia.cancelarTodo();
      await ref.read(hogarProvider.notifier).eliminarCuenta();
    } on Fallo catch (f) {
      if (context.mounted) _aviso(context, f.mensaje);
    }
  }
}

class _HojaPrivacidad extends ConsumerWidget {
  const _HojaPrivacidad();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(hogarProvider).value?.perfil;
    if (perfil == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Privacidad y datos', style: Letra.titulo),
        const SizedBox(height: 4),
        const Text(
          'Qué guardamos, para qué, y cómo lo apagas.',
          style: Letra.secundario,
        ),
        const SizedBox(height: 8),
        Interruptor(
          titulo: 'Usar mis datos para prestar el servicio',
          etiqueta: 'Necesaria',
          detalle: perfil.autorizo
              ? 'Autorizado el ${fechaConAnio(perfil.autorizoServicioEl!)}.'
              : 'No autorizado.',
          valor: perfil.autorizo,
          fijo: perfil.autorizo,
        ),
        const Separador(),
        Interruptor(
          titulo: 'Usarlos sin mi nombre para estadísticas',
          etiqueta: 'Opcional',
          detalle: 'Puedes cambiarla cuando quieras.',
          valor: perfil.autorizaEstadistica,
          alCambiar: (v) =>
              ref.read(hogarProvider.notifier).cambiarEstadistica(v),
        ),
        const SizedBox(height: 8),
        BotonTexto(
          'Leer la política de datos',
          alPulsar: () => abrirDocumento(context, Legal.datos),
        ),
        const SizedBox(height: 8),
        Boton(
          'Revocar mi autorización',
          estilo: EstiloBoton.peligroSuave,
          alPulsar: () async {
            Navigator.pop(context);
            await ref.read(hogarProvider.notifier).revocarAutorizacion();
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Si revocas, dejamos de calcular fechas y de avisarte. Tus datos '
          'siguen guardados hasta que elimines la cuenta.',
          style: Letra.secundario,
        ),
      ],
    );
  }
}

class _HojaAvisos extends StatefulWidget {
  const _HojaAvisos();

  @override
  State<_HojaAvisos> createState() => _HojaAvisosState();
}

class _HojaAvisosState extends State<_HojaAvisos> {
  bool? _concedido;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Notificaciones', style: Letra.titulo),
        const SizedBox(height: 12),
        const ListaVistos([
          'Un aviso el día D-10, cuando empezamos a gestionar un medicamento.',
          'Otro aviso tres días antes de que se acabe, si el ciclo sigue '
              'abierto.',
          'Nada de publicidad.',
        ]),
        const SizedBox(height: 16),
        if (_concedido == false)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Nota(
              tono: TonoNota.aviso,
              texto:
                  'Este teléfono no permitió los avisos. Actívalos desde los '
                  'ajustes de Mimedica.',
            ),
          ),
        if (_concedido == true)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Nota(texto: 'Listo: los avisos están activados.'),
          ),
        Boton(
          'Activar los avisos',
          estilo: EstiloBoton.secundario,
          icono: Icono.campana,
          alPulsar: () async {
            final ok = await Avisos.instancia.pedirPermiso();
            if (mounted) setState(() => _concedido = ok);
          },
        ),
      ],
    );
  }
}

class _HojaAyuda extends StatelessWidget {
  const _HojaAyuda();

  @override
  Widget build(BuildContext context) {
    final conCanal = Entorno.soporteCorreo.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Ayuda y soporte', style: Letra.titulo),
        const SizedBox(height: 12),
        Text(
          conCanal
              ? 'Escríbenos y una persona del equipo te responde.'
              : 'Cuéntale a la persona del equipo que te entregó la app qué '
                    'pasó. Si algo no se entiende, también nos sirve saberlo.',
          style: Letra.cuerpo.copyWith(color: Tinta.suave),
        ),
        if (conCanal) ...[
          const SizedBox(height: 16),
          Boton(
            'Escribir al equipo',
            icono: Icono.correo,
            estilo: EstiloBoton.secundario,
            alPulsar: () =>
                launchUrl(Uri(scheme: 'mailto', path: Entorno.soporteCorreo)),
          ),
        ],
      ],
    );
  }
}
