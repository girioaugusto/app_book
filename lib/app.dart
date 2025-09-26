import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/library_provider.dart';
import 'providers/tabs_controller.dart';
import 'splash_screen.dart'; // <- importe o splash



class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.light,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryProvider()..init()),
        ChangeNotifierProvider(create: (_) => TabsController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Livros App',
        theme: ThemeData(
          colorScheme: baseScheme.copyWith(
            primary: Colors.green.shade700,
            secondary: Colors.lightGreen,
            surface: Colors.white,
            background: Colors.white,
            onPrimary: Colors.white,
            onSecondary: Colors.black,
            onSurface: Colors.black87,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.robotoMono(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          textTheme: GoogleFonts.robotoMonoTextTheme(),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
