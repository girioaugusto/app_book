import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:livros_app/models/book.dart';
import 'package:livros_app/providers/library_provider.dart';
import 'package:livros_app/widgets/book_card.dart'; // ajuste o path se necessário

class ReadingScreen extends StatelessWidget {
  final List<Book> toRead; // “Ler”
  final List<Book> read;   // “Lido”
  final void Function(Book) onOpenDetails;

  const ReadingScreen({
    super.key,
    required this.toRead,
    required this.read,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '📖 Sua Leitura',
            style: GoogleFonts.lobster(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(
              fontSize: 18,
            ),
            tabs: [
              Tab(text: 'Ler'),
              Tab(text: 'Lido'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Ler: swipe → Lido
            _BooksGrid(
              books: toRead,
              onTap: onOpenDetails,
              overlayBuilder: (book) => const SizedBox.shrink(),
              buildDismissible: (book, child) => Dismissible(
                key: ValueKey('toRead-${book.id}'),
                direction: DismissDirection.endToStart,
                background: _swipeBg(
                  alignment: Alignment.centerRight,
                  icon: Icons.check_circle,
                  label: 'Marcar como Lido',
                  color: Colors.green,
                ),
                onDismissed: (_) async {
                  await context.read<LibraryProvider>().markAsRead(book);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('“${book.title}” marcado como Lido'),
                      action: SnackBarAction(
                        label: 'Desfazer',
                        onPressed: () =>
                            context.read<LibraryProvider>().moveBackToRead(book),
                      ),
                    ),
                  );
                },
                child: child,
              ),
            ),

            // Lido: swipe → Ler
            _BooksGrid(
              books: read,
              onTap: onOpenDetails,
              overlayBuilder: (book) => const _ReadBadge(),
              buildDismissible: (book, child) => Dismissible(
                key: ValueKey('read-${book.id}'),
                direction: DismissDirection.startToEnd,
                background: _swipeBg(
                  alignment: Alignment.centerLeft,
                  icon: Icons.undo,
                  label: 'Mover para Ler',
                  color: Theme.of(context).colorScheme.primary,
                ),
                onDismissed: (_) async {
                  await context.read<LibraryProvider>().moveBackToRead(book);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('“${book.title}” movido para Ler'),
                      action: SnackBarAction(
                        label: 'Desfazer',
                        onPressed: () =>
                            context.read<LibraryProvider>().markAsRead(book),
                      ),
                    ),
                  );
                },
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BooksGrid extends StatelessWidget {
  final List<Book> books;
  final void Function(Book) onTap;
  final Widget Function(Book) overlayBuilder;

  // Permite customizar o Dismissible por aba
  final Widget Function(Book, Widget) buildDismissible;

  const _BooksGrid({
    required this.books,
    required this.onTap,
    required this.overlayBuilder,
    required this.buildDismissible,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(child: Text('Sem livros ainda.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.64,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, i) {
        final book = books[i];
        final card = Stack(
          children: [
            BookCard(
              book: book,
              onTap: () => onTap(book),
              showPrice: false, // NÃO mostrar preço nas abas Ler/Lido
            ),
            Positioned.fill(child: overlayBuilder(book)),
          ],
        );
        return buildDismissible(book, card);
      },
    );
  }
}

class _ReadBadge extends StatelessWidget {
  const _ReadBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withOpacity(.45)),
          ),
          child: Text(
            'LIDO',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _swipeBg({
  required Alignment alignment,
  required IconData icon,
  required String label,
  required Color color,
}) {
  return Container(
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    color: color.withOpacity(0.12),
    child: Row(
      mainAxisAlignment:
          alignment == Alignment.centerLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (alignment == Alignment.centerLeft) ...[
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ] else ...[
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Icon(icon, color: color),
        ],
      ],
    ),
  );
}
