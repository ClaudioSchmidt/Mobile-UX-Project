class ChatInfo {
  final String displayName;
  final String? languageCode;
  final String? languageName;
  final String? level;

  ChatInfo({
    required this.displayName,
    this.languageCode,
    this.languageName,
    this.level,
  });
}

class ChatNameParser {
  static ChatInfo parse(String chatName) {
    // Try to match pattern: "Username - Language (Level)"
    final regex = RegExp(r'^(.+) - (.+) \((.+)\)$');
    final match = regex.firstMatch(chatName);

    if (match != null) {
      final username = match.group(1)?.trim();
      final language = match.group(2)?.trim();
      final level = match.group(3)?.trim();

      if (username != null && language != null && level != null) {
        // Map full language names to codes
        final languageMap = {
          'English': 'EN',
          'Japanese': 'JP',
          'French': 'FR',
          'German': 'DE',
          'Spanish': 'ES',
          'Chinese': 'CN',
          'Italian': 'IT',
          'Korean': 'KR',
          'Russian': 'RU',
          'Portuguese': 'PT',
          'Arabic': 'AR',
          'Hindi': 'HI',
        };

        String? languageCode;
        String? languageName;

        // Try to find the language code
        for (var entry in languageMap.entries) {
          if (language.contains(entry.key)) {
            languageCode = entry.value;
            languageName = language;
            break;
          }
        }

        return ChatInfo(
          displayName: username,
          languageCode: languageCode,
          languageName: languageName,
          level: level,
        );
      }
    }

    // If pattern doesn't match, return original name without language info
    return ChatInfo(displayName: chatName);
  }
}
