import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:livros_app/models/book.dart';
import 'package:livros_app/services/book_api.dart';

class LibraryProvider extends ChangeNotifier {
  // Resultados de busca + favoritos
  final List<Book> _results = [];
  final List<Book> _favorites = [];

  // Ler / Lido
  final List<Book> _toRead = [];
  final List<Book> _read = [];

  bool _isLoading = false;
  String _lastQuery = '';
  String? _error;

  // Getters públicos
  List<Book> get results => List.unmodifiable(_results);
  List<Book> get favorites => List.unmodifiable(_favorites);
  List<Book> get toRead => List.unmodifiable(_toRead);
  List<Book> get read => List.unmodifiable(_read);

  bool get isLoading => _isLoading;
  String get lastQuery => _lastQuery;
  String? get error => _error;

  // Chaves de persistência
  static const _prefsFavKey = 'favorite_v1';
  static const _prefsToReadKey = 'toRead_v1';
  static const _prefsReadKey = 'read_v1';

  // ---------------------- Inicialização ----------------------
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Favoritos
    final favStored = prefs.getStringList(_prefsFavKey) ?? [];
    _favorites
      ..clear()
      ..addAll(favStored.map((s) => Book.fromJson(jsonDecode(s))));

    // Ler
    final toReadStored = prefs.getStringList(_prefsToReadKey) ?? [];
    _toRead
      ..clear()
      ..addAll(toReadStored.map((s) => Book.fromJson(jsonDecode(s))));

    // Lido
    final readStored = prefs.getStringList(_prefsReadKey) ?? [];
    _read
      ..clear()
      ..addAll(readStored.map((s) => Book.fromJson(jsonDecode(s))));

    notifyListeners();
  }

  // ---------------------- Persistência ----------------------
  Future<void> _saveFavorites(SharedPreferences prefs) async {
    await prefs.setStringList(
      _prefsFavKey,
      _favorites.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  Future<void> _saveReadingLists(SharedPreferences prefs) async {
    await prefs.setStringList(
      _prefsToReadKey,
      _toRead.map((b) => jsonEncode(b.toJson())).toList(),
    );
    await prefs.setStringList(
      _prefsReadKey,
      _read.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  // ---------------------- Busca ----------------------
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
      _error = 'Não foi possível carregar os livros. Verifique sua conexão e tente novamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
    await _saveFavorites(prefs);
    notifyListeners();
  }

  // ---------------------- Ler / Lido ----------------------
  bool isInToRead(String id) => _toRead.any((b) => b.id == id);
  bool isInRead(String id) => _read.any((b) => b.id == id);

  /// Adiciona à lista "Ler" (se não estiver em nenhuma).
  Future<void> addToRead(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    if (!isInToRead(book.id) && !isInRead(book.id)) {
      _toRead.add(book);
      await _saveReadingLists(prefs);
      notifyListeners();
    }
  }

  /// Move de Ler → Lido.
  Future<void> markAsRead(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    _toRead.removeWhere((b) => b.id == book.id);
    if (!isInRead(book.id)) _read.add(book);
    await _saveReadingLists(prefs);
    notifyListeners();
  }

  /// Move de Lido → Ler.
  Future<void> moveBackToRead(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    _read.removeWhere((b) => b.id == book.id);
    if (!isInToRead(book.id)) _toRead.add(book);
    await _saveReadingLists(prefs);
    notifyListeners();
  }

  /// Remove de Ler e Lido.
  Future<void> removeFromAll(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _toRead.removeWhere((b) => b.id == id);
    _read.removeWhere((b) => b.id == id);
    await _saveReadingLists(prefs);
    notifyListeners();
  }

  // ---------------------- Recomendação por autor ----------------------
  Future<List<Book>> fetchByAuthor(String author, {int max = 12}) async {
    final a = author.trim();
    if (a.isEmpty || a == 'Autor desconhecido') return [];

    try {
      final list = await BookApi.search('inauthor:"$a"');
      final filtered = list.where((b) => (b.title ?? '').trim().isNotEmpty).toList();
      return (max > 0) ? filtered.take(max).toList() : filtered;
    } catch (e) {
      if (kDebugMode) print('fetchByAuthor error: $e');
      final lower = a.toLowerCase();
      final candidates = _results.where((b) {
        final authors = b.authors ?? const [];
        return authors.any((x) => x.toLowerCase() == lower);
      }).toList();
      return (max > 0) ? candidates.take(max).toList() : candidates;
    }
  }
}
