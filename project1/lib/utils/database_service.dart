import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  Database? _database;

  // 데이터베이스 초기화
  Future<Database> get database async {
    if (_database != null) return _database!;

    // 데이터베이스가 없으면 새로 생성
    _database = await _initDatabase();
    return _database!;
  }

  // 데이터베이스 생성
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'timers.db');

    // 데이터베이스 열기 또는 생성
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onUpgrade: _onUpgrade, // 마이그레이션 처리
    );
  }

  // 테이블 생성
  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE timers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timer_id TEXT,
        user_id TEXT,
        week_start TEXT,
        total_seconds INTEGER,
        remaining_seconds INTEGER,
        last_activity_id TEXT,
        created_at TEXT,
        last_updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id TEXT,
        user_id TEXT,
        timer_id TEXT,
        activity_time TEXT,
        created_at TEXT,
        last_updated_at TEXT
      )
    ''');
  }

  Future<void> updateTimer(
      String timerId, String userId, Map<String, dynamic> updatedData) async {
    final db = await database;
    await db.update(
      'timers',
      updatedData, // 업데이트할 데이터 (remaining_seconds, last_updated_at)
      where: 'timer_id = ? AND user_id = ?',
      whereArgs: [timerId, userId],
    );
  }

  // 마이그레이션 코드 추가 (version 2)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE timers ADD COLUMN last_updated_at TEXT');
    }
  }

// 타이머 조회 (user_id와 timer_id를 동시에 확인)
  Future<Map<String, dynamic>?> getTimer(
      String userId, DateTime weekStart) async {
    final db = await database;

    // DateTime을 문자열로 변환 (ISO 8601 형식)
    String weekStartString = weekStart.toIso8601String().split('T').first;

    final List<Map<String, dynamic>> result = await db.query(
      'timers',
      where: 'user_id = ? AND DATE(week_start) = ?',
      whereArgs: [userId, weekStartString],
    );

    return result.isNotEmpty ? result.first : null;
  }

  // 타이머 생성
  Future<void> createTimer(Map<String, dynamic> timerData) async {
    final db = await database;
    await db.insert('timers', timerData,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
