import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livros_app/services/auth_service.dart';

import 'new_password_screen.dart';

class RecoveryWaitingScreen extends StatefulWidget {
  const RecoveryWaitingScreen({super.key});

  @override
  State<RecoveryWaitingScreen> createState() => _RecoveryWaitingScreenState();
}

class _RecoveryWaitingScreenState extends State<RecoveryWaitingScreen> {
  StreamSubscription? _sub;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();

    _sub = auth.authEvents().listen((ev) {
      if (!_mounted) return;
      final name = ev.toString(); // 'AuthChangeEvent.passwordRecovery'
      if (name.contains('passwordRecovery')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NewPasswordScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifique seu e-mail')),
      body: const Center(
        child: Text(
          'Enviamos um link para redefinir sua senha.\n'
          'Toque no link no e-mail e voltaremos para esta tela automaticamente.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
