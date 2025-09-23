// lib/root_shell.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/tabs_controller.dart';
import 'providers/library_provider.dart';

// Telas
import 'screens/home_presentation.dart'; // <- Home (agora certo)
import 'screens/home_screen.dart';       // <- Buscar
import 'screens/favorites_screen.dart';
import 'screens/reading_screen.dart';
import 'screens/cafes_screen.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<TabsController>().index;

    // Ordem das páginas = ordem das abas abaixo
    final pages = <Widget>[
      const HomePresentation(), // Home
      const HomeScreen(),       // Buscar
      const FavoritesScreen(),  // Favoritos
      ReadingScreen(            // Ler/Lido
        toRead: context.watch<LibraryProvider>().toRead,
        read: context.watch<LibraryProvider>().read,
        onOpenDetails: (book) {},
      ),
      const CafesScreen(),      // Cafés
    ];

    final safeIndex = pages.isEmpty ? 0 : math.min(selected, pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) =>
            context.read<TabsController>().setIndex(i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favoritos'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Ler/Lido'),
          NavigationDestination(icon: Icon(Icons.local_cafe), label: 'Cafés'),
        ],
      ),
    );
  }
}
