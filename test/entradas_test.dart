import 'package:flutter_test/flutter_test.dart';
import 'package:mimedica_app/nucleo/entradas.dart';

TextEditingValue _escribir(String texto) {
  const formato = FormatoFecha();
  return formato.formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(text: texto),
  );
}

void main() {
  group('FormatoFecha', () {
    test('agrupa los dígitos como día / mes / año', () {
      expect(_escribir('14031991').text, '14 / 03 / 1991');
    });

    test('muestra solo lo escrito hasta ahora', () {
      expect(_escribir('1').text, '1');
      expect(_escribir('140').text, '14 / 0');
      expect(_escribir('14031').text, '14 / 03 / 1');
    });

    test('ignora letras y recorta lo que sobra', () {
      expect(_escribir('14a03-1991999').text, '14 / 03 / 1991');
    });
  });

  group('leerFecha', () {
    test('lee una fecha real', () {
      expect(leerFecha('14 / 03 / 1991'), DateTime(1991, 3, 14));
    });

    test('rechaza días y meses que no existen', () {
      expect(leerFecha('31 / 02 / 2026'), isNull);
      expect(leerFecha('10 / 13 / 2026'), isNull);
    });

    test('rechaza fechas incompletas', () {
      expect(leerFecha('14 / 03'), isNull);
      expect(leerFecha(''), isNull);
    });
  });

  group('leerCantidad', () {
    test('acepta coma o punto decimal', () {
      expect(leerCantidad('0,5'), 0.5);
      expect(leerCantidad('0.5'), 0.5);
      expect(leerCantidad(' 60 '), 60);
    });

    test('rechaza vacío y texto', () {
      expect(leerCantidad(''), isNull);
      expect(leerCantidad('abc'), isNull);
    });
  });
}
