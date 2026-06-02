// lib/screens/map_screen.dart
// ─── W12: Mapa OpenStreetMap con markers desde SQFLite ────────
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import '../db/database_helper.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  final Logger _logger = Logger();
  final MapController _mapController = MapController();

  List<Marker> _markers = [];
  bool _isLoading = true;

  // Centro por defecto (Madrid, se actualizará con los markers)
  static const LatLng _defaultCenter = LatLng(40.4168, -3.7038);

  @override
  void initState() {
    super.initState();
    _logger.d('MapScreen · initState');
    _loadMarkers();
  }

  @override
  void dispose() {
    _logger.d('MapScreen · dispose');
    super.dispose();
  }

  // ── Cargar markers desde la base de datos ─────────────────

  Future<void> _loadMarkers() async {
    final coords = await DatabaseHelper.instance.getCoordinates();

    final loadedMarkers = coords.map((record) {
      final lat = record['latitude'] as double;
      final lon = record['longitude'] as double;
      final qr  = record['qr_code']  as String;

      return Marker(
        point: LatLng(lat, lon),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showMarkerInfo(qr, lat, lon),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  qr,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 9),
                ),
              ),
              const Icon(
                Icons.location_pin,
                size: 32,
                color: Colors.indigo,
              ),
            ],
          ),
        ),
      );
    }).toList();

    if (mounted) {
      setState(() {
        _markers = loadedMarkers;
        _isLoading = false;
      });
    }
  }

  void _showMarkerInfo(String qrCode, double lat, double lon) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(qrCode,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Lat: ${lat.toStringAsFixed(6)}',
                style: const TextStyle(fontFamily: 'monospace')),
            Text('Lon: ${lon.toStringAsFixed(6)}',
                style: const TextStyle(fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  // ── Tile Layer de OpenStreetMap ───────────────────────────

  TileLayer get _osmTileLayer => TileLayer(
        urlTemplate:
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'es.mad.locker_scan',
      );

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map (${_markers.length} points)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadMarkers();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _markers.isNotEmpty
                    ? _markers.first.point
                    : _defaultCenter,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all),
              ),
              children: [
                _osmTileLayer,
                MarkerLayer(markers: _markers),
              ],
            ),
      floatingActionButton: _markers.isNotEmpty
          ? FloatingActionButton.small(
              onPressed: () {
                _mapController.move(
                    _markers.first.point, 15);
              },
              tooltip: 'Center map',
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }
}
