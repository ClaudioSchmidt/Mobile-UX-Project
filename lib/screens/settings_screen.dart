import 'package:flutter/material.dart';
import '../core/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  // Mock settings values
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedTheme = 'system';
  String _appLanguage = 'English';
  String _defaultTranslationLanguage = 'English';
  bool _autoTranslate = false;
  int _fontSize = 16;
  bool _autoCorrect = true;

  Future<void> _logout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout bestätigen'),
          content: const Text('Möchtest du dich wirklich ausloggen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      bool success = await _apiService.logout();
      if (success) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout fehlgeschlagen')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive chat and system notifications'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Sound'),
            value: _soundEnabled,
            onChanged: (value) => setState(() => _soundEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            value: _vibrationEnabled,
            onChanged: (value) => setState(() => _vibrationEnabled = value),
          ),

          const _SectionHeader(title: 'Chat Preferences'),
          ListTile(
            title: const Text('Default Translation Language'),
            subtitle: Text(_defaultTranslationLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {/* Show language picker */},
          ),
          SwitchListTile(
            title: const Text('Auto-Translate Messages'),
            subtitle: const Text('Automatically translate incoming messages'),
            value: _autoTranslate,
            onChanged: (value) => setState(() => _autoTranslate = value),
          ),
          ListTile(
            title: const Text('Font Size'),
            subtitle: Text('${_fontSize}px'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(() => _fontSize = (_fontSize - 1).clamp(12, 24)),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _fontSize = (_fontSize + 1).clamp(12, 24)),
                ),
              ],
            ),
          ),

          const _SectionHeader(title: 'App Preferences'),
          ListTile(
            title: const Text('App Language'),
            subtitle: Text(_appLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {/* Show language picker */},
          ),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_selectedTheme),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {/* Show theme picker */},
          ),
          SwitchListTile(
            title: const Text('Auto-Correct'),
            subtitle: const Text('Automatically correct spelling mistakes'),
            value: _autoCorrect,
            onChanged: (value) => setState(() => _autoCorrect = value),
          ),

          const _SectionHeader(title: 'Account'),
          ListTile(
            title: const Text('Delete Account'),
            textColor: Colors.red,
            onTap: () {/* Show delete confirmation */},
          ),
          ListTile(
            title: const Text('Logout'),
            textColor: Colors.red,
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
