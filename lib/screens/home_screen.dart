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
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Busca inicial após o 1º frame (evita problemas de contexto)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = _controller.text.trim();
      if (q.isNotEmpty) {
        context.read<LibraryProvider>().searchBooks(q);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();

    Widget body;
    if (lib.isLoading) {
      body = const _BooksGridSkeleton();
    } else if (lib.error != null) {
      body = _ErrorState(message: lib.error!, onRetry: lib.retry);
    } else if (lib.results.isEmpty) {
      body = const _EmptyState(
        title: 'Nada por aqui 😕',
        subtitle: 'Tente outra palavra-chave ou ajuste os filtros.',
      );
    } else {
      body = LayoutBuilder(
        builder: (ctx, c) {
          final cols = _columnsForWidth(c.maxWidth);
          return RefreshIndicator(
            onRefresh: () => lib.searchBooks(_controller.text.trim()),
            child: GridView.builder(
              controller: _scroll,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                // ↓↓↓ MAIS ALTO para caber capa + textos (evita overflow)
                childAspectRatio: _tileAspectRatio(
                  cols: cols,
                  textScale: MediaQuery.of(context).textScaleFactor,
                ),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: lib.results.length,
              itemBuilder: (context, index) {
                final book = lib.results[index];
                return BookCard(
                  book: book,
                  // se quiser ligar favoritos agora, descomente:
                  // isFavorite: lib.isFavorite(book.id),
                  // onFavorite: () => lib.toggleFavorite(book),
                  // onTap: () => Navigator.pushNamed(context, '/details', arguments: book),
                );
              },
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // fecha teclado ao tocar fora
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buscar livros'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => lib.searchBooks(_controller.text.trim()),
              tooltip: 'Buscar novamente',
            ),
          ],
        ),
        body: Column(
          children: [
            // --- BARRA DE BUSCA ---
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Digite um termo (ex.: flutter, clean code...)',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar',
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {}); // atualiza suffixIcon
                                  // opcional: limpar resultados no provider ao limpar a busca
                                  // context.read<LibraryProvider>().searchBooks('');
                                },
                              ),
                      ),
                      onChanged: (_) => setState(() {}), // atualiza suffix
                      onSubmitted: (q) => lib.searchBooks(q.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => lib.searchBooks(_controller.text.trim()),
                    child: const Text('Buscar'),
                  ),
                ],
              ),
            ),

            // --- CONTEÚDO ---
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Nº de colunas por largura (responsivo)
int _columnsForWidth(double w) {
  if (w >= 1000) return 4; // desktop/tablet grande
  if (w >= 720) return 3;  // tablet/landscape
  return 2;                // celular
}

/// Aspect ratio mais ALTO para caber capa (3:4) + textos
double _tileAspectRatio({required int cols, required double textScale}) {
  // Quanto MENOR o número → MAIS ALTO o card.
  double base;
  switch (cols) {
    case 2:
      base = 0.54; // celular (2 colunas) — alto o suficiente
      break;
    case 3:
      base = 0.60; // tablet médio
      break;
    default:
      base = 0.70; // 4 colunas ou mais
  }
  // Se o usuário aumentou o tamanho do texto no sistema, aumente a altura
  final scale = textScale.clamp(1.0, 1.3);
  return base / scale;
}

// ----------------- Widgets auxiliares: skeleton/erro/vazio -----------------

class _BooksGridSkeleton extends StatelessWidget {
  const _BooksGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final cols = _columnsForWidth(c.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: _tileAspectRatio(
              cols: cols,
              textScale: MediaQuery.of(context).textScaleFactor,
            ),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 8,
          itemBuilder: (_, __) => const _BookSkeletonCard(),
        );
      },
    );
  }
}

class _BookSkeletonCard extends StatelessWidget {
  const _BookSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book, size: 64, color: Colors.black38),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.black38),
            const SizedBox(height: 12),
            Text('Ops!', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
