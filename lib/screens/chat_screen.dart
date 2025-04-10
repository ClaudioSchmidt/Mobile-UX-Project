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
import '../theme.dart';
import '../widgets/language_badge.dart';
import '../util/chat_name_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String chatName;
  final Function(bool) onLikeChanged;

  const ChatScreen({super.key, required this.chatId, required this.chatName, required this.onLikeChanged});

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
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  Future<void> _deleteChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove chat?'),
        content: const Text(
            'Are you sure you want to remove this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiService.deleteChat(widget.chatId);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat has been deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting chat')),
        );
      }
    }
  }

  Future<void> _reportChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report chat?'),
        content: const Text(
            'Are you sure you want to report this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat has been reported')),
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
    widget.onLikeChanged(isLiked);
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    final chatInfo = ChatNameParser.parse(widget.chatName);
    
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(chatInfo.displayName),
              if (chatInfo.languageCode != null)
                LanguageBadge(
                  languageCode: chatInfo.languageCode!,
                  languageName: chatInfo.languageName!,
                  level: chatInfo.level!,
                ),
            ],
          ),
        ),
        actions: [
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
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : null,
            ),
            onPressed: _toggleLike,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteChat();
              } else if (value == 'report') {
                _reportChat();
              } else if (value == 'viewProfile') {
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'viewProfile',
                child: Text('View Profile'),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text('Report User'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Remove Chat'),
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
                      hintText: 'Write message...',
                      fillColor: Colors.transparent,
                      filled: true,
                    ),
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
        title: const Text('Translation Language'),
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
            child: Text('Cancel', style: TextStyle(color: customColors.primaryText)),
          ),
        ],
      ),
    );
  }
}
