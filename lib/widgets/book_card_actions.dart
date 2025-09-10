import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:livros_app/models/book.dart';
import 'package:livros_app/providers/library_provider.dart';
import 'package:livros_app/widgets/book_card.dart'; // ajuste o path se necessário

enum _MenuAction {
  addToRead,
  markAsRead,
  moveBackToRead,
  removeFromLists,
  toggleFavorite,
}

class BookCardActions extends StatelessWidget {
  const BookCardActions({
    super.key,
    required this.book,
    this.onTap,
  });

  final Book book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();

    final inToRead = lib.isInToRead(book.id);
    final inRead = lib.isInRead(book.id);
    final isFav = lib.isFavorite(book.id);

    // Ação primária dinâmica (ao lado do favorito)
    final _MenuAction primaryAction = inToRead
        ? _MenuAction.markAsRead
        : (inRead ? _MenuAction.moveBackToRead : _MenuAction.addToRead);

    final IconData primaryIcon = inToRead
        ? Icons.check_circle
        : (inRead ? Icons.undo : Icons.playlist_add);

    final String primaryTooltip = inToRead
        ? 'Marcar como Lido'
        : (inRead ? 'Mover para Ler' : 'Adicionar a Ler');

    // Itens do menu (3 pontinhos) no topo direito
    final items = <PopupMenuEntry<_MenuAction>>[
      if (!inToRead && !inRead) ...[
        _menuItem(_MenuAction.addToRead, Icons.playlist_add, 'Adicionar a Ler'),
        _menuItem(_MenuAction.markAsRead, Icons.check_circle, 'Marcar como Lido'),
      ],
      if (inToRead) ...[
        _menuItem(_MenuAction.markAsRead, Icons.check_circle, 'Marcar como Lido'),
        _menuItem(_MenuAction.removeFromLists, Icons.remove_circle_outline, 'Remover de Ler'),
      ],
      if (inRead) ...[
        _menuItem(_MenuAction.moveBackToRead, Icons.undo, 'Mover para Ler'),
        _menuItem(_MenuAction.removeFromLists, Icons.remove_circle_outline, 'Remover de Lido'),
      ],
      const PopupMenuDivider(height: 8),
      _menuItem(
        _MenuAction.toggleFavorite,
        isFav ? Icons.favorite : Icons.favorite_border,
        isFav ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
      ),
    ];

    return Stack(
      children: [
        // Usa o BookCard original (sem passar onFavorite aqui para evitar coração duplicado)
        BookCard(book: book, onTap: onTap),

        // Menu (3 pontinhos) no topo direito
        Positioned(
          right: 6,
          top: 6,
          child: Material(
            color: Colors.transparent,
            child: PopupMenuButton<_MenuAction>(
              tooltip: 'Ações',
              itemBuilder: (_) => items,
              onSelected: (action) => _handle(context, action),
              icon: const Icon(Icons.more_vert),
            ),
          ),
        ),

        // 💚 Botões lado a lado: Favorito + Ler/Lido
        Positioned(
          left: 10,
          bottom: 10,
          child: Row(
            children: [
              // Favoritar
              IconButton.filledTonal(
                tooltip: isFav ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                onPressed: () async {
                  await context.read<LibraryProvider>().toggleFavorite(book);
                  _snack(
                    context,
                    'Favoritos: ${context.read<LibraryProvider>().isFavorite(book.id) ? 'adicionado' : 'removido'}',
                  );
                },
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              // Ler/Lido (dinâmico)
              IconButton.filledTonal(
                tooltip: primaryTooltip,
                onPressed: () => _handle(context, primaryAction),
                icon: Icon(primaryIcon),
                constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<_MenuAction> _menuItem(
    _MenuAction action,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<_MenuAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }

  Future<void> _handle(BuildContext context, _MenuAction action) async {
    final lib = context.read<LibraryProvider>();
    switch (action) {
      case _MenuAction.addToRead:
        await lib.addToRead(book);
        _snackWithUndo(
          context,
          '“${book.title}” adicionado em Ler',
          onUndo: () => lib.removeFromAll(book.id),
        );
        break;

      case _MenuAction.markAsRead:
        await lib.markAsRead(book);
        _snackWithUndo(
          context,
          '“${book.title}” marcado como Lido',
          onUndo: () => lib.moveBackToRead(book),
        );
        break;

      case _MenuAction.moveBackToRead:
        await lib.moveBackToRead(book);
        _snackWithUndo(
          context,
          '“${book.title}” movido para Ler',
          onUndo: () => lib.markAsRead(book),
        );
        break;

      case _MenuAction.removeFromLists:
        await lib.removeFromAll(book.id);
        _snack(context, 'Removido de Ler/Lido');
        break;

      case _MenuAction.toggleFavorite:
        await lib.toggleFavorite(book);
        _snack(
          context,
          'Favoritos: ${lib.isFavorite(book.id) ? 'adicionado' : 'removido'}',
        );
        break;
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _snackWithUndo(
    BuildContext context,
    String msg, {
    required VoidCallback onUndo,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        action: SnackBarAction(label: 'Desfazer', onPressed: onUndo),
      ),
    );
  }
}
