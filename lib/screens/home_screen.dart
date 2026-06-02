// lib/screens/home_screen.dart
// ─── W11: One-off GPS + SharedPreferences + AlertDialog + Toast
// Change: continuous CSV tracking removed.
// GPS is only captured when saving a record.
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/scan_record.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final Logger _logger = Logger();

  String  _userName        = 'User';
  String  _lastPosition    = 'No data yet';
  bool    _loadingLocation = false;

  // ── Ciclo de vida ─────────────────────────────────────────

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

  // ── SharedPreferences ─────────────────────────────────────

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'User';
      });
    }
  }

  // ── Toast de bienvenida ───────────────────────────────────

  void _showWelcomeToast() {
    Fluttertoast.showToast(
      msg: 'Welcome to LockerScan',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.indigo,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  // ── One-off GPS: capture ONE position on press ───────────
  // This is the same method used in _saveRecord() (W12/W13)
  // Only called when the user records an action.

  Future<Position?> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('GPS is disabled on the device');
      return null;
    }
    var permission = await Geolocator.checkPermission();
       if (permission == LocationPermission.denied) {
         permission = await Geolocator.requestPermission();
         if (permission == LocationPermission.denied) {
           _showSnackBar('Location permission denied');
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Permission permanently denied');
      return null;
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _demoGetLocation() async {
    setState(() => _loadingLocation = true);
    final pos = await _getCurrentPosition();
    if (mounted) {
      setState(() {
        _loadingLocation = false;
        _lastPosition = pos != null
            ? 'Lat: ${pos.latitude.toStringAsFixed(6)}\n'
              'Lon: ${pos.longitude.toStringAsFixed(6)}'
            : 'Could not obtain position';
      });
    }
    _logger.d('Position obtained: $pos');
  }

  // ── AlertDialog de demo ───────────────────────────────────

  Future<void> _showClearDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Demo AlertDialog'),
        content: const Text('Do you confirm this test action?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showSnackBar('Action confirmed');
            },
          ),
        ],
      ),
    );
  }

  // ── SnackBar ──────────────────────────────────────────────

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Info de la app ────────────────────────────
            _SectionCard(
              title: 'LockerScan',
              child: const Text(
                 'Scan your locker QR in the Records tab\n'
                 'and the GPS will be saved automatically at that moment.',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
            ),
            const SizedBox(height: 16),

            // ── GPS puntual ───────────────────────────────
            _SectionCard(
               title: 'My current position (GPS demo)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lastPosition,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _loadingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.gps_fixed, size: 18),
                       label: const Text('Get position'),
                      onPressed:
                          _loadingLocation ? null : _demoGetLocation,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Action types (enum W9) ─────────────────
            _SectionCard(
               title: 'Action types',
              child: Column(
                children: ScanAction.values.map((action) {
                  return ListTile(
                    dense: true,
                    leading: Text(action.icon,
                        style: const TextStyle(fontSize: 20)),
                    title: Text(action.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(action.requiresReason
                        ? 'Requires reason'
                        : 'No reason required'),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Demo pop-ups ──────────────────────────────
            _SectionCard(
              title: 'Demo pop-ups',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showClearDialog,
                    icon: const Icon(Icons.check_circle_outline,
                        size: 18),
                    label: const Text('AlertDialog'),
                  ),
                  ElevatedButton.icon(
                     onPressed: () =>
                         _showSnackBar('This is a SnackBar'),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('SnackBar'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showWelcomeToast,
                    icon: const Icon(Icons.notifications_outlined,
                        size: 18),
                    label: const Text('Toast'),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
