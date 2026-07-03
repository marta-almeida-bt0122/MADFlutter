// lib/screens/home_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app.dart' show PendingLocker;
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
    // Consume a pending locker from the web URL (?locker=XXX after login).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locker = PendingLocker.value;
      if (locker != null && mounted) {
        PendingLocker.value = null;
        _showAddRecordDialog(locker);
      }
    });
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
      _showAddRecordDialog(_extractLockerCode(result));
    }
  }

  /// Tries to parse [raw] as a URL and extract the 'locker' query param.
  /// Falls back to [raw] itself for legacy plain-text QR codes.
  String _extractLockerCode(String raw) {
    try {
      final uri = Uri.parse(raw);
      if (uri.hasScheme && uri.queryParameters.containsKey('locker')) {
        final code = uri.queryParameters['locker']!;
        if (code.isNotEmpty) return code;
      }
    } catch (_) {}
    return raw;
  }

  // ── Diálogo para guardar registro ─────────────────────────

  Future<void> _showAddRecordDialog(String qrCode) async {
    final reasonController = TextEditingController();
    ScanAction selectedAction = ScanAction.pick;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDialogState) {
            return AlertDialog(
              title: Text('Locker: $qrCode'),
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

    // GPS capture — gracefully degraded when unavailable or denied.
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      _logger.w('GPS unavailable: $e');
    }

    final record = ScanRecord(
      qrCode: qrCode,
      reason: reason,
      action: action,
      latitude:  pos?.latitude,
      longitude: pos?.longitude,
    );

    // 1. Local SQFLite — skipped on web (sqflite not supported there).
    if (!kIsWeb) {
      try {
        await DatabaseHelper.instance.insertScan(record);
      } catch (e) {
        _logger.w('Local DB error: $e');
      }
    }

    // 2. Firebase Realtime Database.
    final user = FirebaseAuth.instance.currentUser;
    bool cloudSaved = false;
    if (user != null) {
      try {
        await FirebaseDatabase.instance
            .ref('scans/${user.uid}')
            .push()
            .set(record.toMap()..remove('id'));
        _logger.d('Saved to Firebase');
        cloudSaved = true;
      } catch (e) {
        _logger.w('Firebase error: $e');
      }
    }

    if (cloudSaved) {
      _showSnackBar('✓ Record saved');
    } else if (kIsWeb) {
      // On web there is no local fallback, so warn the user.
      _showSnackBar('⚠ No connection — record not saved');
    } else {
      _showSnackBar('✓ Saved locally (sync pending)');
    }
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

            // ── Scan button ──────────────────────────────
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

            // ── How does it work? ─────────────────────────
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
                        text: 'Scan the locker QR code or open the locker link'),
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

            // ── Active session card ───────────────────────
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

// ── Step row widget ───────────────────────────────────────────
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

// ── QR scanner screen ─────────────────────────────────────────
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
            errorBuilder: (context, error, child) {
              final isPermissionDenied =
                  error.errorCode == MobileScannerErrorCode.permissionDenied;
              return Container(
                color: Colors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPermissionDenied
                              ? Icons.no_photography_outlined
                              : Icons.error_outline,
                          size: 64,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isPermissionDenied
                              ? 'Camera permission denied.\nGrant permission in Settings and try again.'
                              : 'Camera error: ${error.errorDetails?.message ?? error.errorCode.name}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
