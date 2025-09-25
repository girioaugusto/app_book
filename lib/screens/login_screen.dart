import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../root_shell.dart';
import '../providers/tabs_controller.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthService>();
      await auth.login(_userCtrl.text.trim(), _passCtrl.text);

      // Vai para Home (aba 1 = HomeScreen) dentro do RootShell
      context.read<TabsController>().setIndex(0);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RootShell()),
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

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esqueci minha senha'),
        content: const Text(
          'Para redefinição de senha de forma segura é necessário um backend '
          '(e-mail/SMS/verificação). Neste app local, use "Alterar senha" após '
          'fazer login ou implemente verificação externa.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ok')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 24),
                  Icon(Icons.lock_outline, size: 72, color: cs.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Entrar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Usuário
                  TextFormField(
                    controller: _userCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Usuário',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o usuário'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Senha
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    onFieldSubmitted: (_) => _doLogin(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Informe a senha'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Botão entrar
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _doLogin,
                      icon: const Icon(Icons.login),
                      label: Text(_busy ? 'Entrando…' : 'Entrar'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Ações secundárias
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _busy
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                );
                              },
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Criar conta'),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _showForgotPasswordDialog,
                        child: const Text('Esqueci minha senha'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
