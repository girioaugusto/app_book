import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:livros_app/screens/book_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:livros_app/providers/library_provider.dart' hide BookDetailsScreen;
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
    final cs = Theme.of(context).colorScheme;

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
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookDetailsScreen(book: book),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // AppBar única com título grande e barra de busca no "bottom"
        appBar: AppBar(
          centerTitle: true,
          toolbarHeight: 88,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Buscar livros 🔎',
            style: GoogleFonts.lobster(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: cs.primary, // verde do tema
              height: 1.1,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Buscar novamente',
              onPressed: () => lib.searchBooks(_controller.text.trim()),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(76),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Ex.: flutter, clean code…',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar',
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {});
                                },
                              ),
                      ),
                      onChanged: (_) => setState(() {}),
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
          ),
        ),

        body: body,
      ),
    );
  }
}

/// Nº de colunas por largura (responsivo)
int _columnsForWidth(double w) {
  if (w >= 1000) return 4;
  if (w >= 720) return 3;
  return 2;
}

/// Aspect ratio para caber capa + textos
double _tileAspectRatio({required int cols, required double textScale}) {
  double base;
  switch (cols) {
    case 2:
      base = 0.54;
      break;
    case 3:
      base = 0.60;
      break;
    default:
      base = 0.70;
  }
  final scale = textScale.clamp(1.0, 1.3);
  return base / scale;
}

// ----------------- Widgets auxiliares -----------------

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
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
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
            Icon(Icons.menu_book, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38)),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
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
            Icon(Icons.wifi_off, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38)),
            const SizedBox(height: 12),
            Text('Ops!', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
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
