import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livros_app/services/auth_service.dart';
import 'verify_email_waiting_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final emailC = TextEditingController();
  final passC  = TextEditingController();
  final pass2C = TextEditingController();
  final nameC  = TextEditingController();

  bool loading = false;
  bool obscure1 = true;
  bool obscure2 = true;
  bool agreeTerms = false;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420))..forward();

  @override
  void dispose() {
    _fadeCtrl.dispose();
    emailC.dispose();
    passC.dispose();
    pass2C.dispose();
    nameC.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa aceitar os Termos de uso e a Política de privacidade.')),
      );
      return;
    }

    final auth = context.read<AuthService>();
    setState(() => loading = true);
    try {
      await auth.signUpWithPassword(
        email: emailC.text.trim(),
        password: passC.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyEmailWaitingScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Falha no cadastro: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  double _passwordStrength(String s) {
    if (s.isEmpty) return 0;
    int score = 0;
    if (s.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(s)) score++;
    if (RegExp(r'[a-z]').hasMatch(s)) score++;
    if (RegExp(r'\d').hasMatch(s)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(s)) score++; // qualquer caractere especial
    return (score / 5).clamp(0, 1);
  }

  String _passwordLabel(double v) {
    if (v < 0.34) return 'Senha fraca';
    if (v < 0.67) return 'Senha média';
    return 'Senha forte';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final strength = _passwordStrength(passC.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar conta'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.surface,
                  cs.surfaceVariant.withOpacity(0.55),
                  cs.surface,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: FadeTransition(
                  opacity: _fadeCtrl,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Card(
                          elevation: 6,
                          color: cs.surface.withOpacity(0.78),
                          shadowColor: cs.primary.withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Crie sua conta',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  _FieldWrapper(
                                    child: TextFormField(
                                      controller: nameC,
                                      decoration: const InputDecoration(
                                        labelText: 'Nome (opcional)',
                                        prefixIcon: Icon(Icons.person_outline_rounded),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  _FieldWrapper(
                                    child: TextFormField(
                                      controller: emailC,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [AutofillHints.email],
                                      decoration: const InputDecoration(
                                        labelText: 'E-mail',
                                        prefixIcon: Icon(Icons.alternate_email_rounded),
                                      ),
                                      validator: (v) {
                                        final t = (v ?? '').trim();
                                        if (t.isEmpty) return 'Informe seu e-mail';
                                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(t)) {
                                          return 'E-mail inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  _FieldWrapper(
                                    child: TextFormField(
                                      controller: passC,
                                      obscureText: obscure1,
                                      decoration: InputDecoration(
                                        labelText: 'Senha',
                                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => obscure1 = !obscure1),
                                          icon: Icon(obscure1
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded),
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      validator: (v) {
                                        final s = v ?? '';
                                        if (s.isEmpty) return 'Informe uma senha';
                                        if (s.length < 8) return 'Use pelo menos 8 caracteres';
                                        if (!RegExp(r'[A-Z]').hasMatch(s)) {
                                          return 'Inclua ao menos 1 letra maiúscula';
                                        }
                                        if (!RegExp(r'\d').hasMatch(s)) {
                                          return 'Inclua ao menos 1 número';
                                        }
                                        if (!RegExp(r'[^A-Za-z0-9]').hasMatch(s)) {
                                          return 'Inclua ao menos 1 caractere especial';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        LinearProgressIndicator(
                                          value: strength,
                                          minHeight: 6,
                                          backgroundColor: cs.outlineVariant.withOpacity(0.4),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _passwordLabel(strength),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: strength < 0.34
                                                ? Colors.redAccent
                                                : (strength < 0.67 ? cs.secondary : Colors.green),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  _FieldWrapper(
                                    child: TextFormField(
                                      controller: pass2C,
                                      obscureText: obscure2,
                                      decoration: InputDecoration(
                                        labelText: 'Confirmar senha',
                                        prefixIcon: const Icon(Icons.lock_person_outlined),
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => obscure2 = !obscure2),
                                          icon: Icon(obscure2
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded),
                                        ),
                                      ),
                                      validator: (v) {
                                        if ((v ?? '').isEmpty) return 'Confirme sua senha';
                                        if (v != passC.text) return 'As senhas não coincidem';
                                        return null;
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    children: [
                                      Checkbox.adaptive(
                                        value: agreeTerms,
                                        onChanged: (v) => setState(() => agreeTerms = v ?? false),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Aceito os Termos de uso e a Política de privacidade.',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  SizedBox(
                                    height: 50,
                                    child: FilledButton.tonal(
                                      onPressed: loading ? null : _register,
                                      child: loading
                                          ? const CircularProgressIndicator(strokeWidth: 2)
                                          : const Text('Cadastrar'),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Align(
                                    alignment: Alignment.center,
                                    child: TextButton(
                                      onPressed: loading ? null : () => Navigator.of(context).pop(),
                                      child: const Text('Já tenho uma conta'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _FieldWrapper extends StatelessWidget {
  final Widget child;
  const _FieldWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: child,
      ),
    );
  }
}
