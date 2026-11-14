import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/entorno.dart';
import 'app/router.dart';
import 'app/tema.dart';
import 'datos/hogar.dart';
import 'datos/repositorio.dart';
import 'datos/repositorio_local.dart';
import 'datos/repositorio_supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await initializeDateFormatting('es_CO');

  final Repositorio repositorio;
  final Acceso acceso;
  if (Entorno.conServidor) {
    await Supabase.initialize(
      url: Entorno.supabaseUrl,
      publishableKey: Entorno.supabaseAnonKey,
    );
    repositorio = RepositorioSupabase(Supabase.instance.client);
    acceso = AccesoSupabase(Supabase.instance.client);
  } else {
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioLocal(prefs);
    acceso = AccesoLocal(prefs);
  }

  runApp(
    ProviderScope(
      overrides: [
        repositorioProvider.overrideWithValue(repositorio),
        accesoProvider.overrideWithValue(acceso),
      ],
      child: const Mimedica(),
    ),
  );
}

class Mimedica extends ConsumerWidget {
  const Mimedica({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Mimedica',
      debugShowCheckedModeBanner: false,
      theme: temaMimedica(),
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
