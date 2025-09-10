import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/tabs_controller.dart';
import 'providers/library_provider.dart';

import 'screens/home_presentation.dart';   // ID 1
import 'screens/home_screen.dart';         // ID 2 (Buscar)
import 'screens/favorites_screen.dart';    // ID 3
import 'screens/reading_screen.dart';      // ID 4
import 'screens/book_details_screen.dart'; // detalhes

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final index = context.watch<TabsController>().index;

    final library = context.watch<LibraryProvider>();
    final toRead = library.toRead;
    final read = library.read;

    final pages = <Widget>[
      const HomePresentation(),
      const HomeScreen(),
      const FavoritesScreen(),
      ReadingScreen(
        toRead: toRead,
        read: read,
        onOpenDetails: (book) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookDetailsScreen(book: book),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.read<TabsController>().setIndex(i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favoritos'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Ler/Lido'),
        ],
      ),
    );
  }
}
