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

  // Cache de recomendações por autor (chave: autor normalizado)
  final Map<String, List<Book>> _authorCache = {};

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

    // A busca muda o universo local; limpe a cache de autor
    _authorCache.clear();

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

    // Favoritar pode influenciar recomendações locais; limpe a cache
    _authorCache.clear();

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

      // Pode afetar recomendações locais
      _authorCache.clear();

      notifyListeners();
    }
  }

  /// Move de Ler → Lido.
  Future<void> markAsRead(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    _toRead.removeWhere((b) => b.id == book.id);
    if (!isInRead(book.id)) _read.add(book);
    await _saveReadingLists(prefs);

    _authorCache.clear();
    notifyListeners();
  }

  /// Move de Lido → Ler.
  Future<void> moveBackToRead(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    _read.removeWhere((b) => b.id == book.id);
    if (!isInToRead(book.id)) _toRead.add(book);
    await _saveReadingLists(prefs);

    _authorCache.clear();
    notifyListeners();
  }

  /// Remove de Ler e Lido.
  Future<void> removeFromAll(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _toRead.removeWhere((b) => b.id == id);
    _read.removeWhere((b) => b.id == id);
    await _saveReadingLists(prefs);

    _authorCache.clear();
    notifyListeners();
  }

  // ---------------------- Recomendação por autor ----------------------

  /// Retorna recomendações do mesmo autor, combinando:
  /// 1) Itens já conhecidos localmente (results/favorites/toRead/read)
  /// 2) Busca remota na API (BookApi.search) com `inauthor:"$author"`
  ///
  /// - Compara autores com normalização (trim/lowercase).
  /// - Remove o livro atual na UI (lá no widget) usando `currentId`.
  /// - Usa cache para evitar repetir chamadas enquanto a store não muda.
  Future<List<Book>> fetchByAuthor(String author, {int limit = 10}) async {
    final key = author.trim().toLowerCase();
    if (key.isEmpty) return const <Book>[];

    // Cache
    final cached = _authorCache[key];
    if (cached != null) {
      return limit > 0 && cached.length > limit ? cached.take(limit).toList() : cached;
    }

    // 1) Busca local (já carregados)
    final localPool = <Book>{
      ..._results,
      ..._favorites,
      ..._toRead,
      ..._read,
    };

    bool bookHasAuthor(Book b) {
      final a = (b.authors ?? const <String>[]);
      return a.any((x) => x.trim().toLowerCase() == key);
    }

    final localMatches = localPool.where(bookHasAuthor).toList();

    // 2) Busca remota por autor (se disponível)
    final merged = <Book>[...localMatches];
    try {
      final remote = await BookApi.search('inauthor:"$author"');
      for (final b in remote) {
        if (!merged.any((x) => x.id == b.id)) {
          merged.add(b);
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('fetchByAuthor error: $e');
        print(st);
      }
      // Mesmo que a remota falhe, devolvemos o que achamos localmente
    }

    // Opcional: ordena priorizando itens locais primeiro (podem ser mais relevantes)
    // Depois por título como fallback estável
    merged.sort((a, b) {
      final aLocal = localPool.any((x) => x.id == a.id) ? 0 : 1;
      final bLocal = localPool.any((x) => x.id == b.id) ? 0 : 1;
      final cmpLocal = aLocal.compareTo(bLocal);
      if (cmpLocal != 0) return cmpLocal;
      final ta = (a.title ?? '').toLowerCase();
      final tb = (b.title ?? '').toLowerCase();
      return ta.compareTo(tb);
    });

    final result = (limit > 0 && merged.length > limit) ? merged.take(limit).toList() : merged;

    // Preenche cache e retorna
    _authorCache[key] = result;
    return result;
  }
}
