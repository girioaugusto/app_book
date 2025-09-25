import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tabs_controller.dart';
import '../services/auth_service.dart';
import '../root_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controles
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _busy = false;
  bool _obscure = true;

  // Estado verificação
  bool _codeSent = false;
  bool _emailVerified = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ---------------- Ações (email verification) ----------------

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um e-mail válido.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await context.read<AuthService>().sendVerificationCode(email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _emailVerified = false; // se reenviar, precisa verificar de novo
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código enviado. Confira seu e-mail.')),
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

  Future<void> _verifyCode() async {
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um e-mail válido.')),
      );
      return;
    }
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código deve ter 6 dígitos.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final ok = await context.read<AuthService>().verifyCode(email, code);
      if (!mounted) return;
      if (ok) {
        setState(() => _emailVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail verificado com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código inválido.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createAccount() async {
    if (!_emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifique seu e-mail para criar a conta.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameCtrl.text.trim();
    final pass = _passwordCtrl.text;
    final pass2 = _confirmCtrl.text;

    if (pass != pass2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não conferem.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final auth = context.read<AuthService>();
      await auth.register(username, pass);

      context.read<TabsController>().setIndex(0);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootShell()),
        (_) => false,
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

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      // AppBar simples; o conteúdo principal fica centralizado num Card
      appBar: AppBar(
        title: const Text('Criar conta'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // em telas grandes o card cresce um pouco; em phones fica compacto
            maxWidth: isWide ? 820 : 560,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: cs.onSurface.withOpacity(0.08),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Form(
                  key: _formKey,
                  child: isWide
                      ? _WideLayout(
                          emailCtrl: _emailCtrl,
                          codeCtrl: _codeCtrl,
                          usernameCtrl: _usernameCtrl,
                          passwordCtrl: _passwordCtrl,
                          confirmCtrl: _confirmCtrl,
                          busy: _busy,
                          codeSent: _codeSent,
                          emailVerified: _emailVerified,
                          onSendCode: _sendCode,
                          onVerifyCode: _verifyCode,
                          obscure: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                          onCreate: _createAccount,
                        )
                      : _NarrowLayout(
                          emailCtrl: _emailCtrl,
                          codeCtrl: _codeCtrl,
                          usernameCtrl: _usernameCtrl,
                          passwordCtrl: _passwordCtrl,
                          confirmCtrl: _confirmCtrl,
                          busy: _busy,
                          codeSent: _codeSent,
                          emailVerified: _emailVerified,
                          onSendCode: _sendCode,
                          onVerifyCode: _verifyCode,
                          obscure: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                          onCreate: _createAccount,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

/* --------------- LAYOUT EM COLUNA (phones) --------------- */

class _NarrowLayout extends StatelessWidget {
  final TextEditingController emailCtrl, codeCtrl, usernameCtrl, passwordCtrl, confirmCtrl;
  final bool busy, codeSent, emailVerified, obscure;
  final VoidCallback onSendCode, onVerifyCode, onToggleObscure, onCreate;

  const _NarrowLayout({
    required this.emailCtrl,
    required this.codeCtrl,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.busy,
    required this.codeSent,
    required this.emailVerified,
    required this.onSendCode,
    required this.onVerifyCode,
    required this.onToggleObscure,
    required this.onCreate,
    required this.obscure,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Verificação de e-mail'),
        const SizedBox(height: 10),

        TextFormField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail',
            prefixIcon: Icon(Icons.alternate_email),
          ),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return 'Informe o e-mail';
            if (!t.contains('@')) return 'E-mail inválido';
            return null;
          },
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : onSendCode,
                icon: const Icon(Icons.send),
                label: Text(codeSent ? 'Reenviar código' : 'Enviar código'),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              emailVerified ? Icons.verified : Icons.mark_email_read_outlined,
              color: emailVerified ? Colors.green : cs.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Código (6 dígitos)',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: busy ? null : onVerifyCode,
              child: const Text('Verificar'),
            ),
          ],
        ),

        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 6),

        const _SectionTitle('Dados da conta'),
        const SizedBox(height: 10),

        TextFormField(
          controller: usernameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Usuário',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Informe o usuário' : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: passwordCtrl,
          obscureText: obscure,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Senha',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: onToggleObscure,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Informe a senha';
            if (v.length < 6) return 'Use ao menos 6 caracteres';
            return null;
          },
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: confirmCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirmar senha',
            prefixIcon: Icon(Icons.lock_reset_outlined),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Confirme a senha';
            if (v != passwordCtrl.text) return 'As senhas não conferem';
            return null;
          },
        ),

        const SizedBox(height: 20),

        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: busy ? null : onCreate,
            icon: const Icon(Icons.check),
            label: Text(busy ? 'Criando…' : 'Criar conta'),
          ),
        ),
      ],
    );
  }
}

/* --------------- LAYOUT EM DUAS COLUNAS (tablets/desktop) --------------- */

class _WideLayout extends StatelessWidget {
  final TextEditingController emailCtrl, codeCtrl, usernameCtrl, passwordCtrl, confirmCtrl;
  final bool busy, codeSent, emailVerified, obscure;
  final VoidCallback onSendCode, onVerifyCode, onToggleObscure, onCreate;

  const _WideLayout({
    required this.emailCtrl,
    required this.codeCtrl,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.busy,
    required this.codeSent,
    required this.emailVerified,
    required this.onSendCode,
    required this.onVerifyCode,
    required this.onToggleObscure,
    required this.onCreate,
    required this.obscure,
  });

  @override
  Widget build(BuildContext context) {
    final gap = 14.0;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coluna 1 — Verificação de e-mail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionTitle('Verificação de e-mail'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Informe o e-mail';
                      if (!t.contains('@')) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : onSendCode,
                          icon: const Icon(Icons.send),
                          label: Text(codeSent ? 'Reenviar código' : 'Enviar código'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        emailVerified ? Icons.verified : Icons.mark_email_read_outlined,
                        color: emailVerified ? Colors.green : cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codeCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'Código (6 dígitos)',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: busy ? null : onVerifyCode,
                        child: const Text('Verificar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: gap),

            // Coluna 2 — Dados da conta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionTitle('Dados da conta'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: usernameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Usuário',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o usuário' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
                        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: onToggleObscure,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe a senha';
                      if (v.length < 6) return 'Use ao menos 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar senha',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirme a senha';
                      if (v != passwordCtrl.text) return 'As senhas não conferem';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: busy ? null : onCreate,
            icon: const Icon(Icons.check),
            label: Text(busy ? 'Criando…' : 'Criar conta'),
          ),
        ),
      ],
    );
  }
}
