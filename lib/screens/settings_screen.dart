// lib/screens/settings_screen.dart
// ─── W11: SharedPreferences — leer, editar y guardar ──────────
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final Logger _logger = Logger();

  // Un controller por cada clave de SharedPreferences
  Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;

  // Preferencias por defecto que siempre estarán disponibles
  static const Map<String, String> _defaultPrefs = {
    'user_name'  : 'Usuario',
    'user_email' : '',
    'server_url' : 'https://mi-servidor.com',
  };

  @override
  void initState() {
    super.initState();
    _logger.d('SettingsScreen · initState');
    _loadAllPreferences();
  }

  @override
  void dispose() {
    // Liberar todos los controllers
    for (final c in _controllers.values) {
      c.dispose();
    }
    _logger.d('SettingsScreen · dispose');
    super.dispose();
  }

  // ── Cargar TODAS las preferencias guardadas ───────────────

  Future<void> _loadAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Asegurar que las claves por defecto existen
    for (final entry in _defaultPrefs.entries) {
      if (!prefs.containsKey(entry.key)) {
        await prefs.setString(entry.key, entry.value);
      }
    }

    final keys = prefs.getKeys();
    final Map<String, TextEditingController> controllers = {};

    for (final key in keys) {
      final value = prefs.get(key)?.toString() ?? '';
      controllers[key] = TextEditingController(text: value);
    }

    if (mounted) {
      setState(() {
        _controllers = controllers;
        _isLoading = false;
      });
    }
  }

  // ── Save a preference ───────────────────────────────

  Future<void> _savePreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    _logger.d('Guardado: $key = $value');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guardado: $key'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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

                const Text(
                  'User preferences',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // Una tarjeta por preferencia
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
                              entry.key.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.indigo,
                                  letterSpacing: 0.5),
                            ),
                            TextField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                hintText: 'Introduce ${entry.key}',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (value) =>
                                  _savePreference(entry.key, value),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 8),

                // Save all at once
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save all settings'),
                    onPressed: () async {
                      for (final entry in _controllers.entries) {
                        await _savePreference(entry.key, entry.value.text);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // ── Zona de peligro (W13: aquí irá Logout) ──
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Account',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey),
                ),
                const SizedBox(height: 12),
                // W13: reemplazar con botón de logout Firebase
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.grey),
                  title: const Text('Log out',
                      style: TextStyle(color: Colors.grey)),
                  subtitle: const Text(
                      'Available in W13 with Firebase Auth',
                      style: TextStyle(fontSize: 12)),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: null,
                ),
              ],
            ),
    );
  }
}
