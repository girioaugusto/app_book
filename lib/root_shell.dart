import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/tabs_controller.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final index = context.watch<TabsController>().index;

    return Scaffold(
      // IndexedStack preserva o estado das telas
      body: IndexedStack(
        index: index,
        children: const [
          HomeScreen(),
          FavoritesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            context.read<TabsController>().setIndex(i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favoritos'),
        ],
      ),
    );
  }
}
