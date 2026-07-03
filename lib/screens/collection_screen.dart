// lib/screens/collection_screen.dart
// ─── W13: Lista SQFLite + sync con Firebase Realtime DB ───────
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';
import '../db/database_helper.dart';
import '../models/scan_record.dart';
import '../core/constants.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {

  final Logger _logger = Logger();
  List<ScanRecord> _scans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    final scans = await DatabaseHelper.instance.getAllScans();
    if (mounted) {
      setState(() {
        _scans = scans;
        _isLoading = false;
      });
    }
  }

  // ── DELETE local + Firebase ───────────────────────────────

  Future<void> _showDeleteDialog(ScanRecord record) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${record.qrCode}?'),
        content: const Text(
            'Se eliminará de la base de datos local.\n'
            'En Firebase quedan los registros históricos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await DatabaseHelper.instance.deleteScan(record);
              _loadScans();
              _showSnackBar('Record deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── UPDATE local ──────────────────────────────────────────

  Future<void> _showUpdateDialog(ScanRecord record) async {
    final controller = TextEditingController(text: record.reason);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${record.qrCode}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await DatabaseHelper.instance
                  .updateScan(record, controller.text.trim());
              _loadScans();
              _showSnackBar('Updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Ver registros en Firebase ─────────────────────────────

  Future<void> _showFirebaseCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseDatabase.instance
          .ref('scans/${user.uid}')
          .get();
      final count = snap.children.length;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Firebase: $count registros en la nube'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      _logger.w('Error Firebase: $e');
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
        title: Text('Records (${_scans.length})'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_outlined),
            onPressed: _showFirebaseCount,
            tooltip: 'Check Firebase total',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScans,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scans.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No records.\nScan a QR code from Home.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Ayuda para el usuario
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.indigo.withOpacity(0.05),
                      child: const Text(
                        'Tap → delete  ·  Long press → edit',
                        style:
                            TextStyle(fontSize: 12, color: Colors.indigo),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _scans.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, i) {
                          final scan = _scans[i];
                          return Card(
                            elevation: 0,
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: ListTile(
                              leading: Text(scan.action.icon,
                                  style:
                                      const TextStyle(fontSize: 22)),
                              title: Text(
                                scan.qrCode,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                '${scan.action.label}'
                                '${scan.reason.isNotEmpty ? ' · ${scan.reason}' : ''}'
                                '\n${scan.formattedDate}',
                              ),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    scan.latitude != null
                                        ? Icons.location_on
                                        : Icons.location_off,
                                    size: 16,
                                    color: scan.latitude != null
                                        ? Colors.indigo
                                        : Colors.grey,
                                  ),
                                  const SizedBox(height: 2),
                                  const Icon(Icons.cloud_done,
                                      size: 14, color: Colors.green),
                                ],
                              ),
                              onTap: () => _showDeleteDialog(scan),
                              onLongPress: () => _showUpdateDialog(scan),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
