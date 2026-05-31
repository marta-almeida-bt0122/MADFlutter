// lib/screens/home_screen.dart
// ─── W9: Pantalla principal - StatelessWidget ─────────────────
// Demuestra: StatelessWidget, funciones recursivas, enums,
//            async/await, clases y colecciones (snippets W9)
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/scan_record.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ── Función recursiva del snippet W9 ──────────────────────
  int fibonacci(int n) {
    if (n == 0 || n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
  }

  // ── Async/await del snippet W9 ────────────────────────────
  Future<String> fetchAppInfo() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return '${AppConstants.appName} v${AppConstants.appVersion} '
        '· ${AppConstants.maxLockers} armarios disponibles';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Bienvenida ─────────────────────────────────
            _SectionCard(
              title: 'Bienvenido a LockerScan',
              child: const Text(
                'Escanea el QR de tu armario, autentícate y '
                'registra qué has recogido y para qué.',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),

            // ── App info con FutureBuilder (async/await W9) ─
            _SectionCard(
              title: 'Información de la app',
              child: FutureBuilder<String>(
                future: fetchAppInfo(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  return Text(
                    snap.data ?? '',
                    style: const TextStyle(fontSize: 13,
                        fontFamily: 'monospace'),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Enum - tipos de acción (enhanced enum W9) ──
            _SectionCard(
              title: 'Tipos de acción disponibles',
              child: Column(
                children: ScanAction.values.map((action) {
                  return ListTile(
                    leading: Text(action.icon,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(action.label,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(action.requiresReason
                        ? 'Requiere indicar el motivo'
                        : 'Sin motivo requerido'),
                    trailing: action.isPickup
                        ? const Icon(Icons.arrow_downward, color: Colors.indigo)
                        : const Icon(Icons.arrow_upward, color: Colors.teal),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Demo ScanRecord (clase Dart W9) ────────────
            _SectionCard(
              title: 'Demo modelo ScanRecord',
              child: Builder(builder: (ctx) {
                // Collections: List (snippet W9)
                final List<ScanRecord> demos = [
                  ScanRecord(
                    qrCode: 'LOCKER_42',
                    reason: 'Proyecto MAD',
                    action: ScanAction.pick,
                  ),
                  ScanRecord(
                    qrCode: 'LOCKER_07',
                    reason: '',
                    action: ScanAction.returnItem,
                  ),
                ];
                return Column(
                  children: demos.map((r) => ListTile(
                    dense: true,
                    title: Text(r.qrCode,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('${r.action.label} · ${r.formattedDate}'),
                    trailing: Text(r.action.icon,
                        style: const TextStyle(fontSize: 20)),
                  )).toList(),
                );
              }),
            ),
            const SizedBox(height: 16),

            // ── Fibonacci recursivo (snippet W9) ───────────
            _SectionCard(
              title: 'Demo Dart: Fibonacci recursivo',
              child: Text(
                List.generate(8, (i) => 'fib($i) = ${fibonacci(i)}')
                    .join('\n'),
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 13, height: 1.7),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ── Widget auxiliar reutilizable ───────────────────────────────
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
