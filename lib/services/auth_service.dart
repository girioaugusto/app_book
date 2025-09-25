import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/user_dao.dart';

/// Serviço de autenticação local:
/// - Senhas com PBKDF2-HMAC-SHA256 + salt
/// - Sessão no FlutterSecureStorage (Keychain/Keystore)
class AuthService extends ChangeNotifier {
  final _dao = UserDao();
  final _storage = const FlutterSecureStorage();

  // PBKDF2 com HMAC-SHA256, 150k iterações, 256 bits
  final _algo = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 150000,
    bits: 256,
  );

  UserRecord? _current;
  UserRecord? get currentUser => _current;

  /// Carrega sessão persistida (se houver).
  Future<void> loadSession() async {
    final userIdStr = await _storage.read(key: 'session_user_id');
    final username = await _storage.read(key: 'session_username');
    if (userIdStr == null || username == null) return;

    _current = UserRecord(
      id: int.parse(userIdStr),
      username: username,
      passwordHash: '',
      salt: '',
      createdAt: 0,
    );
    notifyListeners();
  }

  Future<void> _saveSession(UserRecord u) async {
    await _storage.write(key: 'session_user_id', value: u.id.toString());
    await _storage.write(key: 'session_username', value: u.username);
  }

  Future<void> logout() async {
    _current = null;
    await _storage.delete(key: 'session_user_id');
    await _storage.delete(key: 'session_username');
    notifyListeners();
  }

  // ----------------- Helpers de segurança -----------------

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  Future<String> _hashPassword(String password, List<int> salt) async {
    final secretKey = SecretKey(utf8.encode(password));
    final derived = await _algo.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
    final bytes = await derived.extractBytes();
    return base64Encode(bytes);
  }

  String _encodeSalt(List<int> salt) => base64Encode(salt);
  List<int> _decodeSalt(String s) => base64Decode(s);

  // ---------------------- API pública ----------------------

  /// Cria usuário (username único) e faz login.
  Future<UserRecord> register(String username, String password) async {
    final existing = await _dao.findByUsername(username);
    if (existing != null) {
      throw Exception('Nome de usuário já existe');
    }

    final salt = _randomBytes(16);
    final hash = await _hashPassword(password, salt);

    final user = await _dao.insertUser(
      username: username,
      passwordHash: hash,
      salt: _encodeSalt(salt),
    );

    _current = user;
    await _saveSession(user);
    notifyListeners();
    return user;
  }

  /// Faz login validando senha com PBKDF2.
  Future<UserRecord> login(String username, String password) async {
    final user = await _dao.findByUsername(username);
    if (user == null) {
      throw Exception('Usuário não encontrado');
    }

    final salt = _decodeSalt(user.salt);
    final hash = await _hashPassword(password, salt);
    if (hash != user.passwordHash) {
      throw Exception('Senha inválida');
    }

    _current = user;
    await _saveSession(user);
    notifyListeners();
    return user;
  }

  /// Troca a senha verificando a senha atual.
  Future<void> changePassword({
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = await _dao.findByUsername(username);
    if (user == null) {
      throw Exception('Usuário não encontrado');
    }

    final salt = _decodeSalt(user.salt);
    final currentHash = await _hashPassword(currentPassword, salt);
    if (currentHash != user.passwordHash) {
      throw Exception('Senha atual incorreta');
    }

    final newSalt = _randomBytes(16);
    final newHash = await _hashPassword(newPassword, newSalt);

    await _dao.updatePassword(
      userId: user.id,
      newPasswordHash: newHash,
      newSalt: _encodeSalt(newSalt),
    );
  }
}
