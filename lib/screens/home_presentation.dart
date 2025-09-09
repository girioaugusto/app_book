import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livros_app/providers/tabs_controller.dart';

class HomePresentation extends StatelessWidget {
  const HomePresentation({super.key});

  @override
  Widget build(BuildContext context) {
    const appGreen = Color(0xFF2E7D32);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Image.asset('lib/assets/logo.png', width: 160),
            const SizedBox(height: 20),
            const Text(
              "Bem-vindo ao Entre Páginas",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: appGreen),
            ),
            const SizedBox(height: 10),
            const Text(
              "Gerencie sua biblioteca, acompanhe o progresso e guarde seus favoritos.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _Feature(icon: Icons.library_books, label: "Biblioteca"),
                _Feature(icon: Icons.star, label: "Favoritos"),
                _Feature(icon: Icons.bar_chart, label: "Progresso"),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Ir para a aba Buscar (ID 2 => índice 1)
                  context.read<TabsController>().setIndex(1);
                },
                icon: const Icon(Icons.add),
                label: const Text("Adicionar meu primeiro livro"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
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
