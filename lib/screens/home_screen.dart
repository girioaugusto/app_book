import 'package:flutter/material.dart';
import 'package:livros_app/providers/tabs_controller.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  const Text('Buscar livros'),
        actions: [
          IconButton(
            onPressed: () => () => context.read<TabsController>().setIndex(1), 
            icon: const Icon(Icons.favorite)
          )
        ],
      ),

      body: const Center(
        child: Text('Home em construção...🚧')),
    );
  }
}