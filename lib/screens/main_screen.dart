import 'package:flutter/material.dart';
import '../core/api_service.dart';
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
    bool success = await _apiService.logout();
    if (success) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logout fehlgeschlagen')));
    }
  }

  Future<void> _confirmDeregistration() async {
    // Bestätigungsdialog anzeigen
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konto löschen'),
          content: const Text('Bist du sicher, dass du dein Konto löschen möchtest? Diese Aktion kann nicht rückgängig gemacht werden.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Löschen', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      bool success = await _apiService.deregister();
      if (success) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konto konnte nicht gelöscht werden')));
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
    final response = await _apiService.getChats();
    final createdChat = response?.firstWhere((chat) => chat['chatname'] == chatName, orElse: () => null);

    if (createdChat != null) {
      setState(() {
        chats.add(createdChat);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat erfolgreich erstellt')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fehler beim Erstellen des Chats')));
    }
  }
}

  void _showAddChatDialog() {
    final TextEditingController chatNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neuen Chat erstellen'),
          content: TextField(
            controller: chatNameController,
            decoration: const InputDecoration(hintText: 'Chatname eingeben'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final chatName = chatNameController.text.trim();
                if (chatName.isNotEmpty) {
                  _createChat(chatName);
                }
                Navigator.pop(context);
              },
              child: const Text('Erstellen'),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat erfolgreich gelöscht')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fehler beim Löschen des Chats')));
    }
  }

Future<void> _leaveChat(int chatId) async {
  bool success = await _apiService.leaveChat(chatId);

  if (success) {
    setState(() {
      chats.removeWhere((chat) => chat['chatid'] == chatId);
    });

    // Optional: Chatliste vom Server erneut laden
    await _loadChats();  // Dies stellt sicher, dass der Server-Status synchron ist

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erfolgreich aus dem Chat ausgetreten')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fehler beim Austreten aus dem Chat')),
    );
  }
}

Future<void> _joinChat(int chatId) async {
  bool success = await _apiService.joinChat(chatId);
  if (success) {
    final response = await _apiService.getChats();
    final joinedChat = response?.firstWhere((chat) => chat['chatid'] == chatId, orElse: () => null);

    if (joinedChat != null) {
      setState(() {
        chats.add(joinedChat);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erfolgreich dem Chat beigetreten')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Beitritt zum Chat')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fehler beim Beitritt zum Chat')),
    );
  }
}

void _showJoinChatDialog() async {
  final availableChats = await _apiService.getChats(); // Annahme: Dies gibt auch die Chats zurück, die verfügbar sind, aber denen der User noch nicht beigetreten ist

  if (availableChats == null || availableChats.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Keine verfügbaren Chats zum Beitreten')),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Chat beitreten'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableChats.length,
            itemBuilder: (context, index) {
              final chat = availableChats[index];
              final chatId = chat['chatid']; // Sicherstellen, dass chatId korrekt ist
              print("Chat ID im Dialog: $chatId"); // Debugging: Ausgabe der Chat ID

              return ListTile(
                title: Text(chat['chatname'] ?? 'Chat ${index + 1}'),
                trailing: ElevatedButton(
                  onPressed: () {
                    if (chatId != null) {
                      print("Beitreten mit Chat ID: $chatId");
                      _joinChat(chatId); // Aufruf der Methode zum Beitritt
                      Navigator.of(context).pop();
                    } else {
                      print("Ungültige Chat ID, kann dem Chat nicht beitreten.");
                    }
                  },
                  child: const Text('Beitreten'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Abbrechen'),
          ),
        ],
      );
    },
  );
}

Future<void> _inviteUser(int chatId) async {
  TextEditingController invitedHashController = TextEditingController();

  // Einladungs-Dialog anzeigen, um die invitedHash zu erfassen
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Benutzer einladen'),
        content: TextField(
          controller: invitedHashController,
          decoration: const InputDecoration(hintText: 'Benutzerhash eingeben'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              String invitedHash = invitedHashController.text.trim();
              if (invitedHash.isNotEmpty) {
                bool success = await _apiService.inviteUser(chatId, invitedHash);
                if (success) {
                  // Erfolgreiche Einladung
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Einladung erfolgreich gesendet!')),
                  );
                  // Chatliste nach erfolgreicher Einladung erneut laden
                  await _loadChats();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fehler bei der Einladung')),
                  );
                }
                Navigator.of(context).pop();
              }
            },
            child: const Text('Einladen'),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddChatDialog,
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: _showJoinChatDialog, // Neuer Dialog zum Beitreten eines vorhandenen Chats
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
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
              const PopupMenuItem(
                value: 'deregister',
                child: Text('Konto löschen'),
              ),
            ],
          ),
        ],
      ),
      body: chats.isEmpty
          ? const Center(child: Text('Keine Chats vorhanden'))
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteChat(chat['chatid']);
                  },
                  child: ListTile(
                    title: Text(chat['chatname'] ?? 'Chat ${index + 1}'),
                    subtitle: Text('Chat ID: ${chat['chatid']}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'leave') {
                          _leaveChat(chat['chatid']);   // Chat verlassen
                        } else if (value == 'invite') {
                          _inviteUser(chat['chatid']);    // Benutzer einladen
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'leave',
                          child: Text('Austreten'),
                        ),
                        const PopupMenuItem(
                          value: 'invite',
                          child: Text('Benutzer einladen'),
                        ),
                      ],
                    ),
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
