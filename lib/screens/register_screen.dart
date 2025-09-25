import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _busy = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  // Regras: mínimo 8, 1 maiúscula, 1 caractere especial
  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Informe a senha';
    final hasUpper = v.contains(RegExp(r'[A-Z]'));
    final hasSpecial = v.contains(RegExp(r'[^A-Za-z0-9]')); // qualquer símbolo
    if (v.length < 8 || !hasUpper || !hasSpecial) {
      return 'Mínimo 8 caracteres, 1 maiúscula e 1 especial';
    }
    return null;
  }

  Future<void> _doRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthService>();
      await auth.register(_userCtrl.text.trim(), _passCtrl.text);

      if (!mounted) return;
      // Volta para a tela de login com confirmação
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada! Faça login.')),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar conta'),
        centerTitle: true,
      ),
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
                  const SizedBox(height: 8),
                  Icon(Icons.person_add_alt_1, size: 64, color: cs.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Nova conta',
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
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o usuário' : null,
                  ),
                  const SizedBox(height: 12),

                  // Senha
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure1,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscure1 ? 'Mostrar senha' : 'Ocultar senha',
                        icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 12),

                  // Confirmar senha
                  TextFormField(
                    controller: _pass2Ctrl,
                    obscureText: _obscure2,
                    onFieldSubmitted: (_) => _doRegister(),
                    decoration: InputDecoration(
                      labelText: 'Confirmar senha',
                      prefixIcon: const Icon(Icons.lock_person_outlined),
                      suffixIcon: IconButton(
                        tooltip: _obscure2 ? 'Mostrar senha' : 'Ocultar senha',
                        icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                      ),
                    ),
                    validator: (v) {
                      final base = _validatePassword(v);
                      if (base != null) return base;
                      if (v != _passCtrl.text) return 'As senhas não coincidem';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Botão criar conta
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _doRegister,
                      icon: const Icon(Icons.check),
                      label: Text(_busy ? 'Criando…' : 'Criar conta'),
                    ),
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
