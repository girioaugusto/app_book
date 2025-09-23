import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/tabs_controller.dart';
import 'providers/library_provider.dart';

import 'splash_screen.dart'; 

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabsController()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()..init()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget { 
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Livros App',
      theme: base.copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: base.colorScheme.primary,
          foregroundColor: base.colorScheme.onPrimary,
          centerTitle: true,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: base.colorScheme.primaryContainer,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: base.colorScheme.primary,
            foregroundColor: base.colorScheme.onPrimary,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: base.colorScheme.primary,
            foregroundColor: base.colorScheme.onPrimary,
          ),
        ),
      ),
      home: const SplashScreen(), 

    );
  }
}
