// lib/core/constants.dart
// ─── W9/W10: Constantes globales y enums ──────────────────────
class AppConstants {
  static const String appName    = 'LockerScan';
  static const String appVersion = '1.0.0';
  static const int    maxLockers = 100;
}

enum ScanAction {
  pick(label: 'Recogida',     icon: '📦', requiresReason: true),
  returnItem(label: 'Devolución', icon: '↩️', requiresReason: false);

  const ScanAction({
    required this.label,
    required this.icon,
    required this.requiresReason,
  });

  final String label;
  final String icon;
  final bool   requiresReason;

  bool get isPickup => this == ScanAction.pick;

  static ScanAction fromString(String value) {
    return ScanAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ScanAction.pick,
    );
  }
}
