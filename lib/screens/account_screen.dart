import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/api_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  List<LanguageSelection> selectedLanguages = [];
  Map<String, bool> showError = {};
  String? userHash;
  String? userNick;
  String? email;
  String bio = 'I love to learn new languages!';
  final ScrollController _scrollController = ScrollController();

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
    _loadLanguages();
    _loadUserDetails();
  }

  Future<void> _loadLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    final languages = prefs.getString('accountLanguages');
    if (languages != null) {
      setState(() {
        selectedLanguages = (jsonDecode(languages) as List)
            .map((e) => LanguageSelection.fromJson(e))
            .toList();
        for (var lang in selectedLanguages) {
          showError[lang.language] = lang.proficiencies.isEmpty;
        }
      });
    }
  }

  Future<void> _loadUserDetails() async {
    final apiService = ApiService();
    final hash = await apiService.getUserHash();
    final profiles = await apiService.getProfiles();
    setState(() {
      userHash = hash;
      final userProfile = profiles?.firstWhere((profile) => profile['hash'] == hash, orElse: () => null);
      userNick = userProfile?['nickname'] ?? 'Unknown';
      email = hash?.contains('@') == true ? hash : '$userNick@hs-esslingen.de';
      bio = userProfile?['bio'] ?? bio;
    });
  }

  Future<void> _saveLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'accountLanguages',
        jsonEncode(selectedLanguages.map((e) => e.toJson()).toList()));
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _addLanguage() async {
    final availableLanguages = languageOptions
        .where((option) => !selectedLanguages
            .any((selected) => selected.language == option.name))
        .toList();

    if (availableLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more languages available.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AddLanguageDialog(
        languageOptions: availableLanguages,
        onLanguageSelected: (languageOption) {
          setState(() {
            selectedLanguages.add(LanguageSelection(languageOption.name));
            showError[languageOption.name] = true;
          });
          _saveLanguages();
        },
      ),
    );
  }

  void _removeLanguage(String language) {
    setState(() {
      selectedLanguages.removeWhere((lang) => lang.language == language);
      showError.remove(language);
    });
    _saveLanguages();
  }

  void _toggleProficiency(String language, String proficiency) {
    setState(() {
      final selectedLanguage = selectedLanguages
          .firstWhere((lang) => lang.language == language);
      selectedLanguage.proficiencies.clear();
      selectedLanguage.proficiencies.add(proficiency);
      showError[language] = false;
    });
    _saveLanguages();
  }

  void _editUserNick() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit User Nickname button pressed!')),
    );
  }

  Future<void> _editBio() async {
    final TextEditingController bioController = TextEditingController(text: bio);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Bio'),
          content: TextField(
            controller: bioController,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        bio = bioController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        automaticallyImplyLeading: selectedLanguages.any((lang) => showError[lang.language] == true) ? false : true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit Picture button pressed!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text('Edit Picture'),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            userNick ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: _editUserNick,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email ?? 'Loading...',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '42 likes',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bio Section
            const Text(
              'About Me',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _editBio,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        bio,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: _editBio,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Languages Section
            const Text(
              'My Languages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedLanguages.length + 1,
              itemBuilder: (context, index) {
                if (index == selectedLanguages.length) {
                  return GestureDetector(
                    onTap: _addLanguage,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(
                          color: Theme.of(context).textTheme.titleMedium?.color ?? Colors.grey,
                        ),
                      ),
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: SizedBox(
                        height: 50,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: Theme.of(context).textTheme.titleMedium?.color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add Language',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.titleMedium?.color,
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
                    (option) => option.name == selectedLanguage.language);

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
                                label: Text(
                                  proficiency,
                                  style: TextStyle(
                                    color: isSelected 
                                        ? Colors.white 
                                        : Theme.of(context).textTheme.titleMedium?.color,
                                  ),
                                ),
                                backgroundColor: isSelected
                                    ? Colors.green
                                    : Theme.of(context).brightness == Brightness.light
                                        ? Colors.grey[300]
                                        : Colors.transparent,
                                shape: !isSelected && Theme.of(context).brightness == Brightness.dark
                                    ? StadiumBorder(
                                        side: BorderSide(
                                          color: Theme.of(context).textTheme.titleMedium?.color ?? Colors.white,
                                        ),
                                      )
                                    : const StadiumBorder(),
                              ),
                            );
                          }).toList(),
                        ),
                        if (showError[selectedLanguage.language] == true)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Please choose a proficiency',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
      title: const Text('Add Language'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search Language',
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
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
