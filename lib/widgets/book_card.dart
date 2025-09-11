import 'package:flutter/material.dart';
import 'package:livros_app/models/book.dart';
import 'package:livros_app/utils/title_utils.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavorite;

  // 👇 NOVO: controla se mostra o preço
  final bool showPrice;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.isFavorite = false,
    this.onFavorite,
    this.showPrice = true, // padrão: mostra preço (outras telas)
  });

  @override
  Widget build(BuildContext context) {
    final t = prettyTitle(book.title);
    final title = t.title;
    final subtitle = t.subtitle;

    final authors =
        (book.authors.isNotEmpty) ? book.authors.join(', ') : 'Autor desconhecido';

    final coverUrl = _tunedCoverUrl(book.thumbnail);
    final priceText = _formatPrice(book.price, book.currency);

    final scheme = Theme.of(context).colorScheme;

    final card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.surface, scheme.surface.withOpacity(0.94)],
          ),
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // conteúdo
            Padding(
              // espaço extra para a seta
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // capa com badge de preço
                  Flexible(
                    fit: FlexFit.tight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: coverUrl != null
                                ? Image.network(
                                    coverUrl,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.medium,
                                    loadingBuilder: (c, child, p) =>
                                        p == null ? child : Container(color: Colors.black12),
                                    errorBuilder: (c, _, __) => Container(
                                      color: Colors.black12,
                                      child: const Icon(Icons.broken_image, color: Colors.black38),
                                    ),
                                  )
                                : Container(
                                    color: Colors.black12,
                                    child: const Icon(Icons.menu_book, color: Colors.black38),
                                  ),
                          ),

                          // 👇 Só mostra o badge se showPrice for true e existir preço
                          if (showPrice && priceText != '—')
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
                  ),

                  const SizedBox(height: 10),

                  // título
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: 0.2,
                        ),
                  ),

                  // subtítulo (opcional)
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withOpacity(0.6),
                            height: 1.1,
                          ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // autor (pill)
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      authors,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSecondaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // favorito opcional
                  if (onFavorite != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filledTonal(
                        onPressed: onFavorite,
                        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                        tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // setinha sutil
            if (onTap != null)
              Positioned(
                right: 8,
                bottom: 6,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: scheme.onSurface.withOpacity(0.35),
                ),
              ),
          ],
        ),
      ),
    );

    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: card,
    );
  }

  String? _tunedCoverUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    var u = url.replaceFirst('http://', 'https://');
    u = u.replaceAll(RegExp(r'zoom=\d'), 'zoom=2');
    return u;
  }

  String _formatPrice(double? amount, String? currency) {
    if (amount == null) return '—';
    final v = amount.toStringAsFixed(2);
    if (currency == null || currency.isEmpty) return v;
    return '$currency $v';
  }
}
