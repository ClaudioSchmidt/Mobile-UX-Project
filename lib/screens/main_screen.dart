import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../core/api_service.dart';
import '../theme.dart';  // Add this import
import 'account_screen.dart';
import 'settings_screen.dart';
import 'matchmaking_screen.dart';
import 'chat_screen.dart';

class MainScreen extends StatefulWidget {
  final void Function(bool) toggleTheme; // Add this parameter
  final bool isDarkMode; // Add this parameter

  const MainScreen({super.key, required this.toggleTheme, required this.isDarkMode}); // Update constructor

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> chats = [];
  Timer? _timer;
  bool _isDarkMode;

  _MainScreenState() : _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadChats();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadChats();
    });
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
      final content = lastMessage['text'] ?? '📷';
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
      return DateFormat('HH:mm').format(dateTime);
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
          // Theme Switch
          Row(
            children: [
              Icon(
                _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                size: 20,
                color: Colors.white,
              ),
              Transform.scale(
                scale: 0.65,
                child: Switch(
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _isDarkMode = value;
                    });
                    widget.toggleTheme(value);
                  },
                  activeColor: Colors.black,
                  inactiveThumbColor: const Color(0xFF9C27B0),
                  inactiveTrackColor: Colors.white,
                  activeTrackColor: Colors.white,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
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
                          return ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(chat['chatname'] ?? 'Chat ${index + 1}'),
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
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
        ],
      ),
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
        backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
        foregroundColor: Theme.of(context).brightness == Brightness.light 
            ? Colors.white 
            : Colors.black,
      ),
    );
  }
}
