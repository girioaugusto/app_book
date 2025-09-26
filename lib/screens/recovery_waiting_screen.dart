import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livros_app/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'new_password_screen.dart';

class RecoveryWaitingScreen extends StatefulWidget {
  final String email;
  const RecoveryWaitingScreen({super.key, required this.email});

  @override
  State<RecoveryWaitingScreen> createState() => _RecoveryWaitingScreenState();
}

class _RecoveryWaitingScreenState extends State<RecoveryWaitingScreen> {
  StreamSubscription<AuthChangeEvent>? _sub;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // ouvir deep link -> evento passwordRecovery (ou signedIn como fallback)
    _sub = context.read<AuthService>().authEvents().listen((event) {
      if (!mounted || _navigated) return;
      if (event == AuthChangeEvent.passwordRecovery || event == AuthChangeEvent.signedIn) {
        _navigated = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NewPasswordScreen()),
        );
      }
    });
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
      appBar: AppBar(title: const Text('Redefinir senha')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_reset, size: 72, color: cs.primary),
                const SizedBox(height: 16),
                Text('Confirme pelo e-mail',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Enviamos um link para: ${_mask(widget.email)}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Expanded(child: Text('Aguarde: ao clicar no link, abriremos a tela de nova senha.')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Atualizar caixa de entrada'),
                      onPressed: () {},
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.mail_outline),
                      label: const Text('Abrir app de e-mail'),
                      onPressed: () {},
                    ),
                  ],
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
