// lib/models/scan_record.dart
// ─── W9: Modelo de datos - demuestra clases Dart ─────────────
// Demuestra: clases, constructores, getters, toString, herencia
import '../core/constants.dart';

class ScanRecord {
  final int?       id;
  final String     qrCode;
  final String     reason;
  final ScanAction action;
  final DateTime   timestamp;
  final double?    latitude;
  final double?    longitude;

  // Constructor con parámetros nombrados y valor por defecto
  ScanRecord({
    this.id,
    required this.qrCode,
    required this.reason,
    required this.action,
    DateTime?     timestamp,
    this.latitude,
    this.longitude,
  }) : timestamp = timestamp ?? DateTime.now();

  // Getter (snippet W9 - Spacecraft.yearsSinceLaunch)
  String get formattedDate {
    final d = timestamp;
    final date = '${_pad(d.day)}/${_pad(d.month)}/${d.year}';
    final time = '${_pad(d.hour)}:${_pad(d.minute)}';
    return '$date $time';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  // Serialización para SQFLite (W12) y Firebase (W13)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'qr_code'  : qrCode,
      'reason'   : reason,
      'action'   : action.name,
      'timestamp': timestamp.millisecondsSinceEpoch.toString(),
      'latitude' : latitude,
      'longitude': longitude,
    };
  }

  // Factory constructor desde Map (SQFLite / Firebase)
  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id        : map['id'] as int?,
      qrCode    : map['qr_code'] as String,
      reason    : map['reason']  as String,
      action    : ScanAction.fromString(map['action'] as String),
      timestamp : DateTime.fromMillisecondsSinceEpoch(
                    int.parse(map['timestamp'].toString())),
      latitude  : map['latitude']  as double?,
      longitude : map['longitude'] as double?,
    );
  }

  @override
  String toString() =>
      'ScanRecord(qr: $qrCode, action: ${action.label}, reason: $reason)';
}
