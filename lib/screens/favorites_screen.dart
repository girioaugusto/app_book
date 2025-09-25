// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:livros_app/models/book.dart';
import 'package:livros_app/providers/library_provider.dart';
import 'package:livros_app/screens/book_details_screen.dart';
import 'package:livros_app/providers/tabs_controller.dart'; // 👈 para trocar para a aba Buscar

enum _SortMode { recent, title, author }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  _SortMode _mode = _SortMode.recent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lib = context.watch<LibraryProvider>();
    final favorites = List<Book>.from(lib.favorites);

    // Ordenação local
    switch (_mode) {
      case _SortMode.recent:
        break; // mantém ordem atual
      case _SortMode.title:
        favorites.sort((a, b) => (a.title ?? '')
            .toLowerCase()
            .compareTo((b.title ?? '').toLowerCase()));
        break;
      case _SortMode.author:
        String a1(Book b) => (b.authors?.isNotEmpty ?? false)
            ? b.authors!.first.toLowerCase()
            : 'zzz';
        favorites.sort((a, b) => a1(a).compareTo(a1(b)));
        break;
    }

    final favCountLabel =
        '${favorites.length}\u00A0${favorites.length == 1 ? 'favorito' : 'favoritos'}';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 84, // deixa o título respirar
        title: Text(
          'Favoritos 💖',
          style: GoogleFonts.lobster(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: cs.primary, // verde do tema
            height: 1.1,
          ),
        ),
        actions: [
          if (favorites.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'clear') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Limpar favoritos?'),
                      content: const Text(
                          'Essa ação removerá todos os livros dos seus favoritos.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Limpar'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    for (final b in List<Book>.from(favorites)) {
                      await context.read<LibraryProvider>().toggleFavorite(b);
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Favoritos limpos')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined),
                      SizedBox(width: 12),
                      Text('Limpar todos'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: favorites.isEmpty
            ? _EmptyState(
                onExplore: () =>
                    context.read<TabsController>().setIndex(1), // 👉 vai para Buscar
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho com contagem + chips
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          favCountLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _SortChips(
                        mode: _mode,
                        onChanged: (m) => setState(() => _mode = m),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Grid (tap abre detalhes, long-press remove com Undo)
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: favorites.length,
                      itemBuilder: (_, i) {
                        final b = favorites[i];
                        return _FavCard(
                          book: b,
                          onOpen: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BookDetailsScreen(book: b),
                              ),
                            );
                          },
                          onRemove: () async {
                            await context
                                .read<LibraryProvider>()
                                .toggleFavorite(b);
                            if (!mounted) return;
                            final removed = b;
                            final messenger =
                                ScaffoldMessenger.of(context);
                            messenger.clearSnackBars();
                            messenger.showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  '"${_shortTitle(removed.title)}" removido dos favoritos',
                                ),
                                action: SnackBarAction(
                                  label: 'Desfazer',
                                  onPressed: () {
                                    context
                                        .read<LibraryProvider>()
                                        .toggleFavorite(removed);
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _shortTitle(String? t) {
    final s = (t ?? '').trim();
    if (s.length <= 40) return s.isEmpty ? 'Sem título' : s;
    return '${s.substring(0, 37)}...';
  }
}

/// Estado vazio
class _EmptyState extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptyState({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📚💖', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text(
            'Você ainda não tem favoritos',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Salve os livros que mais curtir para acessar rapidinho por aqui.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onExplore,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Explorar livros'),
          ),
        ],
      ),
    );
  }
}

/// Chips para alternar ordenação — estilizadas no verde do tema
class _SortChips extends StatelessWidget {
  final _SortMode mode;
  final ValueChanged<_SortMode> onChanged;
  const _SortChips({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: c.primary,                 // ✅ selecionado: verde
        labelStyle: TextStyle(
          color: selected ? c.onPrimary : c.primary,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
        backgroundColor: Colors.transparent,
        side: BorderSide(color: c.primary.withOpacity(0.75)), // borda verde
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
    }

    return Wrap(
      spacing: 6,
      children: [
        chip(
          label: 'Recentes',
          selected: mode == _SortMode.recent,
          onTap: () => onChanged(_SortMode.recent),
        ),
        chip(
          label: 'Título',
          selected: mode == _SortMode.title,
          onTap: () => onChanged(_SortMode.title),
        ),
        chip(
          label: 'Autor',
          selected: mode == _SortMode.author,
          onTap: () => onChanged(_SortMode.author),
        ),
      ],
    );
  }
}

/// Card de favorito (SEM botões; ações ficam nos detalhes)
class _FavCard extends StatelessWidget {
  final Book book;
  final VoidCallback onOpen;
  final VoidCallback onRemove; // remove dos favoritos com Undo

  const _FavCard({
    required this.book,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lib = context.watch<LibraryProvider>();

    final title =
        (book.title ?? '').trim().isEmpty ? 'Sem título' : book.title!.trim();
    final authors = (book.authors?.isNotEmpty ?? false)
        ? book.authors!.join(', ')
        : 'Autor desconhecido';
    final coverUrl = _tunedCoverUrl(book.thumbnail);

    // estado de leitura (só indicador visual)
    final inToRead = lib.isInToRead(book.id);
    final inRead = lib.isInRead(book.id);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onOpen,
      onLongPress: onRemove, // long press remove favorito com Undo
      child: Ink(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Capa + selo de favorito
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: coverUrl != null
                      ? Hero(
                          tag: 'cover_${book.id}',
                          child: Image.network(
                            coverUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          ),
                        )
                      : Container(
                          height: 160,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cs.surfaceVariant,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: Icon(Icons.menu_book_rounded,
                              color: cs.onSurfaceVariant),
                        ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.favorite, color: cs.onPrimary, size: 16),
                  ),
                ),
              ],
            ),

            // Texto
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authors,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _categoriesInline(book),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (inRead)
                          Icon(Icons.check_circle, size: 16, color: cs.primary)
                        else if (inToRead)
                          Icon(Icons.bookmark_added,
                              size: 16, color: cs.onSurfaceVariant),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoriesInline(Book b) {
    final cats = b.categories ?? const <String>[];
    if (cats.isEmpty) return 'Sem categoria';
    return cats.take(2).join(' • ');
  }

  String? _tunedCoverUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    var u = url.replaceFirst('http://', 'https://');
    if (RegExp(r'zoom=\d').hasMatch(u)) {
      u = u.replaceAll(RegExp(r'zoom=\d'), 'zoom=1');
    } else {
      final sep = u.contains('?') ? '&' : '?';
      u = '$u${sep}zoom=1';
    }
    return u;
  }
}
