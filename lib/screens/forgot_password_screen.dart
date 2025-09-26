import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livros_app/services/auth_service.dart';
import 'recovery_waiting_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _oldPassCtrl = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _oldPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    try {
      // 1) Reautentica com a senha antiga e dispara o e-mail de reset (deep link)
      await context.read<AuthService>().requestPasswordResetVerified(
            email: _emailCtrl.text.trim(),
            oldPassword: _oldPassCtrl.text,
          );

      if (!mounted) return;

      // 2) Fica aguardando o clique no link (evento passwordRecovery)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RecoveryWaitingScreen(email: _emailCtrl.text.trim()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (!s.contains('@') || !s.contains('.')) return 'E-mail inválido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir senha')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _oldPassCtrl,
                decoration: const InputDecoration(labelText: 'Senha antiga'),
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (v) => (v ?? '').isEmpty ? 'Informe sua senha atual' : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enviar e-mail de confirmação'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Após clicar no link do e-mail, o app abrirá e você definirá a nova senha.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
