import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String chatName;

  const ChatScreen({super.key, required this.chatId, required this.chatName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> messages = [];
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  // Nachrichten laden
  Future<void> _loadMessages() async {
    final fetchedMessages = await _apiService.getMessages(widget.chatId);
    if (fetchedMessages != null) {
      setState(() {
        messages = fetchedMessages;
      });

      // Direkt zum unteren Ende springen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(initial: true);
      });
    }
  }

  // Scrollen zum unteren Ende
  void _scrollToBottom({bool initial = false}) {
    if (_scrollController.hasClients) {
      if (initial) {
        // Beim ersten Laden direkt springen
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        // Bei neuen Nachrichten sanft scrollen
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  // Bildauswahl-Logik
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bild ausgewählt: ${image.name}')),
      );
    }
  }

  // Nachricht senden (Text und/oder Bild)
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty && _selectedImageBytes == null) return;

    String? base64Image;
    if (_selectedImageBytes != null) {
      base64Image = base64Encode(_selectedImageBytes!);
    }

    bool success = await _apiService.sendMessage(
      chatId: widget.chatId,
      text: messageText.isNotEmpty ? messageText : null,
      base64Image: base64Image,
    );

    if (success) {
      _messageController.clear();
      setState(() {
        _selectedImageBytes = null;
      });
      await _loadMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nachricht konnte nicht gesendet werden')),
      );
    }
  }

// Chat löschen
Future<void> _deleteChat() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Chat löschen'),
      content: const Text(
          'Bist du sicher, dass du diesen Chat löschen möchtest? Diese Aktion kann nicht rückgängig gemacht werden.'),
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
    ),
  );

  if (confirmed == true) {
    final success = await _apiService.deleteChat(widget.chatId);
    if (success) {
      // Chat-Liste im MainScreen aktualisieren
      Navigator.pop(context, true); // True signalisiert erfolgreichen Abschluss
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat erfolgreich gelöscht')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Löschen des Chats')),
      );
    }
  }
}

  // Nachricht anzeigen
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['usernick'] ?? 'Unbekannt',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            if (message['text'] != null)
              Text(
                message['text'] ?? '[Kein Inhalt]',
                style: const TextStyle(color: Colors.black87),
              ),
            if (message['photoData'] != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  message['photoData'],
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              message['time'] ?? '',
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteChat();
              } else if (value == 'viewProfile') {
                // Profile ansehen logic here
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'viewProfile',
                child: Text('Profil ansehen'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Chat löschen'),
              ),
            ],
          ),
        ],
      ),
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
          if (_selectedImageBytes != null) // Vorschau des ausgewählten Bilds
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _selectedImageBytes!,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _pickImage, // Bildauswahl starten
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Nachricht schreiben...',
                    ),
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
