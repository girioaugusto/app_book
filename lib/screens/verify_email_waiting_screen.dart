import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:livros_app/services/auth_service.dart';
import 'login_screen.dart';

class VerifyEmailWaitingScreen extends StatefulWidget {
  const VerifyEmailWaitingScreen({super.key});

  @override
  State<VerifyEmailWaitingScreen> createState() =>
      _VerifyEmailWaitingScreenState();
}

class _VerifyEmailWaitingScreenState extends State<VerifyEmailWaitingScreen>
    with TickerProviderStateMixin {
  StreamSubscription? _sub;
  bool _mounted = true;
  bool _checking = false;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    lowerBound: 0.95,
    upperBound: 1.05,
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();

    // 🔔 Escuta eventos do Supabase
    _sub = auth.authEvents().listen((ev) {
      if (!_mounted) return;
      if (ev == AuthChangeEvent.userUpdated ||
          ev == AuthChangeEvent.signedIn) {
        _goToLogin(success: true);
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _sub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// 👉 Força refresh do usuário para verificar se já está confirmado
  Future<void> _iAlreadyVerified() async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      final res = await Supabase.instance.client.auth.getUser();
      final user = res.user;
      if (user != null && user.emailConfirmedAt != null) {
        _goToLogin(success: true);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ainda não encontramos a confirmação. Tente novamente.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao verificar status: $e')),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// Navega para tela de login com mensagem
  void _goToLogin({required bool success}) {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta confirmada! Agora você pode fazer login.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final email =
        context.watch<AuthService>().currentUser?.email ?? 'seu e-mail';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifique seu e-mail'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _pulseCtrl,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary.withOpacity(0.10),
                      border: Border.all(color: cs.primary.withOpacity(0.25)),
                    ),
                    child: Icon(
                      Icons.mark_email_unread_rounded,
                      size: 40,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Confira sua caixa de entrada',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enviamos um link de verificação para:',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  email,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Text(
                  'Clique no link do e-mail para confirmar.\n'
                  'Depois toque em “Já verifiquei” para continuar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // ✅ Já verifiquei
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _checking ? null : _iAlreadyVerified,
                    child: _checking
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Já verifiquei'),
                  ),
                ),
                const SizedBox(height: 12),

                // 🚪 Sair
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.tonal(
                    onPressed: () async {
                      await context.read<AuthService>().logout();
                      _goToLogin(success: false);
                    },
                    child: const Text('Sair e voltar ao login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
