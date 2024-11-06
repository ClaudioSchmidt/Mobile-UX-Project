import 'package:flutter/material.dart';
import '../core/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();

  void _login() async {
    final userId = _userIdController.text;
    final password = _passwordController.text;

    final token = await _apiService.login(userId, password);

    if (token != null) {
      // Erfolgsmeldung anzeigen
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login erfolgreich!')));
      
      // Weiterleitung zum Hauptbildschirm
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      // Fehlermeldung anzeigen
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login fehlgeschlagen')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(labelText: 'User ID'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Noch keinen Account? Registrieren'),
            ),
          ],
        ),
      ),
    );
  }
}