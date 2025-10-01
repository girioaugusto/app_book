import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart' as uni;            // 👈 alias
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// 1) Supabase → Auth → URL Configuration → Additional Redirect URLs:
///    br.augusto.bookapp://auth-callback
/// 2) No signUp/reset, use emailRedirectTo: kRedirect
/// 3) AndroidManifest/Info.plist com o scheme abaixo
const kRedirect = 'br.augusto.bookapp://auth-callback';

class AuthService with ChangeNotifier {
  final supa.SupabaseClient _sb;
  final GlobalKey<NavigatorState> navigatorKey;

  StreamSubscription<supa.AuthState>? _authSub;
  StreamSubscription<Uri?>? _linkSub;

  bool _listeningLinks = false;
  bool _handlingLink = false;

  AuthService(this._sb, {required this.navigatorKey}) {
    _listenAuthChanges();
    _listenDeepLinks(); // trata os links de confirmação/reset
  }

  supa.User? get currentUser => _sb.auth.currentUser;

  Stream<supa.AuthChangeEvent> authEvents() =>
      _sb.auth.onAuthStateChange.map((s) => s.event);

  // ---------------- AUTH STATE ----------------
  void _listenAuthChanges() {
    _authSub = _sb.auth.onAuthStateChange.listen((data) {
      final ev = data.event;
      debugPrint('[AuthService] onAuthStateChange: $ev');

      if (ev == supa.AuthChangeEvent.signedOut) {
        _goToLogin();
      }
      // Navegação pós-confirmação é feita pelo deep link (_handleIncomingLink)
    });
  }

  // ---------------- DEEP LINKS ----------------
  Future<void> _listenDeepLinks() async {
    if (_listeningLinks) return;
    _listeningLinks = true;

    // Link que abriu o app "frio"
    try {
      final initial = await uni.getInitialUri();
      if (initial != null) {
        debugPrint('[AuthService] initial link: $initial');
        await _handleIncomingLink(initial);
      }
    } catch (e) {
      debugPrint('[AuthService] getInitialUri error: $e');
    }

    // Links enquanto o app está aberto
    _linkSub = uni.uriLinkStream.listen((uri) async {
      if (uri != null) {
        debugPrint('[AuthService] stream link: $uri');
        await _handleIncomingLink(uri);
      }
    }, onError: (err) {
      debugPrint('[AuthService] uriLinkStream error: $err');
    });
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    if (_handlingLink) return;
    _handlingLink = true;

    try {
      debugPrint('[AuthService] handling link: $uri');

      // Interpreta URL (signup/reset/magic) e salva sessão
      await _sb.auth.getSessionFromUrl(uri, storeSession: true);

      // Após salvar a sessão, pegue o user atualizado
      final u = _sb.auth.currentUser;
      debugPrint('[AuthService] currentUser after link: ${u?.email}');

      if (u != null) {
        // Cria/atualiza o perfil (garanta RLS: auth.uid() = id para insert/update)
        try {
          await _sb.from('profiles').upsert(
            {
              'id': u.id,
              'email': u.email,
              // 'full_name': u.userMetadata?['full_name'],
            },
            onConflict: 'id',
          );
        } catch (e) {
          debugPrint('[AuthService] upsert profiles error: $e'); // não bloqueia o fluxo
        }

        // Fluxo desejado: faz signOut e volta ao login com mensagem
        await _sb.auth.signOut();
        _goToLogin(message: 'Conta verificada! Faça login para continuar.');
        return;
      }

      // Se não houver usuário aqui, o link provavelmente não trouxe tokens (redirect/config)
      _showSnackBar(
        'Não foi possível validar o link. Verifique o Additional Redirect URL e tente abrir no navegador externo.',
      );
      _goToLogin();
    } catch (e) {
      debugPrint('[AuthService] handleIncomingLink error: $e');
      _showSnackBar('Falha ao confirmar: $e');
      _goToLogin();
    } finally {
      _handlingLink = false;
    }
  }

  // ---------------- AÇÕES PÚBLICAS ----------------
  Future<supa.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _sb.auth.signInWithPassword(email: email, password: password);
  }

  Future<supa.AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    String? fullName,
  }) {
    return _sb.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: kRedirect,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _sb.auth.resetPasswordForEmail(email, redirectTo: kRedirect);
  }

  Future<void> updatePassword(String newPassword) async {
    await _sb.auth.updateUser(supa.UserAttributes(password: newPassword));
    await _sb.auth.signOut();
  }

  Future<void> signInWithGoogle() async {
    await _sb.auth.signInWithOAuth(
      supa.OAuthProvider.google,
      redirectTo: kRedirect,
      queryParams: const {'prompt': 'select_account'},
    );
  }

  Future<void> logout() => _sb.auth.signOut();

  // ---------------- HELPERS ----------------
  void _goToLogin({String? message}) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    nav.pushNamedAndRemoveUntil('/login', (_) => false);

    if (message != null) {
      final ctx = nav.context;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(message)),
        );
      });
    }
  }

  void _showSnackBar(String msg) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    final ctx = nav.context;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }
}
