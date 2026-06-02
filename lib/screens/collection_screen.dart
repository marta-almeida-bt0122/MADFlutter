// lib/screens/collection_screen.dart
// ─── W12: Lista SQFLite con CRUD completo ─────────────────────
// Tap → diálogo de borrar  |  Long press → diálogo de editar
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  void dispose() {
    _logger.d('CollectionScreen · dispose');
    super.dispose();
  }

  // ── Carga ─────────────────────────────────────────────────

  Future<void> _loadScans() async {
    final scans = await DatabaseHelper.instance.getAllScans();
    if (mounted) {
      setState(() {
        _scans = scans;
        _isLoading = false;
      });
    }
  }

  // ── INSERT: nuevo registro con QR + motivo ────────────────

  Future<void> _showAddDialog() async {
    final qrController     = TextEditingController(text: 'LOCKER_');
    final reasonController = TextEditingController();
    ScanAction selectedAction = ScanAction.pick;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDialogState) {
            return AlertDialog(
              title: const Text('New record'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: qrController,
                      decoration: const InputDecoration(
                        labelText: 'QR code',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ScanAction>(
                      value: selectedAction,
                      decoration: const InputDecoration(
                          labelText: 'Action type'),
                      items: ScanAction.values
                          .map((a) => DropdownMenuItem(
                                value: a,
                                child: Text(
                                    '${a.icon}  ${a.label}'),
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
                      qrController.text.trim(),
                      reasonController.text.trim(),
                      selectedAction,
                    );
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

  Future<void> _saveRecord(
      String qrCode, String reason, ScanAction action) async {
    // Get current GPS position
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      _logger.w('No se pudo obtener GPS al guardar');
    }

    final record = ScanRecord(
      qrCode: qrCode,
      reason: reason,
      action: action,
      latitude:  pos?.latitude,
      longitude: pos?.longitude,
    );

    await DatabaseHelper.instance.insertScan(record);
    // W13: aquí también se guardará en Firebase Realtime DB
    _loadScans();
    _showSnackBar('Record saved');
  }

  // ── DELETE ────────────────────────────────────────────────

  Future<void> _showDeleteDialog(ScanRecord record) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${record.qrCode}?'),
        content: Text(
            '${record.action.label} del ${record.formattedDate}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await DatabaseHelper.instance.deleteScan(record.id!);
              _loadScans();
              _showSnackBar('Record deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── UPDATE ────────────────────────────────────────────────

  Future<void> _showUpdateDialog(ScanRecord record) async {
    final controller = TextEditingController(text: record.reason);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${record.qrCode}'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(labelText: 'New reason'),
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
                  .updateScan(record.id!, controller.text.trim());
              _loadScans();
              _showSnackBar('Record updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2)),
    );
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
                        'Sin registros.\nPulsa + para añadir uno.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
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
                            style: const TextStyle(fontSize: 22)),
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
                        trailing: scan.latitude != null
                            ? const Icon(Icons.location_on,
                                size: 16,
                                color: Colors.indigo)
                            : const Icon(Icons.location_off,
                                size: 16, color: Colors.grey),
                        // Tap → confirmar borrado
                        onTap: () => _showDeleteDialog(scan),
                        // Long press → edit reason
                        onLongPress: () => _showUpdateDialog(scan),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'New record',
        child: const Icon(Icons.add),
      ),
    );
  }
}
