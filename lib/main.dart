import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/tema.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Mimedica());
}

class Mimedica extends StatelessWidget {
  const Mimedica({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mimedica',
      debugShowCheckedModeBanner: false,
      theme: temaMimedica(),
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Scaffold(),
    );
  }
}
