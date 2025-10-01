import 'package:flutter/material.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RootContent();
  }
}

class _RootContent extends StatelessWidget {
  const _RootContent();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'RootShell: navegação principal aqui.\n'
          'O AuthService usa navigatorKey global para abrir telas de autenticação.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
