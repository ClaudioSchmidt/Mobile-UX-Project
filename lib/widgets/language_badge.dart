import 'package:flutter/material.dart';

class LanguageBadge extends StatelessWidget {
  final String languageCode;
  final String languageName;
  final String level;

  const LanguageBadge({
    super.key,
    required this.languageCode,
    required this.languageName,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$languageName $level',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
