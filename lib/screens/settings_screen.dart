// lib/screens/settings_screen.dart
// ─── W11: SharedPreferences + Logger ──────────────────────────
// ─── W13: Logout Firebase ─────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _logger.d('SettingsScreen · initState');
    // W11: _loadAllPreferences() con SharedPreferences
  }

  @override
  void dispose() {
    _logger.d('SettingsScreen · dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Preferencias de usuario\nDisponible en W11 con SharedPreferences\n\nLogout Firebase en W13',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
