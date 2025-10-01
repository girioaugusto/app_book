import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livros_app/services/auth_service.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final passC = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    passC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthService>();
    setState(() => loading = true);
    try {
      await auth.updatePassword(passC.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha atualizada! Faça login novamente.')),
      );
      Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar senha: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova senha')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: passC,
              decoration: const InputDecoration(labelText: 'Nova senha'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : _save,
              child: Text(loading ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
