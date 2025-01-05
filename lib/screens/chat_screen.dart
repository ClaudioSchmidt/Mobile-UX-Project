import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import '../core/api_service.dart';
import '../widgets/chat_bubble.dart';
import '../core/translation_service.dart';
import 'package:intl/intl.dart';
import '../widgets/date_separator.dart';
import '../theme.dart';  // Add this import
import '../widgets/language_badge.dart';
import '../util/chat_name_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String chatName;
  final Function(bool) onLikeChanged; // Add this parameter

  const ChatScreen({super.key, required this.chatId, required this.chatName, required this.onLikeChanged}); // Update constructor

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
  Timer? _timer;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadUserHash();
    _startAutoRefresh();
    _loadLikedStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadMessages();
    });
  }

  Future<void> _loadUserHash() async {
    _userHash = await _apiService.getUserHash();
  }

  Future<void> _loadMessages() async {
    final fetchedMessages = await _apiService.getMessages(widget.chatId);
    if (fetchedMessages != null) {
      setState(() {
        messages = fetchedMessages;
      });
      // Delay the scroll to ensure the layout is complete
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 1),
        curve: Curves.easeOut,
      );
    }
  }

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

  void _removeSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

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
      // Add extra scroll after new message
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nachricht konnte nicht gesendet werden')),
      );
    }
  }

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
        Navigator.pop(context, true);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat wurde gemeldet')),
      );
    }
  }

  String _formatDate(String timestamp) {
    final dateTime = DateFormat('yyyy-MM-dd_HH-mm-ss').parse(timestamp);
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    if (dateTime.year == now.year && 
        dateTime.month == now.month && 
        dateTime.day == now.day) {
      return 'Heute';
    } else if (dateTime.year == yesterday.year && 
               dateTime.month == yesterday.month && 
               dateTime.day == yesterday.day) {
      return 'Gestern';
    }
    return DateFormat('dd.MM.yyyy').format(dateTime);
  }

  String? _getMessageDate(int index) {
    if (index >= messages.length) return null;
    final currentDate = DateFormat('yyyy-MM-dd_HH-mm-ss')
        .parse(messages[index]['time'])
        .toLocal();
    
    if (index == 0) return _formatDate(messages[index]['time']);

    final previousDate = DateFormat('yyyy-MM-dd_HH-mm-ss')
        .parse(messages[index - 1]['time'])
        .toLocal();

    if (currentDate.year != previousDate.year || 
        currentDate.month != previousDate.month || 
        currentDate.day != previousDate.day) {
      return _formatDate(messages[index]['time']);
    }
    return null;
  }

  void _showImageDialog(BuildContext context, Uint8List imageData) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: customColors.imageDialogBackground,
          child: Stack(
            children: [
              Image.memory(imageData),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: customColors.closeButtonBackground,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: customColors.primaryText),
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

  Future<void> _loadLikedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final likedChatIds = prefs.getStringList('likedChats') ?? [];
    setState(() {
      isLiked = likedChatIds.contains(widget.chatId.toString());
    });
  }

  Future<void> _toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLiked = !isLiked;
      final likedChatIds = prefs.getStringList('likedChats') ?? [];
      if (isLiked) {
        likedChatIds.add(widget.chatId.toString());
      } else {
        likedChatIds.remove(widget.chatId.toString());
      }
      prefs.setStringList('likedChats', likedChatIds);
    });
    widget.onLikeChanged(isLiked); // Notify the main screen about the change
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    final chatInfo = ChatNameParser.parse(widget.chatName);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
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
        actions: [
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : null,
            ),
            onPressed: _toggleLike,
          ),
          TextButton.icon(
            icon: const Icon(Icons.translate),
            label: Text(
              TranslationService.currentLanguage.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => _showLanguageSelector(),
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
                final dateSeparator = _getMessageDate(index);
                return Column(
                  children: [
                    if (dateSeparator != null)
                      DateSeparator(date: dateSeparator),
                    ChatBubble(
                      message: message,
                      userHash: _userHash,
                    ),
                  ],
                );
              },
            ),
          ),
          if (_selectedImageBytes != null)
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
                        color: customColors.closeButtonBackground,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: customColors.primaryText),
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
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Nachricht schreiben...',
                      fillColor: Colors.transparent,
                      filled: true,
                    ),
                    // Add these properties:
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
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

  void _showLanguageSelector() {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Übersetzungssprache'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: TranslationService.supportedLanguages.entries.map((entry) {
              return ListTile(
                title: Text(entry.value),
                trailing: entry.key == TranslationService.currentLanguage
                    ? Icon(Icons.check, color: customColors.success)
                    : null,
                onTap: () {
                  setState(() {
                    TranslationService.currentLanguage = entry.key;
                    // Trigger rebuild of all chat bubbles
                    messages = List.from(messages);
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen', style: TextStyle(color: customColors.primaryText)),
          ),
        ],
      ),
    );
  }
}
