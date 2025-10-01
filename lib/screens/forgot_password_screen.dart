import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livros_app/services/auth_service.dart';
import 'recovery_waiting_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final emailC = TextEditingController();
  bool loading = false;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420))
        ..forward();

  @override
  void dispose() {
    _fadeCtrl.dispose();
    emailC.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    setState(() => loading = true);
    try {
      await auth.sendPasswordReset(emailC.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RecoveryWaitingScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro enviando e-mail: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar senha'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo com gradiente suave
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

          // Orbs sutis para coerência visual
          Positioned(
            top: -90,
            right: -40,
            child: _GlowOrb(color: cs.primary.withOpacity(0.22), size: 220),
          ),
          Positioned(
            bottom: -110,
            left: -40,
            child: _GlowOrb(color: cs.tertiary.withOpacity(0.18), size: 260),
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
                                  // Título
                                  Text(
                                    'Vamos redefinir sua senha',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Informe o e-mail cadastrado. Vamos enviar um link para você criar uma nova senha.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Campo de e-mail com validação
                                  _FieldWrapper(
                                    child: TextFormField(
                                      controller: emailC,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [AutofillHints.email],
                                      textInputAction: TextInputAction.done,
                                      decoration: const InputDecoration(
                                        labelText: 'E-mail',
                                        hintText: 'voce@exemplo.com',
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
                                      onFieldSubmitted: (_) => _sendReset(),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Dicas rápidas
                                  _HintRow(
                                    icon: Icons.check_circle_outline_rounded,
                                    text: 'Verifique também a pasta Spam/Lixo eletrônico.',
                                  ),
                                  const SizedBox(height: 6),
                                  _HintRow(
                                    icon: Icons.schedule_rounded,
                                    text: 'O e-mail pode levar alguns minutos para chegar.',
                                  ),

                                  const SizedBox(height: 22),

                                  // Botão principal
                                  SizedBox(
                                    height: 50,
                                    child: FilledButton.tonal(
                                      onPressed: loading ? null : _sendReset,
                                      style: ButtonStyle(
                                        shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 220),
                                        child: loading
                                            ? const SizedBox(
                                                key: ValueKey('prog'),
                                                height: 22,
                                                width: 22,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Text('Enviar link de recuperação', key: ValueKey('txt')),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Voltar ao login
                                  Align(
                                    alignment: Alignment.center,
                                    child: TextButton.icon(
                                      onPressed: loading ? null : () => Navigator.of(context).pop(),
                                      icon: const Icon(Icons.login_rounded),
                                      label: const Text('Voltar ao login'),
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

/// Wrapper visual para os TextFields sem alterar o Theme global
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

/// Linha de dica com ícone
class _HintRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HintRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
