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
      version: 3,
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
        is_running INTEGER,
        created_at TEXT,
        last_updated_at TEXT,
        last_started_at TEXT
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

  // 데이터베이스 삭제 메서드
  Future<void> deleteTimer() async {
    final path = join(await getDatabasesPath(), 'timers.db');
    await deleteDatabase(path); // 기존 데이터베이스 삭제
    print('데이터베이스가 삭제되었습니다.');
  }

  Future<void> updateTimer(
      String timerId, String userId, Map<String, dynamic> updatedData) async {
    final db = await database;
    await db.update(
      'timers',
      updatedData, // 업데이트할 데이터 (remaining_seconds, last_updated_at, is_running)
      where: 'timer_id = ? AND user_id = ?',
      whereArgs: [timerId, userId],
    );
  }

  // 마이그레이션 코드 추가 (version 2)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE timers ADD COLUMN last_updated_at TEXT');
    // }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE timers ADD COLUMN last_started_at TEXT');
    }
  }

// 타이머 조회 (user_id와 timer_id를 동시에 확인)
  Future<Map<String, dynamic>?> getTimer(
      String userId, String weekStart) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      'timers',
      where: 'user_id = ? AND week_start = ?',
      whereArgs: [userId, weekStart],
    );

    return result.isNotEmpty ? result.first : null;
  }

  // 타이머 생성
  Future<void> createTimer(Map<String, dynamic> timerData) async {
    final db = await database;
    print('Inserting Timer: $timerData'); // 데이터 로그 출력

    await db.insert('timers', timerData,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
