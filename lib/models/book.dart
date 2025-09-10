class Book {
  final String id;               // identificador único do volume
  final String title;            // título do livro
  final List<String> authors;    // lista de autores
  final String? thumbnail;       // URL da imagem (pode não existir)
  final double? price;           // preço (pode não existir)
  final String? currency;        // moeda (ex.: USD, BRL)


  final double progress; // 0.0 = não iniciado, 1.0 = lido

  // Usados na tela de detalhes
  final String? description;     // resumo/descrição
  final List<String> categories; // categorias/gêneros

  Book({
    required this.id,
    required this.title,
    required this.authors,
    this.thumbnail,
    this.price,
    this.currency,
    this.description,
    this.categories = const <String>[],
    this.progress = 0.0
  });

  factory Book.fromGoogleItem(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    final saleInfo = json['saleInfo'] ?? {};
    final imageLinks = volumeInfo['imageLinks'] ?? {};

    double? parsedPrice;
    String? currency;

    if (saleInfo['listPrice'] != null) {
      parsedPrice = (saleInfo['listPrice']['amount'] as num?)?.toDouble();
      currency = saleInfo['listPrice']['currencyCode'];
    } else if (saleInfo['retailPrice'] != null) {
      parsedPrice = (saleInfo['retailPrice']['amount'] as num?)?.toDouble();
      currency = saleInfo['retailPrice']['currencyCode'];
    }

    return Book(
      id: (json['id'] ?? '').toString(),
      title: (volumeInfo['title'] ?? '').toString(),
      authors: (volumeInfo['authors'] as List?)
              ?.map((e) => e.toString())
              .toList() ?? <String>[],
      thumbnail: (imageLinks['thumbnail'] ?? imageLinks['smallThumbnail'])?.toString(),
      price: parsedPrice,
      currency: currency,
      description: volumeInfo['description'] as String?,
      categories: (volumeInfo['categories'] as List?)
              ?.map((e) => e.toString())
              .toList() ?? <String>[],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'authors': authors,
    'thumbnail': thumbnail,
    'price': price,
    'currency': currency,
    'description': description,
    'categories': categories,
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    authors: (json['authors'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
    thumbnail: json['thumbnail'] as String?,
    price: (json['price'] as num?)?.toDouble(),
    currency: json['currency'] as String?,
    description: json['description'] as String?,
    categories: (json['categories'] as List?)
            ?.map((e) => e.toString())
            .toList() ?? <String>[],
  );
}
