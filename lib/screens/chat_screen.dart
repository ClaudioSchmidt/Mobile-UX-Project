import 'package:flutter/material.dart';
import '../core/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String chatName;

  ChatScreen({required this.chatId, required this.chatName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final fetchedMessages = await _apiService.getMessages(widget.chatId);
    if (fetchedMessages != null) {
      setState(() {
        messages = fetchedMessages;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    bool success = await _apiService.sendMessage(widget.chatId, messageText);
    if (success) {
      _messageController.clear();
      await _loadMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nachricht konnte nicht gesendet werden')));
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo (
        _scrollController.position.maxScrollExtent,
      );
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['usernick'] ?? 'Unbekannt',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            SizedBox(height: 4),
            Text(
              message['text'] ?? '[Kein Inhalt]',
              style: TextStyle(color: Colors.black87),
            ),
            SizedBox(height: 4),
            Text(
              message['time'] ?? '',
              style: TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chatName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nachricht schreiben...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
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
