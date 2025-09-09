import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/tabs_controller.dart';
import 'screens/home_presentation.dart'; // ID 1
import 'screens/home_screen.dart';       // ID 2 (Buscar)
import 'screens/favorites_screen.dart';  // ID 3
import 'screens/reading_screen.dart';    // ID 4 (novo)

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final index = context.watch<TabsController>().index;

    final pages = const <Widget>[
      HomePresentation(), // 1 = Home (apresentação)
      HomeScreen(),       // 2 = Buscar
      FavoritesScreen(),  // 3 = Favoritos
      ReadingScreen(),    // 4 = Ler/Lido
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            context.read<TabsController>().setIndex(i),
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
