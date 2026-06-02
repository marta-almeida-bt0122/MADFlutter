// lib/screens/home_screen.dart
// ─── W12: Pantalla de inicio limpia ───────────────────────────
// El GPS se captura únicamente en _saveRecord() de CollectionScreen
// al registrar una recogida o devolución, no de forma continua.
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final Logger _logger = Logger();
  String _userName = 'Usuario';

  @override
  void initState() {
    super.initState();
    _logger.d('HomeScreen · initState');
    _loadUserName();
    _showWelcomeToast();
  }

  @override
  void dispose() {
    _logger.d('HomeScreen · dispose');
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Usuario';
      });
    }
  }

  void _showWelcomeToast() {
    Fluttertoast.showToast(
      msg: 'Welcome to LockerScan',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.indigo,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, $_userName'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadUserName();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Bienvenida ────────────────────────────────
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LockerScan',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    const Text(
                      'Go to the Records tab to add a pickup or return.\nYour GPS location will be saved automatically.',
                      style: TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tipos de acción ───────────────────────────
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Action types',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    ...ScanAction.values.map((action) => ListTile(
                          dense: true,
                          leading: Text(action.icon,
                              style: const TextStyle(fontSize: 20)),
                          title: Text(action.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
                          subtitle: Text(action.requiresReason
                              ? 'Reason required'
                              : 'No reason required'),
                        )),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
