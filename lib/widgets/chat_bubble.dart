import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/translation_service.dart';
import '../theme.dart';

class ChatBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final String? userHash;

  const ChatBubble({
    super.key, 
    required this.message, 
    required this.userHash,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  final TranslationService _translationService = TranslationService();
  String? _translatedText;
  bool _isTranslating = false;
  String? _lastUsedLanguage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed && _translatedText != null) {
        _pulseController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Retranslate if translation is active and language changed
    if (_translatedText != null && 
        _lastUsedLanguage != TranslationService.currentLanguage) {
      _translateMessage();
    }
  }

  Future<void> _translateMessage() async {
    if (_translatedText != null) {
      setState(() => _translatedText = null);
      _pulseController.stop();
      return;
    }

    setState(() => _isTranslating = true);
    final translation = await _translationService.translateText(
      widget.message['text']
    );
    setState(() {
      _translatedText = translation;
      _isTranslating = false;
      _lastUsedLanguage = TranslationService.currentLanguage;
    });
    _pulseController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.8;
    const maxImageHeight = 300.0;  // Maximum height for images
    final maxImageWidth = maxBubbleWidth - 24.0;  // Accounting for padding

    final isSentByMe = widget.message['userhash'] == widget.userHash;
    final alignment = isSentByMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isSentByMe ? Theme.of(context).chipTheme.selectedColor : Theme.of(context).chipTheme.backgroundColor;
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

    final timeWidget = Text(
      _formatTime(widget.message['time']),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 11,
        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
      ),
    );

    return Row(
      mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isSentByMe && widget.message['text'] != null) _buildTranslateButton(),
        Flexible(
          child: Align(
            alignment: alignment,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxBubbleWidth,
              ),
              child: IntrinsicWidth(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: borderRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isSentByMe) ...[
                        Text(
                          widget.message['usernick'] ?? 'Unbekannt',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (widget.message['photoData'] != null) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _showImageDialog(context, widget.message['photoData']),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: maxImageWidth,
                                    maxHeight: maxImageHeight,
                                  ),
                                  child: Image.memory(
                                    widget.message['photoData'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.message['text'] == null) 
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [timeWidget],
                                ),
                              ),
                          ],
                        ),
                        if (widget.message['text'] != null) const SizedBox(height: 8),
                      ],
                      if (widget.message['text'] != null) ...[
                        if (_translatedText != null) ...[
                          _buildTextContent(context, widget.message['text']),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: _buildTextContent(context, _translatedText!, isTranslation: true),
                              ),
                              const SizedBox(width: 8),
                              timeWidget,
                            ],
                          ),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: _buildTextContent(context, widget.message['text']),
                              ),
                              const SizedBox(width: 8),
                              timeWidget,
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!isSentByMe && widget.message['text'] != null) _buildTranslateButton(),
      ],
    );
  }

  Widget _buildTranslateButton() {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: _isTranslating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            )
          : AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _translatedText != null ? _pulseAnimation.value : 1.0,
                  child: InkWell(
                    onTap: _translateMessage,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _translatedText != null 
                            ? customColors.translationBackground
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _translatedText != null 
                            ? Icons.translate 
                            : Icons.translate_outlined,
                        size: 16,
                        color: _translatedText != null 
                            ? customColors.translationIconActive
                            : customColors.translationIconInactive,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTextContent(BuildContext context, String text, {bool isTranslation = false}) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontStyle: isTranslation ? FontStyle.italic : FontStyle.normal,
        color: isTranslation 
            ? Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8)
            : Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  void _showImageDialog(BuildContext context, Uint8List imageData) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Image.memory(imageData),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
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
}
