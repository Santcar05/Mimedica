import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/tema.dart';

/// Iconos de línea del sistema, con los mismos trazos de los mockups.
enum Icono {
  flecha('<path d="M4 12h15M14 7l5 5-5 5"/>'),
  volver('<path d="M14.5 5 7.5 12l7 7"/>'),
  cerrar('<path d="M6.5 6.5l11 11M17.5 6.5l-11 11"/>'),
  check('<path d="M5 12.5l4.5 4.5L19 7.5"/>'),
  alerta('<path d="M12 4 21 19.5H3Z"/><path d="M12 10v4.5M12 16.8v.5"/>'),
  info('<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5.5M12 7.6v.5"/>'),
  abajo('<path d="M6 9.5l6 6 6-6"/>'),
  derecha('<path d="M9.5 5.5 16 12l-6.5 6.5"/>'),
  mas('<path d="M12 5v14M5 12h14"/>'),
  persona(
    '<circle cx="12" cy="8.5" r="3.6"/>'
    '<path d="M4.8 20c.9-3.7 3.7-5.6 7.2-5.6s6.3 1.9 7.2 5.6"/>',
  ),
  familia(
    '<circle cx="9" cy="9" r="3.2"/>'
    '<path d="M3 19.5c.7-3.2 3-4.9 6-4.9s5.3 1.7 6 4.9"/>'
    '<path d="M15.5 6a3 3 0 0 1 0 6M17.5 14.9c1.8.6 3 2.1 3.5 4.6"/>',
  ),
  camara(
    '<path d="M4 7.5h3.5L9 5h6l1.5 2.5H20V19H4Z"/>'
    '<circle cx="12" cy="13" r="3.5"/>',
  ),
  galeria(
    '<path d="M4 5h16v14H4Z"/>'
    '<path d="M4 16l4.5-4.5 4 4 2.5-2.5L20 18"/>'
    '<circle cx="15.5" cy="9.5" r="1.5"/>',
  ),
  lapiz(
    '<path d="M4.5 19.5l1-4.2L15.8 5l3.2 3.2L8.7 18.5Z"/>'
    '<path d="M13.5 7.3l3.2 3.2"/>',
  ),
  reintentar('<path d="M19 12a7 7 0 1 1-2-4.9"/><path d="M19 4.5V8h-3.5"/>'),
  inicio('<path d="M4 10.5 12 4l8 6.5V20H4Z"/><path d="M10 20v-5.5h4V20"/>'),
  pendientes(
    '<path d="M5 4.5h14V21H5Z"/><path d="M9 4.5V3h6v1.5"/>'
    '<path d="M8.5 10h7M8.5 13.5h7M8.5 17h4"/>',
  ),
  caja(
    '<path d="M4 8l8-4 8 4v8.5l-8 4-8-4Z"/>'
    '<path d="M4 8l8 4 8-4M12 12v8.5"/>',
  ),
  documento(
    '<path d="M6 3h8.5L19 7.5V21H6Z"/><path d="M14.5 3v4.5H19"/>'
    '<path d="M9 12h7M9 15.5h7"/>',
  ),
  pausa('<path d="M9 6v12M15 6v12"/>'),
  reanudar('<path d="M8 5.5v13l10.5-6.5Z"/>'),
  papelera(
    '<path d="M5 7h14M10 7V4.5h4V7"/><path d="M7 7l.8 13h8.4L17 7"/>'
    '<path d="M10.5 11v5.5M13.5 11v5.5"/>',
  ),
  salir('<path d="M10 4.5H5v15h5"/><path d="M14 8l4 4-4 4M18 12H9"/>'),
  escudo(
    '<path d="M12 3 4.5 5.8v6.1c0 4 3 7.3 7.5 9.1 4.5-1.8 7.5-5.1 7.5-9.1V5.8Z"/>'
    '<path d="M8.8 12.1 11 14.3l4.4-4.4"/>',
  ),
  campana(
    '<path d="M6.5 16.5V11a5.5 5.5 0 0 1 11 0v5.5l1.5 2H5Z"/>'
    '<path d="M10 20.5h4"/>',
  ),
  telefono(
    '<path d="M6.5 4h3l1.5 4-2 1.2a10 10 0 0 0 5.8 5.8l1.2-2 4 1.5v3'
    'a1.5 1.5 0 0 1-1.6 1.5C10.5 18.4 5.6 13.5 5 5.6A1.5 1.5 0 0 1 6.5 4Z"/>',
  ),
  ruta(
    '<circle cx="6" cy="6.5" r="2.5"/><circle cx="18" cy="17.5" r="2.5"/>'
    '<path d="M8.5 6.5h5.5a3.5 3.5 0 0 1 0 7h-4a3.5 3.5 0 0 0 0 7h5.5"/>',
  ),
  correo('<path d="M3.5 6h17v12h-17Z"/><path d="M3.5 6.5 12 13l8.5-6.5"/>'),
  calendario(
    '<path d="M4 5.5h16V20H4Z"/><path d="M4 10h16M8.5 3.5v4M15.5 3.5v4"/>',
  ),
  sinRed(
    '<path d="M3 9.5a13 13 0 0 1 18 0M6.5 13a8 8 0 0 1 11 0"/>'
    '<path d="M12 17.5v.5M4.5 4.5l15 15"/>',
  );

  const Icono(this.trazos);
  final String trazos;
}

class Trazo extends StatelessWidget {
  const Trazo(this.icono, {super.key, this.tam = 24, this.color});

  final Icono icono;
  final double tam;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tinta =
        color ?? DefaultTextStyle.of(context).style.color ?? Tinta.tinta;
    return ExcludeSemantics(
      child: SvgPicture.string(
        '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.25" '
        'stroke-linejoin="round" stroke-linecap="round">${icono.trazos}</svg>',
        width: tam,
        height: tam,
        colorFilter: ColorFilter.mode(tinta, BlendMode.srcIn),
      ),
    );
  }
}
