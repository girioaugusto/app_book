// lib/screens/home_presentation.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:livros_app/widgets/rotating_quotes_card.dart';
import 'package:livros_app/providers/tabs_controller.dart';
import 'package:livros_app/providers/theme_controller.dart'; // tema
import 'package:livros_app/services/auth_service.dart';       // logout
import 'package:livros_app/screens/login_screen.dart';        // voltar ao login

class HomePresentation extends StatelessWidget {
  const HomePresentation({super.key});

  Future<void> _confirmAndLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sair da conta?'),
            content: const Text('Você precisará fazer login novamente para usar o app.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sair')),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    await context.read<AuthService>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const appGreen = Color(0xFF2E7D32);
    final themeCtrl = context.watch<ThemeController>();
    final isDark = themeCtrl.mode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: isDark ? 'Usar tema claro' : 'Usar tema escuro',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeCtrl.toggleDark(!isDark),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmAndLogout(context),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // LOGO
              Image.asset('lib/assets/logo.png', width: 160),

              const SizedBox(height: 20),

              // TÍTULO + DESCRIÇÃO
              const Text(
                "Bem-vindo ao Entre Páginas",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: appGreen,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Gerencie sua biblioteca, acompanhe o progresso e guarde seus favoritos.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87),
                ),
              ),

              const SizedBox(height: 60),

              // ÍCONES (destaques)
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Feature(icon: Icons.library_books, label: "Biblioteca"),
                  _Feature(icon: Icons.favorite, label: "Favoritos"),
                  _Feature(icon: Icons.coffee, label: "Cafés"),
                ],
              ),

              const SizedBox(height: 60),

              // Frase do dia (cor muda automaticamente no DARK)
              const RotatingQuoteCard(dailyOnly: true),

              const Spacer(),

              // CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<TabsController>().setIndex(1);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Adicionar meu primeiro livro"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Feature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    const appGreen = Color(0xFF2E7D32);
    return Column(
      children: [
        Icon(icon, size: 40, color: appGreen),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
