import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class AttendanceService {
  static Database? _db;
  static const _uuid = Uuid();

  static Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'attendance.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE attendance_logs (
            id TEXT PRIMARY KEY,
            employee_id TEXT NOT NULL,
            employee_name TEXT NOT NULL,
            site_id INTEGER NOT NULL,
            site_name TEXT NOT NULL,
            type TEXT NOT NULL,
            status TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            geo_distance REAL,
            face_verified INTEGER DEFAULT 0,
            face_image_path TEXT,
            failure_reason TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE sites (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            address TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            radius REAL NOT NULL DEFAULT 200,
            shift TEXT,
            active INTEGER DEFAULT 1
          )
        ''');

        // Seed demo sites
        final sites = [
          {'id': 1, 'name': 'Jindal Stainless – Unit A', 'address': 'Hisar, Haryana', 'latitude': 29.1492, 'longitude': 75.7217, 'radius': 200.0, 'shift': 'Morning/Night', 'active': 1},
          {'id': 2, 'name': 'Plant – Steel Rolling', 'address': 'Rourkela, Odisha', 'latitude': 22.2604, 'longitude': 84.8536, 'radius': 350.0, 'shift': '24/7', 'active': 1},
          {'id': 3, 'name': 'Corporate HQ', 'address': 'Gurugram, Haryana', 'latitude': 28.4595, 'longitude': 77.0266, 'radius': 100.0, 'shift': 'Day', 'active': 1},
          {'id': 4, 'name': 'Warehouse – North Depot', 'address': 'Ludhiana, Punjab', 'latitude': 30.9, 'longitude': 75.85, 'radius': 500.0, 'shift': 'Morning', 'active': 0},
        ];

        for (final site in sites) {
          await db.insert('sites', site);
        }
      },
    );
  }

  static Future<PunchResult> punch({
    required String employeeId,
    required String employeeName,
    required int siteId,
    required String siteName,
    required String type, // 'in' or 'out'
    required double latitude,
    required double longitude,
    required double geoDistance,
    required bool faceVerified,
    required bool geoVerified,
    String? faceImagePath,
    String? failureReason,
  }) async {
    final database = await db;
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();

    final success = faceVerified && geoVerified;
    final status = success ? 'success' : 'failed';

    await database.insert('attendance_logs', {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'site_id': siteId,
      'site_name': siteName,
      'type': type,
      'status': status,
      'timestamp': now,
      'latitude': latitude,
      'longitude': longitude,
      'geo_distance': geoDistance,
      'face_verified': faceVerified ? 1 : 0,
      'face_image_path': faceImagePath,
      'failure_reason': failureReason,
      'synced': 0,
    });

    return PunchResult(
      success: success,
      id: id,
      timestamp: now,
      failureReason: failureReason,
    );
  }

  static Future<List<Map<String, dynamic>>> getEmployeeLogs(
      String employeeId) async {
    final database = await db;
    return database.query(
      'attendance_logs',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
      orderBy: 'timestamp DESC',
      limit: 60,
    );
  }

  static Future<List<Map<String, dynamic>>> getAllLogs({
    String? date,
    int? siteId,
  }) async {
    final database = await db;
    String? where;
    List<dynamic>? whereArgs;

    if (date != null && siteId != null) {
      where = "timestamp LIKE ? AND site_id = ?";
      whereArgs = ['$date%', siteId];
    } else if (date != null) {
      where = "timestamp LIKE ?";
      whereArgs = ['$date%'];
    } else if (siteId != null) {
      where = "site_id = ?";
      whereArgs = [siteId];
    }

    return database.query(
      'attendance_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: 200,
    );
  }

  static Future<Map<String, int>> getTodayStats() async {
    final database = await db;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await database.rawQuery('''
      SELECT 
        COUNT(DISTINCT CASE WHEN status = 'success' AND type = 'in' THEN employee_id END) as present,
        COUNT(DISTINCT CASE WHEN status = 'failed' THEN employee_id END) as failed
      FROM attendance_logs
      WHERE timestamp LIKE ?
    ''', ['$today%']);

    final row = result.first;
    return {
      'present': (row['present'] as int?) ?? 0,
      'failed': (row['failed'] as int?) ?? 0,
    };
  }

  static Future<List<Map<String, dynamic>>> getAllSites() async {
    final database = await db;
    return database.query('sites', orderBy: 'name ASC');
  }

  static Future<Map<String, dynamic>?> getSite(int id) async {
    final database = await db;
    final rows = await database.query('sites', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  static Future<void> updateSiteRadius(int siteId, double radius) async {
    final database = await db;
    await database.update(
      'sites',
      {'radius': radius},
      where: 'id = ?',
      whereArgs: [siteId],
    );
  }

  static Future<void> toggleSiteActive(int siteId, bool active) async {
    final database = await db;
    await database.update(
      'sites',
      {'active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [siteId],
    );
  }
}

class PunchResult {
  final bool success;
  final String id;
  final String timestamp;
  final String? failureReason;

  PunchResult({
    required this.success,
    required this.id,
    required this.timestamp,
    this.failureReason,
  });
}
