// lib/core/constants.dart
// ─── W9: Constantes globales y enums mejorados ────────────────
// Demuestra: variables tipadas, enhanced enums (snippet W9)

class AppConstants {
  static const String appName    = 'LockerScan';
  static const String appVersion = '1.0.0';
  static const int    maxLockers = 100;
}

// Enhanced enum: cada acción del armario tiene propiedades
// (mismo patrón que Planet enum del snippet W9)
enum ScanAction {
  pick(label: 'Recogida',    icon: '📦', requiresReason: true),
  returnItem(label: 'Devolución', icon: '↩️', requiresReason: false);

  const ScanAction({
    required this.label,
    required this.icon,
    required this.requiresReason,
  });

  final String label;
  final String icon;
  final bool   requiresReason;

  // Enhanced enum getter (igual que isGiant en Planet)
  bool get isPickup => this == ScanAction.pick;

  // Factory desde String (útil para leer de base de datos)
  static ScanAction fromString(String value) {
    return ScanAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ScanAction.pick,
    );
  }
}
