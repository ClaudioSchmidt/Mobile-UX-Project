import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/token_storage.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({Key? key}) : super(key: key);

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ApiService _apiService = ApiService();
  final TokenStorage _tokenStorage = TokenStorage();
  final TextEditingController _messageController = TextEditingController();
  List<String> _messages = [];
  
  @override
  void initState() {
    super.initState();
    _getMessages();
  }

  Future<void> _getMessages() async {
    String? token = await _tokenStorage.getToken();
    if (token != null) {
      List<String>? messages = await _apiService.getMessages(token);
      if (messages != null) {
        setState(() {
          _messages = messages;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    String? token = await _tokenStorage.getToken();
    if (token != null && _messageController.text.isNotEmpty) {
      bool success = await _apiService.postMessage(token, _messageController.text);
      if (success) {
        setState(() {
          _messages.add(_messageController.text);
          _messageController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sending failed!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Room 0'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Enter your message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
