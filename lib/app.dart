import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/library_provider.dart';
import 'providers/tabs_controller.dart';
import 'root_shell.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryProvider()..init()),
        ChangeNotifierProvider(create: (_) => TabsController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Livros App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const RootShell(),
      ),
    );
  }
}
