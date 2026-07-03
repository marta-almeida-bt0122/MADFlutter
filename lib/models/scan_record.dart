// lib/models/scan_record.dart
import '../core/constants.dart';

class ScanRecord {
  final int?       id;
  /// Firebase Realtime DB push key — set on web reads, null on native.
  final String?    firebaseKey;
  final String     qrCode;
  final String     reason;
  final ScanAction action;
  final DateTime   timestamp;
  final double?    latitude;
  final double?    longitude;

  ScanRecord({
    this.id,
    this.firebaseKey,
    required this.qrCode,
    required this.reason,
    required this.action,
    DateTime?     timestamp,
    this.latitude,
    this.longitude,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedDate {
    final d = timestamp;
    return '${_pad(d.day)}/${_pad(d.month)}/${d.year} '
           '${_pad(d.hour)}:${_pad(d.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  // firebaseKey is derived from the node key, not stored in the value.
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'qr_code'  : qrCode,
    'reason'   : reason,
    'action'   : action.name,
    'timestamp': timestamp.millisecondsSinceEpoch.toString(),
    'latitude' : latitude,
    'longitude': longitude,
  };

  factory ScanRecord.fromMap(Map<String, dynamic> map) => ScanRecord(
    id        : map['id'] as int?,
    qrCode    : map['qr_code'] as String,
    reason    : map['reason']  as String,
    action    : ScanAction.fromString(map['action'] as String),
    timestamp : DateTime.fromMillisecondsSinceEpoch(
                  int.parse(map['timestamp'].toString())),
    latitude  : map['latitude']  as double?,
    longitude : map['longitude'] as double?,
  );

  /// Returns a copy of this record with [firebaseKey] set.
  /// Used by DatabaseHelper after reading a Firebase snapshot.
  ScanRecord withFirebaseKey(String? key) => ScanRecord(
        id: id,
        firebaseKey: key,
        qrCode: qrCode,
        reason: reason,
        action: action,
        timestamp: timestamp,
        latitude: latitude,
        longitude: longitude,
      );

  @override
  String toString() =>
      'ScanRecord(qr: $qrCode, action: ${action.label})';
}
