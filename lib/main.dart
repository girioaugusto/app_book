import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/tabs_controller.dart';
import 'providers/library_provider.dart';
import 'providers/theme_controller.dart';       // 👈 NOVO
import 'services/auth_service.dart';
import 'data/app_database.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database; // warm-up sqlite
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabsController()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()..init()),
        ChangeNotifierProvider(create: (_) => AuthService()..loadSession()),
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),   // 👈 NOVO
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

    // Bases de esquema
    final baseLight = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.light,
    );
    final baseDark = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
    );

    // 🔆 Tema claro (visual preservado)
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
        // No claro seguimos com um "branco" visual nos campos:
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );

    // 🌙 Tema escuro (legibilidade corrigida)
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
      // Campos de texto no dark deixam de ficar "brancos fixos"
      // e passam a usar as superfícies do tema (sem mudar layout):
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseDark.surface, // melhora contraste no dark
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
