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

    final light = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      useMaterial3: true,
    );

    final dark = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
      useMaterial3: true,
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
