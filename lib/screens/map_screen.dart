// lib/screens/map_screen.dart
// ─── W12: OpenStreetMap with markers will go here ──────────
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _logger.d('MapScreen · initState');
    // W12: loadMarkers() desde DatabaseHelper
  }

  @override
  void dispose() {
    _logger.d('MapScreen · dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map of scans'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'OpenStreetMap\nAvailable in W12',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
