import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Add this import
import 'dart:convert'; // Add this import
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
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
  Timer? _timer; // Add this line
  Map<int, bool> favoriteChats = {}; // Add this line

  @override
  void initState() {
    super.initState();
    _loadChats();
    _loadFavoriteChats(); // Add this line
    _startAutoRefresh(); // Add this line
  }

  @override
  void dispose() {
    _timer?.cancel(); // Add this line
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadChats();
    });
  }

  Future<void> _loadFavoriteChats() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteChatsString = prefs.getString('favoriteChats') ?? '{}';
    setState(() {
      favoriteChats = (jsonDecode(favoriteChatsString) as Map<String, dynamic>)
          .map((key, value) => MapEntry(int.parse(key), value));
    });
  }

  Future<void> _saveFavoriteChats() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteChatsMap = favoriteChats.map((key, value) => MapEntry(key.toString(), value)); // Convert keys to String
    await prefs.setString('favoriteChats', jsonEncode(favoriteChatsMap));
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

  Future<void> _refreshChats() async {
    await _loadChats();
  }

  Future<Map<String, String>> _getLastMessage(int chatId) async {
    final messages = await _apiService.getMessages(chatId);
    if (messages != null && messages.isNotEmpty) {
      final lastMessage = messages.last;
      final sender = lastMessage['usernick'] ?? 'Unbekannt';
      final content = lastMessage['text'] ?? 'Bildnachricht';
      final timestamp = lastMessage['time'] ?? '';
      final formattedTimestamp = _formatTimestamp(timestamp);
      return {
        'message': '$sender: $content',
        'timestamp': formattedTimestamp,
      };
    }
    return {
      'message': 'Fang den ersten Schritt zum Sprachenmeister an!',
      'timestamp': '',
    };
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateFormat('yyyy-MM-dd_HH-mm-ss').parse(timestamp);
      return DateFormat('HH:mm - dd. MMMM yyyy').format(dateTime);
    } catch (e) {
      return timestamp;
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
          // Notification Icon
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Notifications',
            onPressed: () {
              // No functionality for now
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
                      return FutureBuilder<Map<String, String>>(
                        future: _getLastMessage(chat['chatid']),
                        builder: (context, snapshot) {
                          final lastMessage = snapshot.data?['message'] ?? 'Lade...';
                          final timestamp = snapshot.data?['timestamp'] ?? '';
                          final isFavorite = favoriteChats[chat['chatid']] ?? false;
                          return ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(chat['chatname'] ?? 'Chat ${index + 1}'),
                                ),
                                if (isFavorite)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.favorite, color: Colors.red, size: 16),
                                  ),
                              ],
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(timestamp, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    chatId: chat['chatid'],
                                    chatName: chat['chatname'],
                                    isFavorite: isFavorite, // Pass the favorite status
                                  ),
                                ),
                              );

                              if (result != null && result is bool) {
                                setState(() {
                                  favoriteChats[chat['chatid']] = result;
                                });
                                await _saveFavoriteChats();
                              }
                            },
                          );
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
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MatchmakingScreen()),
          );
          await _refreshChats();
        },
        label: const Text('Matchmaking'),
        icon: const Icon(Icons.people),
      ),
    );
  }
}
