// lib/screens/collection_screen.dart
// ─── W12: Aquí irá la lista de registros con SQFLite ──────────
// Por ahora es un placeholder StatefulWidget (W10)
import 'package:flutter/material.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {

  @override
  void initState() {
    super.initState();
    // W12: aquí se llamará a DatabaseHelper.instance.getScans()
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis registros'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Lista de escaneos\n(disponible en W12 con SQFLite)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ),
      // W12: FAB para añadir registro
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // W12: abrir diálogo para registrar recogida
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
