import 'package:flutter/material.dart';
import '../core/token_storage.dart';
import '../core/api_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final TokenStorage _tokenStorage = TokenStorage();
  bool _isLoggedIn = false; // Variable für den Anmeldestatus

  void _login() async {
    String? token = await _apiService.login(
      _userIdController.text,
      _passwordController.text,
    );

    if (token != null) {
      await _tokenStorage.saveToken(token);
      setState(() {
        _isLoggedIn = true; // Benutzer ist eingeloggt
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful! Token: $token')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed!')),
      );
    }
  }

  void _logout() async {
    await _apiService.logout();
    setState(() {
      _isLoggedIn = false; // Benutzer ist ausgeloggt
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully!')),
    );
  }

  void _deregister() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deregistration'),
          content: const Text('Are you sure you want to deregister? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Bestätigen
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Abbrechen
              child: const Text('No'),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      bool success = await _apiService.deregister(_userIdController.text);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deregistration successful!')),
        );
        setState(() {
          _isLoggedIn = false; // Benutzer ist ausgeloggt
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deregistration failed!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
                const SizedBox(width: 10),
                if (_isLoggedIn) 
                  ElevatedButton(
                    onPressed: _logout,
                    child: const Text('Logout'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoggedIn)
              ElevatedButton(
                onPressed: _deregister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Deregister'),
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                );
              },
              child: const Text('Don\'t have an account? Register here'),
            ),
          ],
        ),
      ),
    );
  }
}
