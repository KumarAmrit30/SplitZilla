import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'category_management_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SharedPreferences _prefs;
  bool _isDarkMode = true;
  String _currency = '₹';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = _prefs.getBool('isDarkMode') ?? true;
      _currency = _prefs.getString('currency') ?? '₹';
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool('isDarkMode', _isDarkMode);
    await _prefs.setString('currency', _currency);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                  _saveSettings();
                });
              },
            ),
          ),
          ListTile(
            title: const Text('Currency'),
            subtitle: Text('Current currency: $_currency'),
            trailing: DropdownButton<String>(
              value: _currency,
              items: const [
                DropdownMenuItem(value: '₹', child: Text('₹ (INR)')),
                DropdownMenuItem(value: '\$', child: Text('\$ (USD)')),
                DropdownMenuItem(value: '€', child: Text('€ (EUR)')),
                DropdownMenuItem(value: '£', child: Text('£ (GBP)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currency = value;
                    _saveSettings();
                  });
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Category Management'),
            subtitle: const Text('Manage expense categories'),
            trailing: const Icon(Icons.category),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryManagementPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Export Data'),
            subtitle: const Text('Export your data as CSV'),
            trailing: const Icon(Icons.download),
            onTap: () {
              // TODO(goconqueror): Implement data export
            },
          ),
          ListTile(
            title: const Text('Import Data'),
            subtitle: const Text('Import data from CSV'),
            trailing: const Icon(Icons.upload),
            onTap: () {
              // TODO(goconqueror): Implement data import
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.info),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SplitZilla',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 48),
                children: const [
                  Text(
                    'SplitZilla is a feature-rich expense tracker app that helps you manage your personal and group expenses.',
                  ),
                  SizedBox(height: 16),
                  Text('Created with ❤️ using Flutter'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
