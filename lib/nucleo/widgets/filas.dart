import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'icono.dart';

/// Fila de navegación de 56 px con icono, texto y flecha.
class FilaEnlace extends StatelessWidget {
  const FilaEnlace(
    this.texto, {
    super.key,
    required this.icono,
    required this.alPulsar,
    this.detalle,
    this.color = Tinta.tinta,
    this.conFlecha = true,
  });

  final String texto;
  final String? detalle;
  final Icono icono;
  final VoidCallback? alPulsar;
  final Color color;
  final bool conFlecha;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: alPulsar,
        highlightColor: Tinta.superficie,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Tinta.linea)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Trazo(icono, tam: 20, color: color == Tinta.tinta ? Tinta.apagada : color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(texto, style: Letra.cuerpo.copyWith(color: color)),
                    if (detalle != null)
                      Text(detalle!, style: Letra.secundario),
                  ],
                ),
              ),
              if (conFlecha)
                const Trazo(Icono.derecha, tam: 18, color: Tinta.apagada),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opción grande de elección única (A-06, B-04).
class TarjetaOpcion extends StatelessWidget {
  const TarjetaOpcion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.alPulsar,
    this.elegida = false,
  });

  final Icono icono;
  final String titulo;
  final String detalle;
  final VoidCallback alPulsar;
  final bool elegida;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegida,
      child: InkWell(
        onTap: alPulsar,
        borderRadius: radio,
        child: AnimatedContainer(
          duration: Ritmo.micro,
          curve: Ritmo.salida,
          padding: EdgeInsets.all(elegida ? 15 : 16),
          decoration: BoxDecoration(
            color: Tinta.papel,
            borderRadius: radio,
            border: Border.all(
              color: elegida ? Tinta.azul : Tinta.lineaFuerte,
              width: elegida ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Trazo(icono, color: Tinta.azul),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: Letra.seccion),
                    const SizedBox(height: 4),
                    Text(
                      detalle,
                      style: Letra.secundario.copyWith(color: Tinta.suave),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Trazo(
                  elegida ? Icono.check : Icono.derecha,
                  tam: 20,
                  color: elegida ? Tinta.azul : Tinta.apagada,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoja inferior con asa, entra con la curva de cajón.
Future<T?> abrirHoja<T>(
  BuildContext context, {
  required WidgetBuilder constructor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Tinta.papel,
    barrierColor: Tinta.velo,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      side: BorderSide(color: Tinta.lineaFuerte),
    ),
    sheetAnimationStyle: const AnimationStyle(
      duration: Ritmo.panel,
      curve: Ritmo.cajon,
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          margen,
          8,
          margen,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: const BoxDecoration(
                  color: Tinta.lineaFuerte,
                  borderRadius: radio,
                ),
              ),
            ),
            constructor(context),
          ],
        ),
      ),
    ),
  );
}

/// Lista de opciones dentro de una hoja; devuelve la elegida.
Future<T?> elegirEnHoja<T>(
  BuildContext context, {
  required String titulo,
  required Map<T, String> opciones,
  T? actual,
}) {
  return abrirHoja<T>(
    context,
    constructor: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(titulo, style: Letra.seccion),
        const SizedBox(height: 8),
        for (final e in opciones.entries)
          Semantics(
            button: true,
            selected: e.key == actual,
            child: InkWell(
              onTap: () => Navigator.pop(context, e.key),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Tinta.linea)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.value,
                        style: e.key == actual
                            ? Letra.cuerpoFuerte
                            : Letra.cuerpo,
                      ),
                    ),
                    if (e.key == actual)
                      const Trazo(Icono.check, tam: 20, color: Tinta.azul),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
