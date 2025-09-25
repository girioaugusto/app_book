// lib/root_shell.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/tabs_controller.dart';
import 'providers/library_provider.dart';

// Telas
import 'screens/home_presentation.dart'; // 0 - Home
import 'screens/home_screen.dart';       // 1 - Buscar
import 'screens/favorites_screen.dart';  // 2 - Favoritos
import 'screens/reading_screen.dart';    // 3 - Ler/Lido
import 'screens/cafes_screen.dart';      // 4 - Cafés
import 'screens/book_details_screen.dart'; // 👈 para navegar aos detalhes

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<TabsController>().index;

    final pages = <Widget>[
      const HomePresentation(),
      const HomeScreen(),
      const FavoritesScreen(),
      ReadingScreen(
        toRead: context.watch<LibraryProvider>().toRead,
        read: context.watch<LibraryProvider>().read,
        onOpenDetails: (book) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
          );
        },
      ),
      const CafesScreen(),
    ];

    final safeIndex = pages.isEmpty ? 0 : math.min(selected, pages.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: [
          // ✅ Só a aba ativa participa de animações Hero (evita tags duplicadas)
          for (var i = 0; i < pages.length; i++)
            HeroMode(
              enabled: i == safeIndex,
              child: pages[i],
            ),
        ],
      ),
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
