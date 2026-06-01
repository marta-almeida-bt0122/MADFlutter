// lib/screens/collection_screen.dart
// ─── W12: Aquí irá la lista de registros con SQFLite ──────────
// W10: StatefulWidget completo con ciclo de vida
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {

  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _logger.d('CollectionScreen · initState');
    // W12: DatabaseHelper.instance.getScans()
  }

  @override
  void dispose() {
    _logger.d('CollectionScreen · dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis registros'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Lista de escaneos\nDisponible en W12 con SQFLite',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // W12: abrir diálogo para nuevo registro
          // W13: además guardará en Firebase Realtime DB
        },
        tooltip: 'Nuevo registro',
        child: const Icon(Icons.add),
      ),
    );
  }
}
