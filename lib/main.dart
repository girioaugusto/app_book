import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/tabs_controller.dart';
import 'providers/library_provider.dart';
import 'providers/theme_controller.dart';
import 'services/auth_service.dart';
import 'data/app_database.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Carrega variáveis do .env (na raiz do projeto)
  await dotenv.load(fileName: ".env");

  // 2) Inicializa Supabase com as chaves do .env
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnon = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseUrl.isEmpty || supabaseAnon == null || supabaseAnon.isEmpty) {
    throw Exception('SUPABASE_URL ou SUPABASE_ANON_KEY ausentes no .env');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnon,
  );

  // 3) Aquece o SQLite local (como você já fazia)
  await AppDatabase.instance.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabsController()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()..init()),
        // 👇 necessário para os eventos de deep link (passwordRecovery etc.)
        ChangeNotifierProvider(create: (_) => AuthService()..init()),
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();

    final baseLight = ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light);
    final baseDark = ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark);

    final light = ThemeData(
      colorScheme: baseLight,
      useMaterial3: true,
      scaffoldBackgroundColor: baseLight.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: baseLight.primary,
        foregroundColor: baseLight.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      iconTheme: IconThemeData(color: baseLight.onSurface),
      dividerColor: baseLight.onSurface.withOpacity(0.12),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: baseLight.inverseSurface,
        contentTextStyle: TextStyle(color: baseLight.onInverseSurface),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );

    final dark = ThemeData(
      colorScheme: baseDark,
      useMaterial3: true,
      scaffoldBackgroundColor: baseDark.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: baseDark.primary,
        foregroundColor: baseDark.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      iconTheme: IconThemeData(color: baseDark.onSurface),
      dividerColor: baseDark.onSurface.withOpacity(0.12),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: baseDark.inverseSurface,
        contentTextStyle: TextStyle(color: baseDark.onInverseSurface),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseDark.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Livros App',
      theme: light,
      darkTheme: dark,
      themeMode: themeCtrl.mode,
      home: const SplashScreen(),
    );
  }
}
