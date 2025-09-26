import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final _sb = Supabase.instance.client;

  User? _user;
  StreamSubscription<AuthState>? _sub;

  User? get user => _user;
  bool get isLogged => _user != null;

  void init() {
    _user = _sb.auth.currentUser;
    _sub = _sb.auth.onAuthStateChange.listen((state) {
      _user = state.session?.user;
      notifyListeners();
    });
  }

  Future<void> loadSession() async {
    _user = _sb.auth.currentUser;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      await _sb.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
        emailRedirectTo: 'livrosapp://auth-callback',
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Falha ao criar conta.');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _sb.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Não foi possível entrar.');
    }
  }

  Future<void> logout() async {
    try {
      await _sb.auth.signOut();
    } catch (_) {}
  }

  /// 1) Verifica SENHA ANTIGA (reauth) e 2) envia e-mail de reset (deep link)
  Future<void> requestPasswordResetVerified({
    required String email,
    required String oldPassword,
  }) async {
    try {
      await _sb.auth.signInWithPassword(email: email, password: oldPassword);
      await _sb.auth.resetPasswordForEmail(
        email,
        redirectTo: 'livrosapp://auth-callback',
      );
      await _sb.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Falha ao solicitar redefinição.');
    }
  }

  /// 3) Depois do deep link (passwordRecovery), troca a senha aqui
  Future<void> updatePassword(String newPassword) async {
    try {
      await _sb.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Não foi possível atualizar a senha.');
    }
  }

  /// Eventos de auth (inclui passwordRecovery quando abre via deep link)
  Stream<AuthChangeEvent> authEvents() =>
      _sb.auth.onAuthStateChange.map((e) => e.event);

  // --- compat opcional ---
  Future<void> register(String username, String password) async {
    if (username.contains('@')) {
      await signUp(email: username, password: password, username: username);
    } else {
      throw Exception('Use signUp(email, password, username).');
    }
  }

  Future<void> login(String username, String password) async {
    if (username.contains('@')) {
      await signIn(email: username, password: password);
    } else {
      throw Exception('Use signIn(email, password).');
    }
  }

  Future<void> changePassword({
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    throw Exception('Use o fluxo via e-mail (reset) e depois updatePassword(newPassword).');
  }
}
