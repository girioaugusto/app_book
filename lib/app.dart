import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';          // ⬅️ novo
import 'providers/library_provider.dart';
import 'providers/tabs_controller.dart';
import 'root_shell.dart';

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
            primary: Colors.green.shade700,        // verde forte (AppBar/botões)
            secondary: Colors.lightGreen,          // detalhes
            surface: Colors.white,                 // cards/folhas
            background: Colors.white,              // fundo geral
            onPrimary: Colors.white,               // texto em cima do verde
            onSecondary: Colors.black,             // contraste nos detalhes
            onSurface: Colors.black87,             // texto padrão
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.robotoMono( // “nerd/tech”
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          textTheme: GoogleFonts.robotoMonoTextTheme(), // fonte global
          useMaterial3: true,
        ),
        home: const RootShell(),
      ),
    );
  }
}
