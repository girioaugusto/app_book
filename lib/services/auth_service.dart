import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/user_dao.dart';

/// Serviço de autenticação local:
/// - Senhas com PBKDF2-HMAC-SHA256 + salt
/// - Sessão no FlutterSecureStorage (Keychain/Keystore)
/// - Verificação de e-mail por código (local; trocar por backend real depois)
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

  // --- Estado de verificação de e-mail (local) ---
  String? _pendingEmail;
  String? _pendingCode;

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

  Future<List<int>> _hashPasswordBytes(String password, List<int> salt) async {
    final secretKey = SecretKey(utf8.encode(password));
    final derived = await _algo.deriveKey(secretKey: secretKey, nonce: salt);
    return await derived.extractBytes();
  }

  Future<String> _hashPassword(String password, List<int> salt) async {
    final bytes = await _hashPasswordBytes(password, salt);
    return base64Encode(bytes);
  }

  String _encodeSalt(List<int> salt) => base64Encode(salt);
  List<int> _decodeSalt(String s) => base64Decode(s);

  bool _constTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  Future<void> _uniformDelayOnFailure() async {
    // jitter 300–550ms para uniformizar tempo de resposta em falhas
    final jitter = 300 + Random.secure().nextInt(250);
    await Future.delayed(Duration(milliseconds: jitter));
  }

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
  /// Retorna erro genérico em falha (evita "user enumeration").
  Future<UserRecord> login(String username, String password) async {
    final user = await _dao.findByUsername(username);
    if (user == null) {
      await _uniformDelayOnFailure();
      throw Exception('Usuário ou senha inválidos');
    }

    final salt = _decodeSalt(user.salt);
    final derivedBytes = await _hashPasswordBytes(password, salt);

    List<int> storedBytes;
    try {
      storedBytes = base64Decode(user.passwordHash);
    } catch (_) {
      await _uniformDelayOnFailure();
      throw Exception('Usuário ou senha inválidos');
    }

    if (!_constTimeEquals(derivedBytes, storedBytes)) {
      await _uniformDelayOnFailure();
      throw Exception('Usuário ou senha inválidos');
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
      await _uniformDelayOnFailure();
      throw Exception('Usuário ou senha inválidos');
    }

    final salt = _decodeSalt(user.salt);
    final currentBytes = await _hashPasswordBytes(currentPassword, salt);
    final storedBytes = base64Decode(user.passwordHash);

    if (!_constTimeEquals(currentBytes, storedBytes)) {
      await _uniformDelayOnFailure();
      throw Exception('Senha atual inválida');
    }

    final newSalt = _randomBytes(16);
    final newHash = await _hashPassword(newPassword, newSalt);

    await _dao.updatePassword(
      userId: user.id,
      newPasswordHash: newHash,
      newSalt: _encodeSalt(newSalt),
    );
  }

  // ----------------- Verificação de e-mail (local) -----------------

  /// Gera e "envia" um código de 6 dígitos para o e-mail.
  /// Troque esta implementação para chamar seu backend real.
  Future<void> sendVerificationCode(String email) async {
    final rnd = Random.secure();
    final code = List.generate(6, (_) => rnd.nextInt(10)).join();

    _pendingEmail = email;
    _pendingCode = code;

    // Envio real de e-mail deve acontecer no seu backend.
    // Aqui, apenas log para facilitar teste local:
    // ignore: avoid_print
    print('[AuthService] Código de verificação para $email: $code');

    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// Verifica o código digitado pelo usuário.
  /// Retorna true/false; em caso de sucesso, limpa o estado pendente.
  Future<bool> verifyCode(String email, String code) async {
    final ok = (_pendingEmail == email) && (_pendingCode == code);
    await Future.delayed(const Duration(milliseconds: 200));
    if (ok) {
      _pendingEmail = null;
      _pendingCode = null;
    }
    return ok;
  }
}
