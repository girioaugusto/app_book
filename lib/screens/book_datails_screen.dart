import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livros_app/models/book.dart';
import 'package:livros_app/providers/library_provider.dart';

class BookDetailsScreen extends StatelessWidget {
  final Book book;
  const BookDetailsScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final String title =
        book.title.trim().isEmpty ? 'Sem título' : book.title.trim();

    final String authorsText =
        book.authors.isNotEmpty ? book.authors.join(', ') : 'Autor desconhecido';

    final String? description =
        (book.description?.trim().isNotEmpty ?? false) ? book.description!.trim() : null;

    final List<String> categories = book.categories;
    final String priceText = _formatPrice(book.price, book.currency);
    final String? coverUrl = _tunedCoverUrl(book.thumbnail);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes')),
      body: CustomScrollView(
        slivers: [
          // Cabeçalho: capa + infos
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // capa + badge preço
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        if (coverUrl != null)
                          Image.network(
                            coverUrl,
                            width: 120,
                            height: 180,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            width: 120,
                            height: 180,
                            color: Colors.black12,
                            alignment: Alignment.center,
                            child: const Icon(Icons.menu_book, color: Colors.black38),
                          ),
                        if (priceText != '—')
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.primary.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                priceText,
                                style: TextStyle(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // título, autores, categorias
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          authorsText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: scheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                        const SizedBox(height: 12),

                        // categorias (chips)
                        if (categories.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categories
                                .map((c) => _CategoryChip(label: c, scheme: scheme))
                                .toList(),
                          )
                        else
                          _CategoryChip(label: 'Sem categoria', scheme: scheme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Resumo (quando houver)
          if (description != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Resumo'),
                    const SizedBox(height: 8),
                    Text(
                      _cleanHtml(description),
                      textAlign: TextAlign.justify,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
            ),

          // Outras obras do autor (carrossel)
          SliverToBoxAdapter(
            child: _AuthorRecommendations(
              author: _primaryAuthor(authorsText),
              currentId: book.id,
            ),
          ),
        ],
      ),
    );
  }

  String? _tunedCoverUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    var u = url.replaceFirst('http://', 'https://');
    u = u.replaceAll(RegExp(r'zoom=\d'), 'zoom=2'); // melhora nitidez
    return u;
  }

  String _formatPrice(double? amount, String? currency) {
    if (amount == null) return '—';
    final v = amount.toStringAsFixed(2);
    if (currency == null || currency.isEmpty) return v;
    return '$currency $v';
  }

  String _cleanHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _primaryAuthor(String authorsJoined) {
    if (authorsJoined.trim().isEmpty) return '';
    return authorsJoined.split(',').first.trim();
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final ColorScheme scheme;
  const _CategoryChip({required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AuthorRecommendations extends StatelessWidget {
  final String author;
  final String? currentId; // evita repetir o livro atual
  const _AuthorRecommendations({required this.author, this.currentId});

  @override
  Widget build(BuildContext context) {
    if (author.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Outras obras do autor'),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: FutureBuilder<List<Book>>(
              future: context.read<LibraryProvider>().fetchByAuthor(author),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _RecSkeleton();
                }
                if (snap.hasError) {
                  return Text(
                    'Não foi possível carregar recomendações.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                  );
                }
                final list = (snap.data ?? [])
                    .where((b) => b.id != null && b.id != currentId)
                    .toList();
                if (list.isEmpty) {
                  return Text('Nada encontrado para $author.',
                      style: Theme.of(context).textTheme.bodySmall);
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final b = list[i];
                    final url = (b.thumbnail == null || b.thumbnail!.isEmpty)
                        ? null
                        : b.thumbnail!.replaceFirst('http://', 'https://');

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookDetailsScreen(book: b),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: url != null
                                  ? Image.network(url, width: 120, height: 160, fit: BoxFit.cover)
                                  : Container(
                                      width: 120,
                                      height: 160,
                                      color: Colors.black12,
                                      alignment: Alignment.center,
                                      child:
                                          const Icon(Icons.menu_book, color: Colors.black38),
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
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
    );
  }
}

class _RecSkeleton extends StatelessWidget {
  const _RecSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => Container(
        width: 120,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
