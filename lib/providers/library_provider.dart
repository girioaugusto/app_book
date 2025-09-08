import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:livros_app/models/book.dart';
import 'package:livros_app/services/book_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryProvider extends ChangeNotifier {
  final List<Book> _results = [];     // lista após a busca
  final List<Book> _favorites = [];   // lista de favoritos

  bool _isLoading = false;            // estado de carregamento
  String _lastQuery = '';             // última busca (opcional, para retry)
  String? _error;                     // mensagem de erro atual (se houver)

  List<Book> get results => List.unmodifiable(_results);
  List<Book> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;
  String get lastQuery => _lastQuery;
  String? get error => _error;

  static const _prefsKey = 'favorite_v1';

  // ---------------------- Inicialização ----------------------
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? [];
    _favorites
      ..clear()
      ..addAll(
        stored.map(
          (s) => Book.fromJson(jsonDecode(s) as Map<String, dynamic>),
        ),
      );
    notifyListeners();
  }

  // ---------------------- Busca livros ----------------------
  Future<void> searchBooks(String query) async {
    if (query.isEmpty) return;
    _isLoading = true;
    _lastQuery = query;
    _error = null;
    notifyListeners();

    try {
      final list = await BookApi.search(query);
      _results
        ..clear()
        ..addAll(list);
    } catch (e, st) {
      if (kDebugMode) {
        print('searchBooks error: $e');
        print(st);
      }
      _results.clear();
      _error =
          'Não foi possível carregar os livros. Verifique sua conexão e tente novamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------- Retry ----------------------
  Future<void> retry() async {
    if (_lastQuery.isEmpty) return;
    await searchBooks(_lastQuery);
  }

  // ---------------------- Favoritos ----------------------
  bool isFavorite(String id) => _favorites.any((b) => b.id == id);

  Future<void> toggleFavorite(Book book) async {
    final prefs = await SharedPreferences.getInstance();

    if (isFavorite(book.id)) {
      _favorites.removeWhere((b) => b.id == book.id);
    } else {
      _favorites.add(book);
    }

    await prefs.setStringList(
      _prefsKey,
      _favorites.map((b) => jsonEncode(b.toJson())).toList(),
    );
    notifyListeners();
  }

  // ---------------------- Recomendação por autor ----------------------
  Future<List<Book>> fetchByAuthor(String author, {int max = 12}) async {
    final a = author.trim();
    if (a.isEmpty || a == 'Autor desconhecido') return [];

    try {
      // Busca na API com filtro por autor
      final list = await BookApi.search('inauthor:"$a"');
      return list.where((b) => (b.title ?? '').trim().isNotEmpty).toList();
    } catch (e) {
      if (kDebugMode) {
        print('fetchByAuthor error: $e');
      }
      // fallback local: filtra dos resultados já carregados
      final lower = a.toLowerCase();
      return _results.where((b) {
        final authors = b.authors ?? const [];
        return authors.any((x) => x.toLowerCase() == lower);
      }).toList();
    }
  }
}
