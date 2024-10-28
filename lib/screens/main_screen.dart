import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../screens/chat_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats(); // Lade die Chats, wenn der Bildschirm angezeigt wird
  }

  Future<void> _logout() async {
    bool success = await _apiService.logout();
    if (success) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout fehlgeschlagen')));
    }
  }

  Future<void> _confirmDeregistration() async {
    // Bestätigungsdialog anzeigen
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konto löschen'),
          content: Text('Bist du sicher, dass du dein Konto löschen möchtest? Diese Aktion kann nicht rückgängig gemacht werden.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Abbrechen
              child: Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Bestätigen
              child: Text('Löschen', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Wenn bestätigt, dann Konto löschen
      bool success = await _apiService.deregister();
      if (success) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Konto konnte nicht gelöscht werden')));
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

  Future<void> _createChat(String chatName) async {
    bool success = await _apiService.createChat(chatName);
    if (success) {
      // Füge den neuen Chat direkt zur lokalen Liste hinzu
      setState(() {
        chats.add({
          'chatid': chats.length + 1, // Dummy-ID für die Darstellung
          'chatname': chatName,
          'role': 'owner', // Setze den Standard-Rollenwert auf "owner"
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat erfolgreich erstellt')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Erstellen des Chats')));
    }
  }

  void _showAddChatDialog() {
    final TextEditingController chatNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Neuen Chat erstellen'),
          content: TextField(
            controller: chatNameController,
            decoration: InputDecoration(hintText: 'Chatname eingeben'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Dialog schließen
              child: Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final chatName = chatNameController.text.trim();
                if (chatName.isNotEmpty) {
                  _createChat(chatName);
                }
                Navigator.pop(context); // Dialog schließen
              },
              child: Text('Erstellen'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteChat(int chatId) async {
    bool success = await _apiService.deleteChat(chatId);
    if (success) {
      setState(() {
        chats.removeWhere((chat) => chat['chatid'] == chatId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat erfolgreich gelöscht')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Löschen des Chats')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddChatDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'deregister') {
                _confirmDeregistration();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
              PopupMenuItem(
                value: 'deregister',
                child: Text('Konto löschen'),
              ),
            ],
          ),
        ],
      ),
      body: chats.isEmpty
          ? Center(child: Text('Keine Chats vorhanden'))
          : ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return Dismissible(
                  key: Key(chat['chatid'].toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteChat(chat['chatid']);
                  },
                  child: ListTile(
                    title: Text(chat['chatname'] ?? 'Chat ${index + 1}'),
                    subtitle: Text('Chat ID: ${chat['chatid']}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chat['chatid'],
                            chatName: chat['chatname'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
