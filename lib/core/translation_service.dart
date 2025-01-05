import 'package:translator/translator.dart';

class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();
  static String currentLanguage = 'en';

  static final Map<String, String> supportedLanguages = {
    'en': 'English',
    'ja': '日本語 (Japanese)',
    'fr': 'Français (French)',
    'de': 'Deutsch (German)',
    'es': 'Español (Spanish)',
    'zh': '中文 (Mandarin Chinese)',
    'it': 'Italiano (Italian)',
    'ko': '한국어 (Korean)',
    'ru': 'Русский (Russian)',
    'pt': 'Português (Portuguese)',
    'ar': 'العربية (Arabic)',
    'hi': 'हिन्दी (Hindi)',
  };

  static String getLanguageCode(String language) {
    return supportedLanguages.entries
        .firstWhere((entry) => entry.value == language)
        .key
        .toUpperCase();
  }
  
  Future<String> translateText(String text, [String? targetLanguage]) async {
    try {
      final translation = await _translator.translate(
        text, 
        to: targetLanguage ?? currentLanguage
      );
      return translation.text;
    } catch (e) {
      return '[Übersetzung fehlgeschlagen]';
    }
  }
}
