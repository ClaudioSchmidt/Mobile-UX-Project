import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../core/api_service.dart';
import '../theme.dart';
import 'account_screen.dart';
import 'settings_screen.dart';
import 'matchmaking_screen.dart';
import 'chat_screen.dart';
import '../widgets/notifications_dialog.dart';
import '../widgets/language_badge.dart';
import '../util/chat_name_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  final void Function(bool) toggleTheme;
  final bool isDarkMode;

  const MainScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> chats = [];
  Timer? _timer;
  bool _isDarkMode;
  Set<int> likedChats = {};
  String? userNick;
  bool _showMainChat = false;

  _MainScreenState() : _isDarkMode = false;

  final List<Map<String, dynamic>> _mockNotifications = [
    {
      'type': 'chat_request',
      'title': 'New Chat Request',
      'message': 'Sarah wants to chat with you',
      'time': DateTime.now().subtract(const Duration(minutes: 5)),
      'read': false,
      'actions': ['accept', 'decline']
    },
    {
      'type': 'like',
      'title': 'New Like',
      'message': 'Michael liked your profile',
      'time': DateTime.now().subtract(const Duration(hours: 1)),
      'read': false,
    },
    {
      'type': 'like',
      'title': 'New Like',
      'message': 'Anna liked your profile',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'read': true,
    },
    {
      'type': 'system',
      'title': 'App Update Available',
      'message': 'Version 2.0.1 is now available. Update now!',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'read': true,
    },
    {
      'type': 'message',
      'title': 'New Message',
      'message': 'Anna: Hi, how are you?',
      'time': DateTime.now().subtract(const Duration(hours: 3)),
      'read': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadChats();
    _startAutoRefresh();
    _loadLikedChats();
    _loadUserNick();
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
          title: const Text('Logout'),
          content: const Text('Do you really want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
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
          const SnackBar(content: Text('Logout failed')),
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
      final sender = lastMessage['usernick'] ?? 'Unknown';
      final content = lastMessage['text'] ?? '📷';
      final timestamp = lastMessage['time'] ?? '';
      final formattedTimestamp = _formatTimestamp(timestamp);
      return {
        'message': '$sender: $content',
        'timestamp': formattedTimestamp,
      };
    }
    return {
      'message': 'No messages yet',
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

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => NotificationsDialog(
        notifications: _mockNotifications,
        onMarkAllRead: () {
          setState(() {
            for (var notification in _mockNotifications) {
              notification['read'] = true;
            }
          });
        },
      ),
    );
  }

  Future<void> _loadLikedChats() async {
    final prefs = await SharedPreferences.getInstance();
    final likedChatIds = prefs.getStringList('likedChats') ?? [];
    setState(() {
      likedChats = likedChatIds.map(int.parse).toSet();
    });
  }

  Future<void> _toggleLike(int chatId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (likedChats.contains(chatId)) {
        likedChats.remove(chatId);
      } else {
        likedChats.add(chatId);
      }
      prefs.setStringList('likedChats', likedChats.map((id) => id.toString()).toList());
    });
  }

  Future<void> _onLikeChanged(bool isLiked) async {
    await _loadLikedChats();
    setState(() {});
  }

  Future<void> _loadUserNick() async {
    final hash = await _apiService.getUserHash();
    final profiles = await _apiService.getProfiles();
    if (profiles != null && hash != null) {
      final userProfile = profiles.firstWhere(
        (profile) => profile['hash'] == hash,
        orElse: () => {'nickname': 'User'},
      );
      setState(() {
        userNick = userProfile['nickname'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${userNick ?? '...'}'),
        leading: IconButton(
          icon: Icon(_showMainChat ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
          onPressed: () {
            setState(() {
              _showMainChat = !_showMainChat;
            });
          },
        ),
        actions: [
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
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_mockNotifications.any((n) => !n['read']))
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () => _showNotifications(context),
          ),
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
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                final visibleChats = chats.where((chat) => 
                  _showMainChat || chat['chatname'] != 'Main Chat'
                ).toList();

                if (visibleChats.isEmpty) {
                  return const Center(
                    child: Text(
                      'No chats yet. Start matchmaking!',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    if (!_showMainChat && chat['chatname'] == 'Main Chat') {
                      return const SizedBox.shrink();
                    }
                    final chatInfo = ChatNameParser.parse(chat['chatname'] ?? '');
                    final isLiked = likedChats.contains(chat['chatid']);
                    
                    return FutureBuilder<Map<String, String>>(
                      future: _getLastMessage(chat['chatid']),
                      builder: (context, snapshot) {
                        final lastMessage = snapshot.data?['message'] ?? 'Loading...';
                        final timestamp = snapshot.data?['timestamp'] ?? '';
                        return ListTile(
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(chatInfo.displayName),
                              if (chatInfo.languageCode != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: LanguageBadge(
                                    languageCode: chatInfo.languageCode!,
                                    languageName: chatInfo.languageName!,
                                    level: chatInfo.level!,
                                  ),
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
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Text(
                                  timestamp, 
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : null,
                            ),
                            onPressed: () => _toggleLike(chat['chatid']),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatId: chat['chatid'],
                                  chatName: chat['chatname'],
                                  onLikeChanged: _onLikeChanged,
                                ),
                              ),
                            );
                            _refreshChats();
                          },
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
