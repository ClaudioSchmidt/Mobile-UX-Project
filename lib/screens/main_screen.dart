import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../screens/account_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/matchmaking_screen.dart';
import '../screens/chat_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout bestätigen'),
          content: const Text('Möchtest du dich wirklich ausloggen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      bool success = await _apiService.logout();
      if (success) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout fehlgeschlagen')),
        );
      }
    }
  }

  Future<void> _loadChats() async {
    final fetchedChats = await _apiService.getChats();
    if (fetchedChats != null) {
      setState(() {
        chats = fetchedChats;
      });
    }
  }

  Future<void> _createChat() async {
    final TextEditingController chatNameController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neuen Chat erstellen'),
          content: TextField(
            controller: chatNameController,
            decoration: const InputDecoration(
              hintText: 'Gib den Chatnamen ein',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Erstellen'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && chatNameController.text.isNotEmpty) {
      final success = await _apiService.createChat(chatNameController.text.trim());
      if (success) {
        await _loadChats();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat erfolgreich erstellt')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Erstellen des Chats')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ongoing Chats'),
        actions: [
          // Account Icon
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Account',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountScreen()),
              );
            },
          ),
          // Settings Icon
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          // Add Chat Icon
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Chat erstellen',
            onPressed: _createChat,
          ),
          // Logout Icon
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          chats.isEmpty
              ? const Center(child: Text('Keine Chats vorhanden'))
              : Expanded(
                  child: ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return ListTile(
                        title: Text(chat['chatname'] ?? 'Chat ${index + 1}'),
                        subtitle: Text('Chat ID: ${chat['chatid']}'),
                        onTap: () async {
                          final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                            chatId: chat['chatid'],
                            chatName: chat['chatname'],
                            ),
                          ),
                          );

                          if (result == true) {
                          await _loadChats();
                          }
                        },
                        );
                      },
                  ),
                ),
        ],
      ),
      // Bottom Center Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MatchmakingScreen()),
          );
        },
        label: const Text('Start Matchmaking'),
        icon: const Icon(Icons.people),
      ),
    );
  }
}
