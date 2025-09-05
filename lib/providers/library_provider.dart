import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:livros_app/models/book.dart';
import 'package:livros_app/services/book_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryProvider extends ChangeNotifier {
  final List<Book> _results = [];     // lista após a busca
  final List<Book> _favorites = [];   // seus favoritos
  bool _isLoading = false;            // estado de carregamento
  String _lastQuery = '';             // última busca (opcional, para UX)

  List<Book> get results => List.unmodifiable(_results);
  List<Book> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;
  String get lastQuery => _lastQuery;

  // Convenção camelCase
  static const _prefsKey = 'favorite_v1';

  // Carrega favoritos salvos no dispositivo
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? [];
    _favorites
      ..clear()
      ..addAll(
        stored.map((s) => Book.fromJson(jsonDecode(s) as Map<String, dynamic>)),
      );
    notifyListeners();
  }

  // Faz uma busca na API e atualiza a lista de resultados
  Future<void> searchBooks(String query) async {
    if (query.isEmpty) return;
    _isLoading = true;
    _lastQuery = query;
    notifyListeners();
    try {
      final list = await BookApi.search(query);
      _results
        ..clear()
        ..addAll(list);
    } catch (e) {
      if (kDebugMode) print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // >>> Faltava este método
  bool isFavorite(String id) => _favorites.any((b) => b.id == id);

  // Helpers de favorito
  Future<void> toggleFavorite(Book book) async {
    // >>> Faltava obter o SharedPreferences aqui
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
}
