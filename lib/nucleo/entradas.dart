import 'package:flutter/services.dart';

/// Escribe solo dígitos y los agrupa como «14 / 03 / 1991».
class FormatoFecha extends TextInputFormatter {
  const FormatoFecha();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    final digitos = nuevo.text.replaceAll(RegExp(r'\D'), '');
    final corto = digitos.length > 8 ? digitos.substring(0, 8) : digitos;
    final partes = [
      if (corto.isNotEmpty) corto.substring(0, corto.length.clamp(0, 2)),
      if (corto.length > 2) corto.substring(2, corto.length.clamp(2, 4)),
      if (corto.length > 4) corto.substring(4),
    ];
    final texto = partes.join(' / ');
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Lee «dd / mm / aaaa»; devuelve nulo si no es una fecha real.
DateTime? leerFecha(String texto) {
  final d = texto.replaceAll(RegExp(r'\D'), '');
  if (d.length != 8) return null;
  final dia = int.parse(d.substring(0, 2));
  final mes = int.parse(d.substring(2, 4));
  final anio = int.parse(d.substring(4));
  final fecha = DateTime(anio, mes, dia);
  if (fecha.day != dia || fecha.month != mes || fecha.year != anio) return null;
  return fecha;
}

/// Acepta «2», «0,5» y «0.5». Devuelve nulo si no es un número positivo.
double? leerCantidad(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  if (limpio.isEmpty) return null;
  final n = double.tryParse(limpio);
  return n == null || n < 0 ? null : n;
}

final soloCantidad = FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

/// Solo números y a lo sumo seis caracteres: «999,5» cabe, un cero de más no.
final formatoCantidad = <TextInputFormatter>[
  soloCantidad,
  LengthLimitingTextInputFormatter(6),
];
