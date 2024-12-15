import 'dart:typed_data'; // Für Uint8List
import 'dart:convert'; // Für Base64-Kodierung
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Für Bildauswahl
import '../core/api_service.dart'; // Dein API-Service

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
  Uint8List? _selectedImageBytes; // Speichert die Bilddaten

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  // Bildauswahl-Logik
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes(); // Lese Bilddaten als Uint8List
      setState(() {
        _selectedImageBytes = bytes; // Speichere Byte-Daten
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
      base64Image = base64Encode(_selectedImageBytes!); // Bilddaten in Base64 umwandeln
    }

    bool success = await _apiService.sendMessage(
      chatId: widget.chatId,
      text: messageText.isNotEmpty ? messageText : null,
      base64Image: base64Image,
    );

    if (success) {
      _messageController.clear();
      setState(() {
        _selectedImageBytes = null; // Bildauswahl zurücksetzen
      });
      await _loadMessages(); // Nachrichtenliste neu laden
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nachricht konnte nicht gesendet werden')),
      );
    }
  }

  // Automatisches Scrollen zum Ende
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
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
                  message['photoData'], // Byte-Daten rendern
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
