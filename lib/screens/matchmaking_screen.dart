import 'package:flutter/material.dart';

class MatchmakingScreen extends StatelessWidget {
  const MatchmakingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matchmaking'),
        automaticallyImplyLeading: false, // Prevents the back arrow from showing
      ),
      body: const Center(
        child: Text(
          'Matchmaking Options',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      // Bottom Center Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context); // Navigate back to MainScreen
        },
        label: const Text('Back to Chats'),
        icon: const Icon(Icons.chat),
      ),
    );
  }
}
