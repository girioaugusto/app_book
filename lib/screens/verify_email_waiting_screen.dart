import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livros_app/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class VerifyEmailWaitingScreen extends StatefulWidget {
  final String email;

  const VerifyEmailWaitingScreen({super.key, required this.email});

  @override
  State<VerifyEmailWaitingScreen> createState() => _VerifyEmailWaitingScreenState();
}

class _VerifyEmailWaitingScreenState extends State<VerifyEmailWaitingScreen> {
  StreamSubscription<AuthChangeEvent>? _sub;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Ouve eventos do Supabase: ao clicar no link de signup, normalmente vem signedIn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      _sub = auth.authEvents().listen((event) async {
        if (!mounted || _done) return;

        if (event == AuthChangeEvent.signedIn) {
          setState(() => _done = true);
          // Faz signOut para voltar ao fluxo de login normal
          await auth.logout();

          if (!mounted) return;
          // Feedback bonito
          await _showSnack('Conta verificada com sucesso! Faça login.');
          _goLogin();
        }
      });
    });
  }

  Future<void> _showSnack(String msg) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    await Future.delayed(const Duration(milliseconds: 600));
  }

  void _goLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirme seu e-mail')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_unread_outlined, size: 72, color: cs.primary),
                const SizedBox(height: 16),
                Text('Verifique sua caixa de entrada',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Enviamos um link de confirmação para:\n${_mask(widget.email)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error ?? 'Aguardando você clicar no link do e-mail...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Não chegou? Atualize sua caixa de entrada'),
                      onPressed: () {},
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.mail_outline),
                      label: const Text('Abrir app de e-mail'),
                      onPressed: () {
                        // Dica: opcional — usar url_launcher para abrir mailto:
                        // launchUrl(Uri.parse('mailto:'));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _goLogin,
                  child: const Text('Voltar ao login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _mask(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final u = parts[0];
    final d = parts[1];
    final head = u.length <= 2 ? u : '${u.substring(0, 2)}***';
    return '$head@$d';
  }
}
