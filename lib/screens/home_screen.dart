// lib/screens/home_screen.dart
// ─── W13: QR Scanner + Firebase ───────────────────────────────
// El GPS se captura SOLO en _saveRecord(), al registrar la acción.
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/constants.dart';
import '../models/scan_record.dart';
import '../db/database_helper.dart';
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
    _loadUserName();
    _showWelcomeToast();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final user  = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name')
            ?? user?.email?.split('@').first
            ?? 'Usuario';
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

  // ── QR Scanner ───────────────────────────────────────────

  Future<void> _openQrScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QrScannerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      _showAddRecordDialog(result);
    }
  }

  // ── Diálogo para guardar registro tras escanear ───────────

  Future<void> _showAddRecordDialog(String qrCode) async {
    final reasonController = TextEditingController();
    ScanAction selectedAction = ScanAction.pick;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDialogState) {
            return AlertDialog(
              title: Text('Escaneado: $qrCode'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ScanAction>(
                    value: selectedAction,
                    decoration: const InputDecoration(
                        labelText: 'Action type'),
                    items: ScanAction.values
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text('${a.icon}  ${a.label}'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedAction = v);
                      }
                    },
                  ),
                  if (selectedAction.requiresReason) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _saveRecord(
                        qrCode,
                        reasonController.text.trim(),
                        selectedAction);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Save: GPS captured ONLY here ────────────────────────

  Future<void> _saveRecord(
      String qrCode, String reason, ScanAction action) async {

    // One-shot GPS: a single position is captured at record time
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      _logger.w('GPS no disponible al guardar: $e');
    }

    final record = ScanRecord(
      qrCode: qrCode,
      reason: reason,
      action: action,
      latitude:  pos?.latitude,
      longitude: pos?.longitude,
    );

    // 1. Save locally in SQFLite
    await DatabaseHelper.instance.insertScan(record);

    // 2. Save to Firebase Realtime Database
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseDatabase.instance
            .ref('scans/${user.uid}')
            .push()
            .set(record.toMap()..remove('id'));
        _logger.d('Saved to Firebase');
      } catch (e) {
        _logger.w('Error Firebase: $e');
      }
    }

    _showSnackBar('✓ Record saved');
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2)));
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
              await Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()));
              _loadUserName();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Botón principal: escanear QR ─────────────
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 24),
                label: const Text('Scan locker QR code',
                    style: TextStyle(fontSize: 16)),
                onPressed: _openQrScanner,
              ),
            ),
            const SizedBox(height: 16),

            // ── Explicación del flujo ─────────────────────
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('How does it work?',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15)),
                    SizedBox(height: 10),
                    _StepRow(icon: Icons.qr_code,
                        text: 'Scan the locker QR code'),
                    _StepRow(icon: Icons.edit_note,
                        text: 'Select pickup or return'),
                    _StepRow(icon: Icons.gps_fixed,
                        text: 'Your GPS location is saved automatically'),
                    _StepRow(icon: Icons.cloud_done,
                        text: 'The record is synced to the cloud'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Firebase session info ──────────────────────
            Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.account_circle_outlined,
                    color: Colors.indigo),
                title: const Text('Active session',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  FirebaseAuth.instance.currentUser?.email ?? '—',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.cloud_done_outlined,
                    color: Colors.green, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget auxiliar para los pasos ────────────────────────────
class _StepRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _StepRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.indigo),
          const SizedBox(width: 10),
          Expanded(child: Text(text,
              style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ── Pantalla del escáner QR ───────────────────────────────────
class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_scanned) return;
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _scanned = true;
                Navigator.of(context).pop(barcode!.rawValue);
              }
            },
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Text(
              'Point at the locker QR code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
