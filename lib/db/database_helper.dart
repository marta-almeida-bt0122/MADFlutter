// lib/db/database_helper.dart
// ─── W12: SQFLite - singleton con CRUD completo ───────────────
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

  // ── Inicialización ────────────────────────────────────────

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

  // ── INSERT ────────────────────────────────────────────────

  Future<int> insertScan(ScanRecord record) async {
    final db = await database;
    return await db.insert(
      'scans',
      record.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── SELECT ALL ────────────────────────────────────────────

  Future<List<ScanRecord>> getAllScans() async {
    final db = await database;
    final maps = await db.query('scans', orderBy: 'timestamp DESC');
    return maps.map((m) => ScanRecord.fromMap(m)).toList();
  }

  // ── SELECT solo coordenadas (para el mapa) ────────────────

  Future<List<Map<String, dynamic>>> getCoordinates() async {
    final db = await database;
    return await db.query(
      'scans',
      columns: ['latitude', 'longitude', 'qr_code'],
      where: 'latitude IS NOT NULL AND longitude IS NOT NULL',
    );
  }

  // ── DELETE por id ─────────────────────────────────────────

  Future<void> deleteScan(int id) async {
    final db = await database;
    await db.delete(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── UPDATE ────────────────────────────────────────────────

  Future<void> updateScan(int id, String newReason) async {
    final db = await database;
    await db.update(
      'scans',
      {'reason': newReason},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
