import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:livros_app/services/auth_service.dart';
import 'verify_email_waiting_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final emailC = TextEditingController();
  final passC  = TextEditingController();

  bool loading = false;
  bool obscure = true;
  bool remember = false;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420))
        ..forward();

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  Future<void> _loadRemembered() async {
    final sp = await SharedPreferences.getInstance();
    remember = sp.getBool('remember_email') ?? false;
    if (remember) emailC.text = sp.getString('remembered_email') ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _persistRemember() async {
    final sp = await SharedPreferences.getInstance();
    if (remember) {
      await sp.setBool('remember_email', true);
      await sp.setString('remembered_email', emailC.text.trim());
    } else {
      await sp.remove('remember_email');
      await sp.remove('remembered_email');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    setState(() => loading = true);
    try {
      await _persistRemember();
      await auth.signInWithPassword(
        email: emailC.text.trim(),
        password: passC.text,
      );
      // Navegação será resolvida pelos eventos no AuthService.
    } catch (e) {
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha no login: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => loading = true);
    try {
      await context.read<AuthService>().signInWithGoogle();
    } catch (e) {
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha no Google: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo com gradiente sutil
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

          // Orbs de brilho de fundo (peso visual sem poluir)
          Positioned(
            top: -90,
            right: -40,
            child: _GlowOrb(color: cs.primary.withOpacity(0.25), size: 220),
          ),
          Positioned(
            bottom: -110,
            left: -40,
            child: _GlowOrb(color: cs.tertiary.withOpacity(0.20), size: 260),
          ),

          // Conteúdo
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FadeTransition(
                opacity: _fadeCtrl,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // efeito vidro
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
                          child: AutofillGroup(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // LOGO + título
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, bottom: 14),
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          'lib/assets/logo.png', // ajuste se necessário
                                          height: 120,
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Bem-vindo ao Entre Páginas',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Acesse sua estante digital',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // E-mail
                                  _FieldWrapper(
                                    child: TextFormField(
                                      controller: emailC,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.username, AutofillHints.email],
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'E-mail',
                                        hintText: 'voce@exemplo.com',
                                        prefixIcon: Icon(Icons.alternate_email_rounded),
                                      ),
                                      validator: (v) {
                                        final t = (v ?? '').trim();
                                        if (t.isEmpty) return 'Informe seu e-mail';
                                        if (!t.contains('@')) return 'E-mail inválido';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Senha
                                  _FieldWrapper(
                                    child: TextFormField(
                                      controller: passC,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [AutofillHints.password],
                                      obscureText: obscure,
                                      onFieldSubmitted: (_) => _login(),
                                      decoration: InputDecoration(
                                        labelText: 'Senha',
                                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => obscure = !obscure),
                                          tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
                                          icon: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 160),
                                            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                                            child: Icon(
                                              key: ValueKey(obscure),
                                              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                            ),
                                          ),
                                        ),
                                      ),
                                      validator: (v) => (v ?? '').isEmpty ? 'Informe sua senha' : null,
                                    ),
                                  ),

                                  // Lembrar e-mail
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6, bottom: 6),
                                    child: SwitchListTile.adaptive(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      title: const Text('Lembrar e-mail neste dispositivo'),
                                      value: remember,
                                      onChanged: (v) => setState(() => remember = v),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Entrar
                                  SizedBox(
                                    height: 50,
                                    child: FilledButton.tonal(
                                      onPressed: loading ? null : _login,
                                      style: ButtonStyle(
                                        shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 220),
                                        child: loading
                                            ? const SizedBox(
                                                key: ValueKey('p'),
                                                height: 22, width: 22,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Text('Entrar', key: ValueKey('t')),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 14),
                                  _OrDivider(color: cs),
                                  const SizedBox(height: 14),

                                  // Entrar com Google (sem ícone, visual limpo)
                                  SizedBox(
                                    height: 50,
                                    child: OutlinedButton(
                                      onPressed: loading ? null : _loginWithGoogle,
                                      style: ButtonStyle(
                                        side: WidgetStatePropertyAll(
                                          BorderSide(color: cs.outlineVariant),
                                        ),
                                        shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        overlayColor: WidgetStatePropertyAll(
                                          cs.primary.withOpacity(0.06),
                                        ),
                                      ),
                                      child: const Text(
                                        'Entrar com Google',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),
                                  const Divider(height: 26),

                                  // Ações secundárias
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      TextButton.icon(
                                        onPressed: loading
                                            ? null
                                            : () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                                ),
                                        icon: const Icon(Icons.person_add_alt_1_rounded),
                                        label: const Text('Criar conta'),
                                      ),
                                      TextButton.icon(
                                        onPressed: loading
                                            ? null
                                            : () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                                ),
                                        icon: const Icon(Icons.help_outline_rounded),
                                        label: const Text('Esqueci minha senha'),
                                      ),
                                    ],
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
          ),
        ],
      ),
    );
  }
}

/// Orb de brilho suave para “peso” de fundo
class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: size * 0.6, spreadRadius: size * 0.25),
          ],
        ),
      ),
    );
  }
}

/// Wrapper que dá um look consistente aos TextFields sem mexer no Theme global
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

/// Divider estilizado com “ou”
class _OrDivider extends StatelessWidget {
  final ColorScheme color;
  const _OrDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: color.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('ou', style: TextStyle(color: color.outline, fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Divider(color: color.outlineVariant)),
      ],
    );
  }
}
