import 'package:flutter/material.dart';
import 'package:livros_app/models/book.dart';
import 'package:livros_app/utils/title_utils.dart';  // ⬅️ importa o formatador

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavorite;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.isFavorite = false,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final t = prettyTitle(book.title);          // ⬅️ título tratadinho
    final title = t.title;
    final subtitle = t.subtitle;

    final authors = (book.authors?.isNotEmpty ?? false)
        ? book.authors!.join(', ')
        : 'Autor desconhecido';

    final coverUrl = _tunedCoverUrl(book.thumbnail);
    final priceText = _formatPrice(book.price, book.currency);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Capa flexível (evita overflow)
              Flexible(
                fit: FlexFit.tight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: coverUrl != null
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          loadingBuilder: (c, child, progress) {
                            if (progress == null) return child;
                            return Container(color: Colors.black12);
                          },
                          errorBuilder: (c, _, __) => Container(
                            color: Colors.black12,
                            child: const Icon(Icons.broken_image,
                                color: Colors.black38),
                          ),
                        )
                      : Container(
                          color: Colors.black12,
                          child: const Icon(Icons.menu_book,
                              color: Colors.black38),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              // Título principal
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start, // ou center se preferir
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
              ),

              // Subtítulo (se houver, curtinho e discreto)
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        height: 1.1,
                      ),
                ),
              ],

              const SizedBox(height: 2),

              // Autor (centralizado, como você pediu)
              Text(
                authors,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54),
              ),

              const SizedBox(height: 6),

              // Preço (centralizado)
              Text(
                priceText,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),

              if (onFavorite != null || onTap != null) ...[
                const SizedBox(height: 6),
                SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                        ),
                        tooltip: isFavorite
                            ? 'Remover dos favoritos'
                            : 'Adicionar aos favoritos',
                        onPressed: onFavorite,
                      ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: onTap,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Detalhes'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
