import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../providers/tabs_controller.dart';
import '../providers/theme_controller.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
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
    context.read<TabsController>().setIndex(0);

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    final isDark = themeCtrl.mode == ThemeMode.dark;

    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    // Tenta pegar o username do metadata; se não houver, usa prefixo do e-mail.
    String displayName = 'Convidado';
    if (user != null) {
      final meta = user.userMetadata ?? {};
      final metaUsername = meta['username'] as String?;
      displayName = metaUsername?.trim().isNotEmpty == true
          ? metaUsername!.trim()
          : (user.email != null ? user.email!.split('@').first : 'Usuário');
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
              accountName: Text(displayName),
              accountEmail: Text(user?.email ?? ''),
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Tema escuro'),
              value: isDark,
              onChanged: (v) => themeCtrl.toggleDark(v),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                Navigator.pop(context); // fecha o Drawer
                await _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
