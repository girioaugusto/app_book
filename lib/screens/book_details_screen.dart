// lib/screens/book_details_screen.dart
import 'dart:ui'; // BackdropFilter / ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:livros_app/models/book.dart';
import 'package:livros_app/providers/library_provider.dart';
import 'package:livros_app/utils/title_utils.dart';      // prettyTitle
import 'package:livros_app/utils/price_formatter.dart'; // formatPrice

class BookDetailsScreen extends StatelessWidget {
  final Book book;
  const BookDetailsScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // título bonitinho (lida com string vazia/nula)
    final t = prettyTitle((book.title ?? '').trim());

    final coverUrl = _tunedCoverUrl(book.thumbnail);

    // Tamanho ideal (em px) para decodificar a imagem do background
    final mq = MediaQuery.of(context);
    const logicalH = 280.0; // mesma altura do SliverAppBar
    final targetW = (mq.size.width * mq.devicePixelRatio).round();
    final targetH = (logicalH * mq.devicePixelRatio).round();

    // provider: checa por id (String)
    final isFav = context.watch<LibraryProvider>().isFavorite(book.id);

    return Scaffold(
      // Barra de ação fixa no rodapé (favoritar + compartilhar)
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                label: Text(isFav ? 'Nos favoritos' : 'Adicionar aos favoritos'),
                onPressed: () async {
                  await context.read<LibraryProvider>().toggleFavorite(book); // envia o Book
                  final nowFav = context.read<LibraryProvider>().isFavorite(book.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(nowFav
                          ? 'Adicionado aos favoritos'
                          : 'Removido dos favoritos'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                padding: WidgetStateProperty.all(const EdgeInsets.all(14)),
              ),
              tooltip: 'Compartilhar',
              icon: const Icon(Icons.ios_share),
              onPressed: () {
                final title = (book.title == null || book.title!.isEmpty) ? 'Livro' : book.title!;
                final authorsList = book.authors ?? const <String>[];
                final authors = authorsList.isNotEmpty ? ' de ${authorsList.join(', ')}' : '';
                final msg = 'Recomendo: "$title"$authors';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(behavior: SnackBarBehavior.floating, content: Text('Compartilhar: $msg')),
                );
                // Para compartilhar de verdade: use o pacote share_plus aqui.
              },
            ),
          ],
        ),
      ),

      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: logicalH,
            backgroundColor: cs.surface,
            foregroundColor: cs.onSurface,
            title: const Text('Detalhes'),
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl != null)
                    Hero(
                      tag: 'cover_${book.id}', // Hero só no background (evita conflito)
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.black26,         // leve escurecida p/ contraste
                          BlendMode.darken,
                        ),
                        child: Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high, // amostragem melhor
                          cacheWidth: targetW,                // bitmap no tamanho certo
                          cacheHeight: targetH,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  const _EdgeFade(), // degradê forte na base
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      child: _TitleOverlayStrong(
                        child: _TitleAndAuthors(
                          title: t.title,
                          subtitle: t.subtitle,
                          authors: book.authors ?? const <String>[],
                          invertForImage: true, // texto branco + sombra/contorno
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bloco principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linha com mini capa, preço e categorias
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: coverUrl != null
                            ? Image.network(
                                coverUrl,
                                width: 110,
                                height: 160,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                              )
                            : Container(
                                width: 110,
                                height: 160,
                                color: cs.surfaceVariant,
                                alignment: Alignment.center,
                                child: Icon(Icons.menu_book_rounded, color: cs.onSurfaceVariant),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (book.price != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  formatPrice(book.price, book.currency),
                                  style: TextStyle(
                                    color: cs.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ((book.categories ?? const <String>[]).isEmpty
                                      ? ['Sem categoria']
                                      : (book.categories ?? const <String>[]).take(6))
                                  .map((c) => Chip(
                                        label: Text(c),
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const _SectionTitle('Resumo'),
                  const SizedBox(height: 8),
                  _Description(text: _cleanHtml(book.description)),

                  const SizedBox(height: 24),
                  const _SectionTitle('Detalhes'),
                  const SizedBox(height: 8),
                  _MetaList(book: book),

                  const SizedBox(height: 64), // espaço p/ não ficar sob a bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ajusta a URL para pegar uma versão MAIOR (zoom=1) e garantir HTTPS.
  String? _tunedCoverUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    var u = url.replaceFirst('http://', 'https://');

    // Se já houver zoom, substitui; senão, adiciona.
    if (u.contains(RegExp(r'zoom=\d'))) {
      u = u.replaceAll(RegExp(r'zoom=\d'), 'zoom=1'); // 0/1 costumam ser maiores
    } else {
      final sep = u.contains('?') ? '&' : '?';
      u = '$u${sep}zoom=1';
    }
    return u;
  }

  static String? _cleanHtml(String? html) {
    final s = html?.trim();
    if (s == null || s.isEmpty) return null;
    return s.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

// ---------- Overlay com blur e fundo escuro ----------
class _TitleOverlayStrong extends StatelessWidget {
  final Widget child;
  const _TitleOverlayStrong({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ---------- Título e autores ----------
class _TitleAndAuthors extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> authors;
  final bool invertForImage;
  const _TitleAndAuthors({
    required this.title,
    required this.subtitle,
    required this.authors,
    this.invertForImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseColor = invertForImage ? Colors.white : cs.onSurface;
    final subColor = invertForImage ? Colors.white70 : cs.onSurface.withOpacity(0.85);
    final authorColor = invertForImage ? Colors.white70 : cs.onSurface.withOpacity(0.8);
    final textShadows = invertForImage
        ? [Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 6, offset: const Offset(0, 2))]
        : const <Shadow>[];

    // título com contorno + preenchimento (quando sobre imagem)
    Widget outlined(String text, TextStyle fillStyle) {
      if (!invertForImage) {
        return Text(text, style: fillStyle, maxLines: 2, overflow: TextOverflow.ellipsis);
      }
      return Stack(
        children: [
          Text( // contorno escuro
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: fillStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.5
                ..color = Colors.black.withOpacity(0.8),
              color: null,
              shadows: const [],
            ),
          ),
          Text( // preenchimento branco
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: fillStyle,
          ),
        ],
      );
    }

    final titleStyle = TextStyle(
      color: baseColor,
      fontSize: 22,
      fontWeight: FontWeight.w800,
      height: 1.1,
      letterSpacing: -0.2,
      shadows: textShadows,
    );

    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final authorsText = authors.isNotEmpty ? authors.join(', ') : 'Autor desconhecido';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        outlined(title.isEmpty ? 'Sem título' : title, titleStyle),
        if (hasSubtitle)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle!,
              style: TextStyle(
                color: subColor,
                fontWeight: FontWeight.w600,
                shadows: textShadows,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            authorsText,
            style: TextStyle(color: authorColor, shadows: textShadows),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------- Resumo com ver mais/menos ----------
class _Description extends StatefulWidget {
  final String? text;
  const _Description({required this.text});

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text?.trim();
    final cs = Theme.of(context).colorScheme;

    if (text == null || text.isEmpty) {
      return Text('Sem resumo disponível', style: TextStyle(color: cs.onSurfaceVariant));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          firstChild: Text(
            text,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.35),
          ),
          secondChild: Text(text, style: const TextStyle(height: 1.35)),
          crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => expanded = !expanded),
          icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          label: Text(expanded ? 'ver menos' : 'ver mais'),
        )
      ],
    );
  }
}

// ---------- Lista de metadados ----------
class _MetaItem {
  final IconData icon;
  final String text;
  _MetaItem(this.icon, this.text);
}

class _MetaList extends StatelessWidget {
  final Book book;
  const _MetaList({required this.book});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final cats = book.categories ?? const <String>[];
    final items = <_MetaItem>[];
    if (cats.isNotEmpty) {
      items.add(_MetaItem(Icons.category_rounded, cats.join(' / ')));
    }
    if (book.price != null) {
      items.add(_MetaItem(Icons.sell_rounded, formatPrice(book.price, book.currency)));
    }

    if (items.isEmpty) {
      return Text('Sem detalhes adicionais', style: TextStyle(color: cs.onSurfaceVariant));
    }

    return Card(
      elevation: 0,
      color: cs.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              ListTile(
                dense: true,
                leading: Icon(items[i].icon),
                title: Text(items[i].text),
                horizontalTitleGap: 8,
              ),
              if (i != items.length - 1) const Divider(height: 0),
            ]
          ],
        ),
      ),
    );
  }
}

// ---------- Recomendações ----------
class _AuthorRecommendations extends StatelessWidget {
  final String author;
  final String currentId; // evita repetir o livro atual
  const _AuthorRecommendations({required this.author, required this.currentId});

  @override
  Widget build(BuildContext context) {
    if (author.isEmpty) return const SizedBox.shrink();

    return Column(
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Não foi possível carregar recomendações.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                  ),
                );
              }
              final list = (snap.data ?? [])
                  .where((b) => b.id != currentId)
                  .toList();
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Nada encontrado para $author.',
                      style: Theme.of(context).textTheme.bodySmall),
                );
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        MaterialPageRoute(builder: (_) => BookDetailsScreen(book: b)),
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
                                ? Image.network(
                                    url,
                                    width: 120,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                  )
                                : Container(
                                    width: 120,
                                    height: 160,
                                    color: Colors.black12,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.menu_book, color: Colors.black38),
                                  ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (b.title == null || b.title!.trim().isEmpty) ? 'Sem título' : b.title!,
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
    );
  }
}

class _RecSkeleton extends StatelessWidget {
  const _RecSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ---------- Degradê forte na base ----------
class _EdgeFade extends StatelessWidget {
  const _EdgeFade();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.55, 1.0],
          colors: [
            Colors.transparent,
            Colors.black38,
            Colors.black87,
          ],
        ),
      ),
    );
  }
}
