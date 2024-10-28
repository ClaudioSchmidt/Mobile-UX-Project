import 'package:flutter/material.dart';
import '../core/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final ApiService _apiService = ApiService();

  void _register() async {
    final userId = _userIdController.text;
    final password = _passwordController.text;
    final nickname = _nicknameController.text;
    final fullName = _fullNameController.text;

    final token = await _apiService.register(userId, password, nickname, fullName);

    if (token != null) {
      // Erfolgsmeldung anzeigen
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registrierung erfolgreich!')));
      
      // Weiterleitung zum Hauptbildschirm
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      // Fehlermeldung anzeigen
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registrierung fehlgeschlagen')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(labelText: 'User ID'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(labelText: 'Nickname'),
            ),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(labelText: 'Full Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}