import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/token_storage.dart';

class ChatRoomScreen extends StatefulWidget {
  final int chatId;
  final String chatName;

  const ChatRoomScreen({super.key, required this.chatId, required this.chatName});

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ApiService _apiService = ApiService();
  final TokenStorage _tokenStorage = TokenStorage();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getMessages();
  }

  Future<void> _getMessages() async {
    String? token = await _tokenStorage.getToken();
    if (token != null) {
      List<Map<String, dynamic>>? messages = await _apiService.getMessages(token, chatId: widget.chatId);

      if (messages != null) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _jumpToBottom(); // Direkt zum Ende der Liste springen
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load messages!')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    String? token = await _tokenStorage.getToken();
    if (token != null && _messageController.text.isNotEmpty) {
      bool success = await _apiService.postMessage(
        token,
        _messageController.text,
        chatId: widget.chatId,
      );
      if (success) {
        await _getMessages(); // Hol die Nachrichten erneut vom Server
        _messageController.clear(); // Lösche das Textfeld nach dem Senden
        _jumpToBottom(); // Direkt zum Ende der Liste springen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message!')),
        );
      }
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }


// müll, komplett anderes machen, eig auch für das ganze chatfenster --> eher an whatsapp orientieren!
String _formatTimestamp(String timestamp) {
  try {
    // Replace the first underscore with 'T' and the remaining dashes in the time part with colons
    String formattedTimestamp = timestamp.replaceFirst('_', 'T');
    formattedTimestamp = '${formattedTimestamp.substring(0, 13)}:${formattedTimestamp.substring(14, 16)}:${formattedTimestamp.substring(17)}';

    // Parse the string to a DateTime object
    DateTime parsedTime = DateTime.parse(formattedTimestamp);

    // Format the time as needed (e.g., HH:mm)
    return "${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}";
  } catch (e) {
    print('Error parsing timestamp: $e');
    return 'Invalid date';
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController, // Hier wird der ScrollController zugewiesen
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final user = message['usernick'] ?? 'Unknown';
                      final time = message['time'] ?? '';
                      final formattedTime = _formatTimestamp(time);
                      final text = message['text'] ?? '[No message]';
                      return ListTile(
                        title: Text(text),
                        subtitle: Text("$user · $formattedTime"),
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
