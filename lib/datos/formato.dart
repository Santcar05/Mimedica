import 'package:intl/intl.dart';

const _es = 'es';

String _sinPuntos(String s) => s.replaceAll('.', '');

/// «sábado 3 de octubre»
String fechaLarga(DateTime d) => DateFormat("EEEE d 'de' MMMM", _es).format(d);

/// «sáb 3 oct»
String fechaCorta(DateTime d) =>
    _sinPuntos(DateFormat('EEE d MMM', _es).format(d));

/// «3 oct»
String fechaMinima(DateTime d) =>
    _sinPuntos(DateFormat('d MMM', _es).format(d));

/// «3 oct 2026»
String fechaConAnio(DateTime d) =>
    _sinPuntos(DateFormat('d MMM y', _es).format(d));

/// «octubre»
String mes(DateTime d) => DateFormat('MMMM', _es).format(d);

/// «14 / 03 / 1991»
String fechaNumerica(DateTime d) => DateFormat('dd / MM / y').format(d);

/// «$ 18.400»
String pesos(int valor) =>
    '\$ ${NumberFormat.decimalPattern('es_CO').format(valor)}';

/// «2 días», «1 día»
String dias(int n) => '$n ${n == 1 ? 'día' : 'días'}';

/// «en 2 días», «mañana», «hoy»
String enCuanto(int n) => switch (n) {
  <= 0 => 'hoy',
  1 => 'mañana',
  _ => 'en $n días',
};

/// Oculta la parte local del correo: «c•••@gmail.com».
String correoVelado(String correo) {
  final arroba = correo.indexOf('@');
  if (arroba <= 0) return correo;
  return '${correo[0]}•••${correo.substring(arroba)}';
}

String mayusculaInicial(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
