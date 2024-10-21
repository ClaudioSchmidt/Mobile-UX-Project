import 'package:flutter/material.dart';
import 'chat_room_screen.dart';
import '../core/api_service.dart';
import '../core/token_storage.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ApiService _apiService = ApiService();
  final TokenStorage _tokenStorage = TokenStorage();
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getChats();
  }

  Future<void> _getChats() async {
    String? token = await _tokenStorage.getToken();
    if (token != null) {
      List<Map<String, dynamic>>? chats = await _apiService.getChats(token);

      if (chats != null) {
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load chats!')),
        );
      }
    }
  }

  Future<void> _createChat() async {
    String? token = await _tokenStorage.getToken();
    if (token == null) return;

    TextEditingController chatNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Chat'),
          content: TextField(
            controller: chatNameController,
            decoration: const InputDecoration(hintText: 'Enter chat name'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String chatName = chatNameController.text.trim();
                if (chatName.isNotEmpty) {
                  bool success = await _apiService.createChat(token, chatName);
                  if (success) {
                    Navigator.of(context).pop();
                    _getChats();  // Refresh the chat list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat created successfully!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create chat')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
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
        title: const Text('Your Chats'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];

                return ListTile(
                  title: Text(chat['chatname'] ?? 'Unnamed Chat'),
                  subtitle: Text('Chat ID: ${chat['chatid']}'),
                  onTap: () {
                    if (chat['chatid'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomScreen(
                            chatId: chat['chatid'],
                            chatName: chat['chatname'] ?? 'Unnamed Chat',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid chat ID')),
                      );
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createChat,
        child: const Icon(Icons.add),
        tooltip: 'Create new chat',
      ),
    );
  }
}
