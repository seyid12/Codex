import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/auth_repository.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      
      if (_isLogin) {
        await authRepo.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await authRepo.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          'student', // default role
        );
      }

      if (mounted) {
        // Başarılı olursa dashboard'a yönlendir
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.psychology, size: 80, color: Color(0xFF00F0FF)),
                const SizedBox(height: 16),
                const Text(
                  'CODEX',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Color(0xFFFF007F),
                    shadows: [
                      Shadow(
                        color: Color(0xFFFF007F),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                if (!_isLogin)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Lütfen adınızı girin' : null,
                  ),
                if (!_isLogin) const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) =>
                      value!.isEmpty || !value.contains('@') ? 'Geçerli bir e-posta girin' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) =>
                      value!.length < 6 ? 'Şifre en az 6 karakter olmalı' : null,
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(
                    _isLogin
                        ? 'Hesabınız yok mu? Kayıt Olun'
                        : 'Zaten hesabınız var mı? Giriş Yapın',
                    style: const TextStyle(color: Color(0xFF00F0FF)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
