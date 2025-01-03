import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Add this import
import 'dart:async'; // Add this import
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
import '../core/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String chatName;
  final bool isFavorite; // Add this line

  const ChatScreen({super.key, required this.chatId, required this.chatName, this.isFavorite = false}); // Update this line

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> messages = [];
  Uint8List? _selectedImageBytes;
  String? _userHash;
  Timer? _timer; // Add this line
  bool _isFavorite = false; // Add this line

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite; // Add this line
    _loadMessages();
    _loadUserHash();
    _startAutoRefresh(); // Add this line
  }

  @override
  void dispose() {
    _timer?.cancel(); // Add this line
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadMessages();
    });
  }

  Future<void> _loadUserHash() async {
    _userHash = await _apiService.getUserHash();
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

  // Bild entfernen
  void _removeSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
    });
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
      title: const Text('Chat auflösen?'),
      content: const Text(
          'Bist du sicher, dass du diesen Chat auflösen möchtest? Diese Aktion kann nicht rückgängig gemacht werden.'),
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

// Chat melden
Future<void> _reportChat() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Chat melden'),
      content: const Text(
          'Bist du sicher, dass du diesen Chat melden möchtest? Diese Aktion kann nicht rückgängig gemacht werden.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Melden', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    // Implement the report functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat wurde gemeldet')),
    );
  }
}

  Future<void> _saveFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteChatsString = prefs.getString('favoriteChats') ?? '{}';
    final favoriteChats = Map<String, dynamic>.from(jsonDecode(favoriteChatsString));
    favoriteChats[widget.chatId.toString()] = _isFavorite;
    await prefs.setString('favoriteChats', jsonEncode(favoriteChats));
  }

  // Nachricht anzeigen
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isSentByMe = message['userhash'] == _userHash;
    final alignment = isSentByMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isSentByMe ? Colors.green[300] : Colors.grey[300];
    final borderRadius = isSentByMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          );

    return Align(
      alignment: alignment,
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSentByMe)
                Text(
                  message['usernick'] ?? 'Unbekannt',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              if (!isSentByMe) const SizedBox(height: 4),
              if (message['text'] != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5.0), // Adjust this value for padding
                        child: Text(
                          message['text'] ?? '[Kein Inhalt]',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(message['time']),
                      style: const TextStyle(fontSize: 10, color: Colors.black45),
                    ),
                  ],
                ),
              if (message['photoData'] != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showImageDialog(message['photoData']),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      message['photoData'],
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatTime(message['time']),
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showImageDialog(Uint8List imageData) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Make the dialog background transparent
          child: Stack(
            children: [
              Image.memory(imageData),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7), // Dark gray background
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateFormat('yyyy-MM-dd_HH-mm-ss').parse(timestamp);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  String _formatDateLabel(String date) {
    final now = DateTime.now();
    final messageDate = DateFormat('yyyy-MM-dd').parse(date);
    if (now.year == messageDate.year && now.month == messageDate.month && now.day == messageDate.day) {
      return 'Heute';
    }
    return DateFormat('dd. MMMM yyyy').format(messageDate);
  }

  Widget _buildDateLabel(String date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatDateLabel(date),
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? lastDate;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : null),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              _saveFavoriteStatus(); // Save the favorite status
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteChat();
              } else if (value == 'report') {
                _reportChat();
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
                value: 'report',
                child: Text('Profil melden'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Chat auflösen'),
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
                final messageDate = DateFormat('yyyy-MM-dd').format(DateFormat('yyyy-MM-dd_HH-mm-ss').parse(message['time']));
                final showDateLabel = lastDate != messageDate;
                lastDate = messageDate;

                return Column(
                  children: [
                    if (showDateLabel) _buildDateLabel(messageDate),
                    _buildMessageBubble(message),
                  ],
                );
              },
            ),
          ),
          if (_selectedImageBytes != null) // Vorschau des ausgewählten Bilds
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7), // Dark gray background
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _removeSelectedImage,
                      ),
                    ),
                  ),
                ],
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
                      fillColor: Colors.transparent, // Make the input background transparent
                      filled: true,
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
