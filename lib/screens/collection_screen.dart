// lib/screens/collection_screen.dart
// ─── W11: ListView reading coordinates from the CSV file ────────
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {

  final Logger _logger = Logger();
  List<List<String>> _coordinates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _logger.d('CollectionScreen · initState');
    _loadCoordinates();
  }

  @override
  void dispose() {
    _logger.d('CollectionScreen · dispose');
    super.dispose();
  }

  // ── Leer CSV ─────────────────────────────────────────────

  Future<void> _loadCoordinates() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/gps_coordinates.csv');

      if (!await file.exists()) {
        setState(() {
          _coordinates = [];
          _isLoading = false;
        });
        return;
      }

      final lines = await file.readAsLines();
      setState(() {
        _coordinates = lines
            .where((l) => l.trim().isNotEmpty)
            .map((l) => l.split(';'))
            .where((parts) => parts.length >= 3)
            .toList();
        _isLoading = false;
      });
      } catch (e) {
      _logger.e('Error reading CSV: $e');
      setState(() => _isLoading = false);
    }
  }

  // ── Formatear timestamp ───────────────────────────────────

  String _formatTimestamp(String raw) {
    try {
      final ms = int.parse(raw);
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(dt);
    } catch (_) {
      return raw;
    }
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPS Coordinates (${_coordinates.length})'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
            IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadCoordinates();
            },
            tooltip: 'Reload',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coordinates.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No coordinates yet.\nEnable GPS in Home.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _coordinates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final coord = _coordinates[index];
                    // W12: the list from SQFLite will also be added
                    return Card(
                      elevation: 0,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.withOpacity(0.1),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                                color: Colors.indigo, fontSize: 13),
                          ),
                        ),
                        title: Text(
                          _formatTimestamp(coord[0]),
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          'Lat: ${double.tryParse(coord[1])?.toStringAsFixed(6) ?? coord[1]}'
                          '  Lon: ${double.tryParse(coord[2])?.toStringAsFixed(6) ?? coord[2]}',
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 12),
                        ),
                        trailing: const Icon(Icons.location_on,
                            color: Colors.indigo, size: 18),
                      ),
                    );
                  },
                ),
      // W12: FAB to add manual scan
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Manual scan available in W12'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        tooltip: 'New record',
        child: const Icon(Icons.add),
      ),
    );
  }
}
