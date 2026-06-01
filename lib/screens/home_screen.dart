// lib/screens/home_screen.dart
// ─── W10: StatefulWidget con ciclo de vida completo ───────────
// Cambio respecto W9: StatelessWidget → StatefulWidget
// Demuestra: initState, didChangeDependencies, didUpdateWidget,
//            dispose, y los métodos del ciclo de vida (W11 snippet)
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../core/constants.dart';
import '../models/scan_record.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final Logger _logger = Logger();

  // Estado local de la pantalla
  String _appInfo = 'Cargando...';
  bool   _isLoading = true;

  // ── Ciclo de vida (snippet W11) ───────────────────────────

  @override
  void initState() {
    super.initState();
    _logger.d('HomeScreen · initState');
    // Cargar datos al crear el widget (async desde initState)
    _loadAppInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se llama después de initState y cuando cambia un
    // InheritedWidget del que depende esta pantalla
    _logger.d('HomeScreen · didChangeDependencies');
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se llama cuando el widget padre se reconstruye
    _logger.d('HomeScreen · didUpdateWidget');
  }

  @override
  void dispose() {
    // Liberar recursos (streams, controllers, timers)
    // W11: aquí se cancelará _positionStreamSubscription
    _logger.d('HomeScreen · dispose');
    super.dispose();
  }

  // ── Lógica ───────────────────────────────────────────────

  // Async/await: simula carga de datos (W11 vendrá de SharedPrefs)
  Future<void> _loadAppInfo() async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Colección Map (snippet W9)
    final Map<String, String> info = {
      'App'      : AppConstants.appName,
      'Versión'  : AppConstants.appVersion,
      'Armarios' : '${AppConstants.maxLockers} disponibles',
    };

    if (mounted) {
      setState(() {
        _appInfo  = info.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        _isLoading = false;
      });
    }
  }

  // Función recursiva (snippet W9)
  int fibonacci(int n) {
    if (n == 0 || n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
  }

  // ── UI ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _logger.d('HomeScreen · build');

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Bienvenida ──────────────────────────
                  _SectionCard(
                    title: 'Bienvenido a LockerScan',
                    child: const Text(
                      'Escanea el QR de tu armario, autentícate\n'
                      'y registra qué has recogido y para qué.',
                      style: TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Info de la app ──────────────────────
                  _SectionCard(
                    title: 'Información de la app',
                    child: Text(
                      _appInfo,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.7),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Acciones disponibles (enum W9) ──────
                  _SectionCard(
                    title: 'Tipos de acción',
                    child: Column(
                      children: ScanAction.values.map((action) {
                        return ListTile(
                          leading: Text(
                            action.icon,
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(
                            action.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            action.requiresReason
                                ? 'Requiere motivo'
                                : 'Sin motivo requerido',
                          ),
                          trailing: Icon(
                            action.isPickup
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: action.isPickup
                                ? Colors.indigo
                                : Colors.teal,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Demo ScanRecord (clase W9) ──────────
                  _SectionCard(
                    title: 'Demo modelo ScanRecord',
                    child: Column(
                      children: [
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
                      ].map((r) => ListTile(
                        dense: true,
                        leading: Text(r.action.icon,
                            style: const TextStyle(fontSize: 20)),
                        title: Text(r.qrCode,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                        subtitle: Text(
                            '${r.action.label} · ${r.formattedDate}'),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Fibonacci recursivo (W9) ─────────────
                  _SectionCard(
                    title: 'Demo Dart: Fibonacci recursivo',
                    child: Text(
                      List.generate(
                              8, (i) => 'fib($i) = ${fibonacci(i)}')
                          .join('\n'),
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.7),
                    ),
                  ),

                ],
              ),
            ),
    );
  }
}

// ── Widget auxiliar reutilizable (fichero separado en W11) ─────
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
