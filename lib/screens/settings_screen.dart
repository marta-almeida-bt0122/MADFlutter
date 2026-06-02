// lib/screens/settings_screen.dart
// ─── W13: SharedPreferences + Logout Firebase ─────────────────
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final Logger _logger = Logger();
  Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;

  static const Map<String, String> _defaultPrefs = {
    'user_name'  : 'Usuario',
    'user_email' : '',
    'server_url' : 'https://mi-servidor.com',
  };

  @override
  void initState() {
    super.initState();
    _loadAllPreferences();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _defaultPrefs.entries) {
      if (!prefs.containsKey(entry.key)) {
        await prefs.setString(entry.key, entry.value);
      }
    }
    final keys = prefs.getKeys();
    final Map<String, TextEditingController> controllers = {};
    for (final key in keys) {
      controllers[key] =
          TextEditingController(text: prefs.get(key)?.toString() ?? '');
    }
    if (mounted) {
      setState(() {
        _controllers = controllers;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Guardado: $key'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2)),
      );
    }
  }

  // ── Logout ────────────────────────────────────────────────

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _signOut();
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    _logger.d('Usuario desconectado');
    // app.dart StreamBuilder redirige automáticamente a LoginScreen
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // ── Cuenta Firebase ──────────────────────
                Card(
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(Icons.account_circle,
                        color: Colors.indigo, size: 36),
                    title: Text(
                      _controllers['user_name']?.text.isNotEmpty == true
                          ? _controllers['user_name']!.text
                          : 'Usuario',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(user?.email ?? '—',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Preferencias ─────────────────────────
                const Text('Preferences',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey)),
                const SizedBox(height: 8),

                ..._controllers.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.indigo,
                                  letterSpacing: 0.5),
                            ),
                            TextField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                hintText: entry.key,
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (v) =>
                                  _savePreference(entry.key, v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save all settings'),
                    onPressed: () async {
                      for (final e in _controllers.entries) {
                        await _savePreference(e.key, e.value.text);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                // ── Logout ───────────────────────────────
                const Text('Account',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey)),
                const SizedBox(height: 8),

                Card(
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Log out',
                        style: TextStyle(color: Colors.red)),
                    subtitle: Text(user?.email ?? '',
                        style: const TextStyle(fontSize: 12)),
                    onTap: _showLogoutDialog,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
    );
  }
}
