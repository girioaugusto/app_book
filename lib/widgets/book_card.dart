import 'package:flutter/material.dart';
import 'package:livros_app/models/book.dart';
import 'package:livros_app/utils/price_formatter.dart';

class BookCard extends StatelessWidget {
  final Book book;
  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    // pega primeiro autor, ou mostra um fallback
    final authorText = (book.authors.isNotEmpty)
        ? book.authors.join(', ')
        : 'Autor desconhecido';

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do livro (ou placeholder)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.thumbnail != null
                  ? Image.network(
                      book.thumbnail!,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 80,
                      height: 120,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.menu_book, size: 40),
                    ),
            ),
            const SizedBox(width: 12),
            // Texto: título, autor(es) e preço
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Autor(es)
                  Text(
                    authorText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  // Preço
                  Text(
                    formatPrice(book.price, book.currency),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
