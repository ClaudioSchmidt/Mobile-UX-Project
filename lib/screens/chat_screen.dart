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
  List<dynamic> messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages(); // Lade die Nachrichten, wenn der Bildschirm angezeigt wird
  }

  Future<void> _loadMessages() async {
    final fetchedMessages = await _apiService.getMessages(widget.chatId);
    if (fetchedMessages != null) {
      setState(() {
        messages = fetchedMessages;
      });
    }
  }

 Future<void> _sendMessage() async {
  final messageText = _messageController.text.trim();
  if (messageText.isEmpty) return;

  // Nachricht sofort zur Liste hinzufügen
  setState(() {
    messages.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch, // Temporäre ID
      'userid': 'current_user_id', // Ersetze 'current_user_id' durch die tatsächliche Benutzer-ID, falls verfügbar
      'time': DateTime.now().toString(),
      'chatid': widget.chatId,
      'text': messageText,
      'usernick': 'Ich', // Zeigt "Ich" für den Absender an
      'userhash': '', // Falls ein userhash benötigt wird
    });
  });

  bool success = await _apiService.sendMessage(widget.chatId, messageText);
  if (success) {
    _messageController.clear();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nachricht konnte nicht gesendet werden')));
    // Entferne die Nachricht wieder, wenn das Senden fehlschlägt
    setState(() {
      messages.removeAt(0);
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chatName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Neueste Nachricht unten
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ListTile(
                       title: Text(message['usernick'] ?? 'Unbekannt'),
      subtitle: Text(message['text'] ?? '[Kein Inhalt]'),
      trailing: Text(message['time'] ?? ''),
                );
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
