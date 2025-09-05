import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:livros_app/models/book.dart';

class BookApi {
  static const _base = 'https://www.googleapis.com/books/v1/volumes';

  static Future<List<Book>> search (String query, {int maxResults = 20}) async {
    final uri = Uri.parse('Uri.encodeQueryComponent(query)}&maxResults=$maxResults');

    final res = await http.get(uri);  //Faz o GET
    if (res.statusCode != 200) {
      throw Exception('Erro ao buscar: &{res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>; // decodifica JSON
    final items = (data['items'] as List?) ?? [];              // pode não ter 'items'
    return items.map((e) => Book.fromGoogleItem (e as Map<String, dynamic>)).toList();
  }
}