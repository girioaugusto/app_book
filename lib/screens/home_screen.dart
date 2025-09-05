import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livros_app/providers/library_provider.dart';
import 'package:livros_app/widgets/book_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController(text: 'flutter');

  @override
  void initState() {
    super.initState();
    // busca inicial
    Future.microtask(() {
      context.read<LibraryProvider>().searchBooks(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buscar livros'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => provider.searchBooks(_controller.text),
              tooltip: 'Buscar novamente',
            ),
          ],
        ),
        body: Column(
          children: [
            // barra de busca
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Digite um termo (ex.: flutter, clean code...)',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (q) => provider.searchBooks(q),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => provider.searchBooks(_controller.text),
                    child: const Text('Buscar'),
                  ),
                ],
              ),
            ),
            if (provider.isLoading) const LinearProgressIndicator(),
            // lista de cards
            Expanded(
              child: provider.results.isEmpty && !provider.isLoading
                  ? const Center(child: Text('Nenhum resultado.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final book = provider.results[index];
                        return BookCard(book: book);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
