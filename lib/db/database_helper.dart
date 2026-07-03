// lib/db/database_helper.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_record.dart';

class DatabaseHelper {

  // ── Singleton ─────────────────────────────────────────────
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // ── Inicialización SQLite ─────────────────────────────────

  Future<Database> _initDB() async {
    final path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'locker_scan.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scans(
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            qr_code   TEXT NOT NULL,
            reason    TEXT,
            action    TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            latitude  REAL,
            longitude REAL
          )
        ''');
      },
    );
  }

  // ── INSERT (mobile/desktop only — web writes directly to Firebase) ──

  Future<int> insertScan(ScanRecord record) async {
    final db = await database;
    return await db.insert(
      'scans',
      record.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── SELECT ALL ────────────────────────────────────────────
  // Web: reads Firebase Realtime DB at scans/{uid}.
  // Native: reads local SQLite.

  Future<List<ScanRecord>> getAllScans() async {
    if (kIsWeb) return _getAllScansFromFirebase();
    final db = await database;
    final maps = await db.query('scans', orderBy: 'timestamp DESC');
    return maps.map((m) => ScanRecord.fromMap(m)).toList();
  }

  Future<List<ScanRecord>> _getAllScansFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    try {
      final snap =
          await FirebaseDatabase.instance.ref('scans/${user.uid}').get();
      if (!snap.exists) return [];
      final records = snap.children.map(_recordFromSnapshot).toList();
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    } catch (_) {
      return [];
    }
  }

  // ── SELECT coordinates (para el mapa) ────────────────────
  // Web: reads Firebase Realtime DB.
  // Native: reads local SQLite.

  Future<List<Map<String, dynamic>>> getCoordinates() async {
    if (kIsWeb) return _getCoordinatesFromFirebase();
    final db = await database;
    return await db.query(
      'scans',
      columns: ['latitude', 'longitude', 'qr_code'],
      where: 'latitude IS NOT NULL AND longitude IS NOT NULL',
    );
  }

  Future<List<Map<String, dynamic>>> _getCoordinatesFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    try {
      final snap =
          await FirebaseDatabase.instance.ref('scans/${user.uid}').get();
      if (!snap.exists) return [];
      return snap.children
          .map((child) =>
              Map<String, dynamic>.from(child.value as Map<Object?, Object?>))
          .where((m) => m['latitude'] != null && m['longitude'] != null)
          .map((m) => {
                'latitude': (m['latitude'] as num).toDouble(),
                'longitude': (m['longitude'] as num).toDouble(),
                'qr_code': m['qr_code'] as String,
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── DELETE ────────────────────────────────────────────────
  // Web:    removes node at scans/{uid}/{record.firebaseKey}.
  // Native: deletes row by record.id from SQLite.

  Future<void> deleteScan(ScanRecord record) async {
    if (kIsWeb) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || record.firebaseKey == null) return;
      await FirebaseDatabase.instance
          .ref('scans/${user.uid}/${record.firebaseKey}')
          .remove();
      return;
    }
    final db = await database;
    await db.delete('scans', where: 'id = ?', whereArgs: [record.id]);
  }

  // ── UPDATE ────────────────────────────────────────────────
  // Web:    patches 'reason' at scans/{uid}/{record.firebaseKey}.
  // Native: updates 'reason' by record.id in SQLite.

  Future<void> updateScan(ScanRecord record, String newReason) async {
    if (kIsWeb) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || record.firebaseKey == null) return;
      await FirebaseDatabase.instance
          .ref('scans/${user.uid}/${record.firebaseKey}')
          .update({'reason': newReason});
      return;
    }
    final db = await database;
    await db.update(
      'scans',
      {'reason': newReason},
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  // ── Firebase snapshot → ScanRecord ───────────────────────
  // Reads child.key as the push key and attaches it via withFirebaseKey()
  // so delete/update can reference the exact Firebase node later.
  // num?.toDouble() guards against Firebase coercing whole-number doubles to int.

  ScanRecord _recordFromSnapshot(DataSnapshot child) {
    final raw = Map<String, dynamic>.from(
        child.value as Map<Object?, Object?>);
    return ScanRecord.fromMap({
      ...raw,
      'latitude': (raw['latitude'] as num?)?.toDouble(),
      'longitude': (raw['longitude'] as num?)?.toDouble(),
      'reason': (raw['reason'] as String?) ?? '',
    }).withFirebaseKey(child.key);
  }
}
