import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Codex Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement Firebase Auth logic
          },
          child: const Text('Giriş Yap'),
        ),
      ),
    );
  }
}
