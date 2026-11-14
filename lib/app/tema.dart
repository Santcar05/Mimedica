import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class Tinta {
  static const papel = Color(0xFFFAFBFC);
  static const papelHondo = Color(0xFFF6F8FA);
  static const superficie = Color(0xFFF1F5F8);
  static const linea = Color(0xFFDFE6EC);
  static const lineaFuerte = Color(0xFFC6D2DC);

  static const tinta = Color(0xFF0C1B27);
  static const suave = Color(0xFF2B3F4D);
  static const apagada = Color(0xFF56707F);
  static const tenue = Color(0xFF7B90A3);

  static const azul = Color(0xFF1B5299);
  static const azulHondo = Color(0xFF113A72);
  static const azulSuave = Color(0xFFE7EFF8);
  static const azulLinea = Color(0xFFA9C4E0);

  static const ok = Color(0xFF2C7454);
  static const espera = Color(0xFF985D16);
  static const riesgo = Color(0xFFB23A32);
  static const okSuave = Color(0xFFE6F1EB);
  static const esperaSuave = Color(0xFFF8EFE2);
  static const riesgoSuave = Color(0xFFF8E9E7);

  static const velo = Color(0x700C1B27);
}

abstract final class Ritmo {
  static const micro = Duration(milliseconds: 120);
  static const ui = Duration(milliseconds: 220);
  static const panel = Duration(milliseconds: 320);
  static const pagina = Duration(milliseconds: 480);

  static const salida = Cubic(0.16, 1, 0.3, 1);
  static const entraSale = Cubic(0.4, 0, 0.2, 1);
  static const cajon = Cubic(0.32, 0.72, 0, 1);
}

const radio = BorderRadius.all(Radius.circular(2));

/// Los botones son más redondeados que el resto: se reconocen como pulsables.
const radioBoton = BorderRadius.all(Radius.circular(8));
const margen = 20.0;

abstract final class Letra {
  static const _familia = 'General Sans';
  static const _tabular = [FontFeature.tabularFigures()];

  static const display = TextStyle(
    fontFamily: _familia,
    fontSize: 28,
    height: 1.12,
    letterSpacing: -0.62,
    fontWeight: FontWeight.w500,
    color: Tinta.tinta,
  );
  static const titulo = TextStyle(
    fontFamily: _familia,
    fontSize: 22,
    height: 1.2,
    letterSpacing: -0.4,
    fontWeight: FontWeight.w500,
    color: Tinta.tinta,
  );
  static const seccion = TextStyle(
    fontFamily: _familia,
    fontSize: 17,
    height: 1.3,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w500,
    color: Tinta.tinta,
  );
  static const cuerpo = TextStyle(
    fontFamily: _familia,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: Tinta.tinta,
  );
  static const cuerpoFuerte = TextStyle(
    fontFamily: _familia,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: Tinta.tinta,
  );
  static const secundario = TextStyle(
    fontFamily: _familia,
    fontSize: 13.5,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: Tinta.apagada,
  );
  static const rotulo = TextStyle(
    fontFamily: _familia,
    fontSize: 11,
    height: 1,
    letterSpacing: 0.88,
    fontWeight: FontWeight.w500,
    color: Tinta.apagada,
  );
  static const entrada = TextStyle(
    fontFamily: _familia,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w400,
    color: Tinta.tinta,
    fontFeatures: _tabular,
  );
  static const cifra = TextStyle(
    fontFamily: _familia,
    fontSize: 40,
    height: 1,
    letterSpacing: -1,
    fontWeight: FontWeight.w500,
    color: Tinta.tinta,
    fontFeatures: _tabular,
  );
}

extension Numeros on TextStyle {
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

ThemeData temaMimedica() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'General Sans',
    scaffoldBackgroundColor: Tinta.papel,
    colorScheme: const ColorScheme.light(
      primary: Tinta.azul,
      onPrimary: Tinta.papel,
      secondary: Tinta.tinta,
      onSecondary: Tinta.papel,
      surface: Tinta.papel,
      onSurface: Tinta.tinta,
      error: Tinta.riesgo,
      onError: Tinta.papel,
      outline: Tinta.lineaFuerte,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    dividerColor: Tinta.linea,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      bodyMedium: Letra.cuerpo,
      bodyLarge: Letra.entrada,
      titleLarge: Letra.titulo,
      titleMedium: Letra.seccion,
      labelSmall: Letra.rotulo,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Tinta.papel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Tinta.azul,
      selectionColor: Tinta.azulLinea,
      selectionHandleColor: Tinta.azul,
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: Tinta.papel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radio),
      headerBackgroundColor: Tinta.tinta,
      headerForegroundColor: Tinta.papel,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Tinta.papel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radio),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
