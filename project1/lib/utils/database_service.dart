import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
      version: 4,
      onCreate: _createDb,
      // onUpgrade: _onUpgrade, // 마이그레이션 처리
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
        last_activity_log_id TEXT,
        is_running INTEGER,
        created_at TEXT,
        last_updated_at TEXT,
        last_started_at TEXT
      )
    ''');

    await db.execute('''
    CREATE TABLE activity_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      activity_log_id TEXT,
      activity_id TEXT,
      timer_id TEXT,
      start_time TEXT,
      end_time TEXT,
      activity_duration INTEGER,
      rest_time INTEGER,
      FOREIGN KEY (activity_id) REFERENCES activity_list(activity_list_id) ON DELETE CASCADE,
      FOREIGN KEY (timer_id) REFERENCES timers(timer_id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE activity_list (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      activity_list_id TEXT,
      user_id TEXT,
      activity_name TEXT,
      activity_icon TEXT,
      created_at TEXT
    )
    ''');
  }

  // // 마이그레이션 코드 추가
  // Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  //   if (oldVersion < 4) {
  //     await db.execute('ALTER TABLE activity_logs ADD COLUMN rest_time INTEGER');
  //     // 필요한 추가 마이그레이션 처리
  //   }
  // }

  // 타이머 생성
  Future<void> createTimer(
      String userId, Map<String, dynamic> timerData) async {
    final db = await database;
    try {
      await db.insert('timers', timerData,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('타이머 생성 중 오류 발생: $e');
    }
  }

  // 특정 타이머 삭제
  Future<void> deleteTimer(String timerId, String userId) async {
    final db = await database;
    try {
      await db.delete(
        'timers',
        where: 'timer_id = ? AND user_id = ?',
        whereArgs: [timerId, userId],
      );
      print('타이머가 삭제되었습니다.');
    } catch (e) {
      print('타이머 삭제 중 오류 발생: $e');
    }
  }

  Future<void> updateTimer(
      String timerId, String userId, Map<String, dynamic> updatedData) async {
    final db = await database;
    try {
      await db.update(
        'timers',
        updatedData,
        where: 'timer_id = ? AND user_id = ?',
        whereArgs: [timerId, userId],
      );
    } catch (e) {
      print('타이머 업데이트 중 오류 발생: $e');
    }
  }

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

  // 기본 활동 리스트 초기화
  Future<void> initializeActivityList(Database db, String userId) async {
    final now = DateTime.now().toUtc();

    // 기본 액티비티 리스트
    List<Map<String, dynamic>> defaultActivityList = [
      {
        'activity_list_id': '${userId}1',
        'user_id': userId,
        'activity_name': '전체',
        'activity_icon': 'category_rounded',
        'created_at': now.toIso8601String(),
      },
      // ... 추가 활동
    ];

    final List<Map<String, dynamic>> result = await db.query(
      'activity_list',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isEmpty) {
      for (var activityList in defaultActivityList) {
        await db.insert('activity_list', activityList);
      }
    }
  }

  Future<void> addActivityList(
      String userId, String activityName, String activityIcon) async {
    final db = await database;
    final uuid = const Uuid().v4();
    String createdAt = DateTime.now().toUtc().toIso8601String();

    try {
      await db.insert('activity_list', {
        'activity_list_id': uuid,
        'user_id': userId,
        'activity_name': activityName,
        'activity_icon': activityIcon,
        'created_at': createdAt,
      });
    } catch (e) {
      print('활동 추가 중 오류 발생: $e');
    }
  }

  Future<void> updateActivityList(String activityListId, String newActivityName,
      String newActivityIcon) async {
    final db = await database;
    try {
      await db.update(
        'activity_list',
        {
          'activity_name': newActivityName,
          'activity_icon': newActivityIcon,
        },
        where: 'activity_list_id = ?',
        whereArgs: [activityListId],
      );
    } catch (e) {
      print('활동 수정 중 오류 발생: $e');
    }
  }

  Future<void> deleteActivity(String activityListId) async {
    final db = await database;
    try {
      await db.delete(
        'activity_list',
        where: 'activity_list_id = ?',
        whereArgs: [activityListId],
      );
    } catch (e) {
      print('활동 삭제 중 오류 발생: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getActivityList(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'activity_list',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getActivityById(
      String activityListId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'activity_list',
      where: 'activity_list_id = ?',
      whereArgs: [activityListId],
    );

    return result;
  }

  Future<String?> getActivityListIdByName(
      String userId, String activityName) async {
    final db = await database;

    final result = await db.query(
      'activity_list',
      where: 'user_id = ? AND activity_name = ?',
      whereArgs: [userId, activityName],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['activity_list_id'] as String;
    }
    return null;
  }

  Future<void> createActivityLog(String activityId, String timerId) async {
    final db = await database;

    final String activityLogId = const Uuid().v4();

    try {
      await db.insert('activity_logs', {
        'activity_log_id': activityLogId,
        'activity_id': activityId,
        'timer_id': timerId,
        'start_time': DateTime.now().toUtc().toIso8601String(),
        'end_time': null,
        'activity_duration': 0,
        'rest_time': 0
      });
    } catch (e) {
      print('활동 로그 생성 중 오류 발생: $e');
    }
  }

  Future<void> updateActivityLog(String? activityLogId,
      {required bool resetEndTime}) async {
    final db = await database;

    if (activityLogId == null || activityLogId.isEmpty) {
      print('activity_log_id가 없습니다.');
      return;
    }

    final log = await db.query(
      'activity_logs',
      where: 'activity_log_id = ?',
      whereArgs: [activityLogId],
      limit: 1,
    );

    if (log.isEmpty) {
      print('로그를 찾을 수 없습니다.');
      return;
    }

    // 트랜잭션 시작
    await db.transaction((txn) async {
      final lastEndTimeString = log.first['end_time'] as String?;
      final lastEndTime = (lastEndTimeString != null)
          ? DateTime.parse(lastEndTimeString).toUtc()
          : null;

      final restTime = lastEndTime != null
          ? DateTime.now().toUtc().difference(lastEndTime).inSeconds
          : 0;

      final existingRestTime = log.first['rest_time'] as int? ?? 0;
      final totalRestTime = existingRestTime + restTime;

      final startTime =
          DateTime.parse(log.first['start_time'] as String).toUtc();
      final endTime = resetEndTime ? null : DateTime.now().toUtc();
      final duration =
          resetEndTime ? null : endTime?.difference(startTime).inSeconds;

      // 업데이트할 데이터 구성
      Map<String, dynamic> updateData = {
        'rest_time': totalRestTime,
        'end_time': endTime?.toIso8601String(),
        'activity_duration': duration,
      };

      if (resetEndTime) {
        updateData['end_time'] = null;
        updateData['activity_duration'] = null;
      }

      await txn.update(
        'activity_logs',
        updateData,
        where: 'activity_log_id = ?',
        whereArgs: [activityLogId],
      );
    });
  }

  Future<Map<String, dynamic>?> getActivityLog(String activityLogId) async {
    final db = await database;

    final result = await db.query(
      'activity_logs',
      where: 'activity_log_id = ?',
      whereArgs: [activityLogId],
    );

    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getLastActivityLog(String timerId) async {
    final db = await database;

    final logs = await db.query(
      'activity_logs',
      where: 'timer_id = ?',
      whereArgs: [timerId],
      orderBy: 'start_time DESC',
      limit: 1,
    );

    return logs.isNotEmpty ? logs.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllActivityLogs() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT activity_logs.*, activity_list.activity_name, activity_list.activity_icon
      FROM activity_logs
      JOIN activity_list
      ON activity_logs.activity_id = activity_list.activity_list_id
    ''');
  }

  Future<void> deleteActivityLog(String activityLogId) async {
    final db = await database;
    try {
      await db.delete(
        'activity_logs',
        where: 'activity_log_id = ?',
        whereArgs: [activityLogId],
      );
    } catch (e) {
      print('활동 로그 삭제 중 오류 발생: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getActivityLogsForCurrentWeek(
      String userId) async {
    final db = await database;

    // 이번 주의 시작일 (UTC 기준)
    DateTime now = DateTime.now().toUtc();
    DateTime weekStartDate =
        now.subtract(Duration(days: now.weekday - 1)); // 월요일 기준으로 주 시작일 계산
    String weekStart = weekStartDate.toIso8601String().split('T').first;

    // 해당 주의 타이머 ID 조회
    final timer = await db.query(
      'timers',
      where: 'user_id = ? AND week_start = ?',
      whereArgs: [userId, weekStart],
      limit: 1,
    );

    if (timer.isEmpty) {
      // 해당 주차의 타이머가 없을 경우 빈 리스트 반환
      return [];
    }

    // 타이머 ID 추출
    final String? timerId = timer.first['timer_id'] as String?;

    // 해당 타이머 ID에 해당하는 활동 로그 조회
    final logs = await db.rawQuery('''
    SELECT activity_logs.*, activity_list.activity_name, activity_list.activity_icon
    FROM activity_logs
    JOIN activity_list
    ON activity_logs.activity_id = activity_list.activity_list_id
    WHERE activity_logs.timer_id = ?
  ''', [timerId]);

    return logs;
  }
}
