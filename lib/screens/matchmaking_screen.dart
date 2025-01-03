import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/api_service.dart'; // Add this import
import 'dart:math'; // Add this import
import 'chat_screen.dart'; // Add this import

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  _MatchmakingScreenState createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  final ApiService _apiService = ApiService(); // Add this line
  List<dynamic> users = []; // Add this line
  List<LanguageSelection> selectedLanguages = [];
  List<dynamic> chats = []; // Add this line
  bool isAutoMatchmakingEnabled = false;

  final List<LanguageOption> languageOptions = [
    LanguageOption('English', ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']),
    LanguageOption('日本語 (Japanese)', ['N5', 'N4', 'N3', 'N2', 'N1']),
    LanguageOption('Français (French)', ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']),
    LanguageOption('Deutsch (German)', ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']),
    LanguageOption('Español (Spanish)', ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']),
    LanguageOption('中文 (Mandarin Chinese)', ['HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6']),
    LanguageOption('Italiano (Italian)', ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']),
    LanguageOption('한국어 (Korean)', ['TOPIK I', 'TOPIK II', 'TOPIK III', 'TOPIK IV', 'TOPIK V', 'TOPIK VI']),
    LanguageOption('Русский (Russian)', ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']),
    LanguageOption('Português (Portuguese)', ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']),
    LanguageOption('العربية (Arabic)', ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']),
    LanguageOption('हिन्दी (Hindi)', ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final languages = prefs.getString('selectedLanguages');
    final autoMatchmaking = prefs.getBool('isAutoMatchmakingEnabled') ?? false;

    setState(() {
      if (languages != null) {
        selectedLanguages = (jsonDecode(languages) as List)
            .map((e) => LanguageSelection.fromJson(e))
            .toList();
      }
      isAutoMatchmakingEnabled = autoMatchmaking;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'selectedLanguages',
        jsonEncode(selectedLanguages.map((e) => e.toJson()).toList()));
    await prefs.setBool('isAutoMatchmakingEnabled', isAutoMatchmakingEnabled);
  }

  void _addLanguage() async {
    final availableLanguages = languageOptions
        .where((option) => !selectedLanguages
            .any((selected) => selected.language == option.name))
        .toList();

    if (availableLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine weiteren Sprachen verfügbar.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AddLanguageDialog(
          languageOptions: availableLanguages,
          onLanguageSelected: (languageOption) {
            setState(() {
              selectedLanguages.add(LanguageSelection(languageOption.name));
            });
            _savePreferences();
          },
        );
      },
    );
  }

  void _toggleProficiency(String language, String proficiency) {
    setState(() {
      final selectedLanguage = selectedLanguages
          .firstWhere((lang) => lang.language == language, orElse: () {
        final newLanguage = LanguageSelection(language);
        selectedLanguages.add(newLanguage);
        return newLanguage;
      });

      if (selectedLanguage.proficiencies.contains(proficiency)) {
        selectedLanguage.proficiencies.remove(proficiency);
      } else {
        selectedLanguage.proficiencies.add(proficiency);
      }
    });
    _savePreferences();
  }

  void _removeLanguage(String language) {
    setState(() {
      selectedLanguages.removeWhere((lang) => lang.language == language);
    });
    _savePreferences();
  }

  Future<void> _startMatchmaking() async {
    if (!isAutoMatchmakingEnabled) {
      final fetchedUsers = await _apiService.getProfiles();
      if (fetchedUsers != null) {
        setState(() {
          users = _mockUserProfiles(fetchedUsers);
        });
        _showUserSelectionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Laden der Benutzer')),
        );
      }
    } else {
      if (users.isEmpty) {
        final fetchedUsers = await _apiService.getProfiles();
        if (fetchedUsers != null) {
          setState(() {
            users = _mockUserProfiles(fetchedUsers);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fehler beim Laden der Benutzer')),
          );
          return;
        }
      }
      _showLoadingScreen();
      await Future.delayed(const Duration(seconds: 3)); // Mock loading time
      final random = Random();
      final randomUser = users[random.nextInt(users.length)];
      final chatName = '${randomUser['nickname']} - ${randomUser['language']} (${randomUser['proficiency']})';
      final success = await _apiService.createChat(chatName);
      if (success) {
        final fetchedChats = await _apiService.getChats();
        if (fetchedChats != null) {
          setState(() {
            chats = fetchedChats;
          });
          final newChat = fetchedChats.firstWhere((chat) => chat['chatname'] == chatName);
          Navigator.pop(context); // Close loading screen
          Navigator.pop(context); // Close matchmaking screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: newChat['chatid'],
                chatName: chatName,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Erstellen des Chats')),
        );
      }
    }
  }

  void _showLoadingScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue), // Match the color here
              SizedBox(height: 20),
              Text(
                'Suche nach einem Match...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue), // Match the color here
              ),
            ],
          ),
        );
      },
    );
  }

  List<dynamic> _mockUserProfiles(List<dynamic> fetchedUsers) {
    final random = Random();
    return fetchedUsers.map((user) {
      final randomLanguage = selectedLanguages[random.nextInt(selectedLanguages.length)];
      final randomProficiency = randomLanguage.proficiencies[random.nextInt(randomLanguage.proficiencies.length)];
      return {
        ...user,
        'language': randomLanguage.language,
        'proficiency': randomProficiency,
      };
    }).toList();
  }

  void _showUserSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Benutzer auswählen'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user['nickname'] ?? 'Benutzer ${index + 1}'),
                  subtitle: Text('Sprache: ${user['language']}\nNiveau: ${user['proficiency']}'),
                  onTap: () async {
                    final chatName = '${user['nickname']} - ${user['language']} (${user['proficiency']})';
                    final success = await _apiService.createChat(chatName);
                    if (success) {
                      final fetchedChats = await _apiService.getChats();
                      if (fetchedChats != null) {
                        setState(() {
                          chats = fetchedChats;
                        });
                        final newChat = fetchedChats.firstWhere((chat) => chat['chatname'] == chatName);
                        Navigator.pop(context);
                        Navigator.pop(context); // Close matchmaking screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: newChat['chatid'],
                              chatName: chatName,
                            ),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fehler beim Erstellen des Chats')),
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
          ],
        );
      },
    );
  }

  bool get _isMatchmakingButtonEnabled {
    if (selectedLanguages.isEmpty) return false;
    for (var language in selectedLanguages) {
      if (language.proficiencies.isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matchmaking Einstellungen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Automatisches Matchmaking',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Switch(
                  value: isAutoMatchmakingEnabled,
                  onChanged: (value) {
                    setState(() {
                      isAutoMatchmakingEnabled = value;
                    });
                    _savePreferences();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Gewählte Sprachen:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: selectedLanguages.length + 1,
                itemBuilder: (context, index) {
                  if (index == selectedLanguages.length) {
                    return selectedLanguages.length >= 3
                        ? Card(
                            color: Colors.grey[300],
                            child: SizedBox(
                              height: 50,
                              child: Center(
                                child: Text(
                                  'Maximal 3 Sprachen',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: _addLanguage,
                            child: Card(
                              color: Colors.grey[200],
                              child: const SizedBox(
                                height: 50,
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text(
                                        'Sprache hinzufügen',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                  }

                  final selectedLanguage = selectedLanguages[index];
                  final languageOption = languageOptions.firstWhere(
                      (option) => option.name == selectedLanguage.language,
                      orElse: () => LanguageOption(selectedLanguage.language, []));

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedLanguage.language,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () =>
                                    _removeLanguage(selectedLanguage.language),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            children: languageOption.proficiencies.map((proficiency) {
                              final isSelected = selectedLanguage.proficiencies
                                  .contains(proficiency);
                              return GestureDetector(
                                onTap: () {
                                  _toggleProficiency(
                                      selectedLanguage.language, proficiency);
                                },
                                child: Chip(
                                  label: Text(proficiency),
                                  backgroundColor: isSelected
                                      ? Colors.green
                                      : Colors.grey[300],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isMatchmakingButtonEnabled ? _startMatchmaking : null,
        label: const Text('Start Matchmaking'),
        icon: const Icon(Icons.people),
        backgroundColor: _isMatchmakingButtonEnabled ? null : Colors.grey,
      ),
    );
  }
}

class LanguageOption {
  final String name;
  final List<String> proficiencies;

  LanguageOption(this.name, this.proficiencies);
}

class LanguageSelection {
  final String language;
  final List<String> proficiencies;

  LanguageSelection(this.language, [List<String>? proficiencies])
      : proficiencies = proficiencies ?? [];

  factory LanguageSelection.fromJson(Map<String, dynamic> json) {
    return LanguageSelection(
      json['language'],
      List<String>.from(json['proficiencies']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'proficiencies': proficiencies,
    };
  }
}

class AddLanguageDialog extends StatefulWidget {
  final List<LanguageOption> languageOptions;
  final Function(LanguageOption) onLanguageSelected;

  const AddLanguageDialog({
    super.key,
    required this.languageOptions,
    required this.onLanguageSelected,
  });

  @override
  _AddLanguageDialogState createState() => _AddLanguageDialogState();
}

class _AddLanguageDialogState extends State<AddLanguageDialog> {
  late List<LanguageOption> filteredOptions;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredOptions = List.from(widget.languageOptions);
    searchController.addListener(() {
      setState(() {
        final query = searchController.text.toLowerCase();
        filteredOptions = widget.languageOptions
            .where((option) => option.name.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sprache hinzufügen'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Suche nach Sprache',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredOptions.length,
                itemBuilder: (context, index) {
                  final languageOption = filteredOptions[index];
                  return ListTile(
                    title: Text(languageOption.name),
                    onTap: () {
                      widget.onLanguageSelected(languageOption);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
      ],
    );
  }
}
