import 'dart:io';
import 'package:flutter/material.dart';
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
      version: 3,
      onCreate: _createDb,
      onUpgrade: _onUpgrade, // 마이그레이션 처리
    );
  }

  // 테이블 생성
  Future<void> _createDb(Database db, int version) async {
    print('데이터베이스 초기화 시작');

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
    print('timers 테이블이 생성되었습니다.');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS activity_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      activity_log_id TEXT,
      activity_id TEXT,
      timer_id TEXT,
      start_time TEXT,
      end_time TEXT,
      activity_duration INTEGER
    )
  ''');
    print('activity_logs 테이블이 생성되었습니다.');

    await db.execute('''
    CREATE TABLE activity_list (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      activity_list_id TEXT,       -- 고유 ID
      user_id TEXT,
      activity_name TEXT,      -- 액티비티 이름 (수정 가능)
      activity_icon TEXT,
      created_at TEXT
    )
  ''');
    print('activity_list 테이블이 생성되었습니다.');
  }

  // 타이머 생성
  Future<void> createTimer(Map<String, dynamic> timerData) async {
    final db = await database;
    print('Inserting Timer: $timerData'); // 데이터 로그 출력

    await db.insert('timers', timerData,
        conflictAlgorithm: ConflictAlgorithm.replace);
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

  // 기본 액티비티 리스트
  Future<void> initializeActivitiyList(Database db, String userId) async {
    final now = DateTime.now();

    // 기본 액티비티 리스트
    List<Map<String, dynamic>> defaultActivitiyList = [
      {
        'activity_list_id': '${userId}1',
        'user_id': userId,
        'activity_name': '전체',
        'activity_icon': 'category_rounded',
        'created_at': now.toIso8601String(),
      },
      {
        'activity_list_id': '${userId}2',
        'user_id': userId,
        'activity_name': '공부',
        'activity_icon': 'school_rounded',
        'created_at': now.toIso8601String(),
      },
      {
        'activity_list_id': '${userId}3',
        'user_id': userId,
        'activity_name': '업무',
        'activity_icon': 'work_rounded',
        'created_at': now.toIso8601String(),
      },
      {
        'activity_list_id': '${userId}4',
        'user_id': userId,
        'activity_name': '운동',
        'activity_icon': 'fitness_center_rounded',
        'created_at': now.toIso8601String(),
      },
    ];

    // 이미 데이터가 있는지 확인
// 특정 userId에 해당하는 activity_list가 있는지 확인
    final List<Map<String, dynamic>> result = await db.query(
      'activity_list',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isEmpty) {
      // 데이터베이스가 비어 있을 경우 기본 액티비티 추가
      for (var activityList in defaultActivitiyList) {
        await db.insert('activity_list', activityList);
      }
      print('기본 액티비티가 데이터베이스에 추가되었습니다.');
    }
  }

  Future<void> addActivityList(String activityName, String activityIcon) async {
    final db = await database;
    final uuid = const Uuid().v4(); // 고유 ID 생성
    String userId = 'v3_4'; // 사용자 ID 예시 (실제 앱에서는 유저 ID를 동적으로 받을 수 있음)
    String createdAt = DateTime.now().toIso8601String(); // 현재 시간

    // 데이터 삽입
    await db.insert('activity_list', {
      'activity_list_id': uuid,
      'user_id': userId,
      'activity_name': activityName,
      'activity_icon': activityIcon,
      'created_at': createdAt,
    });
  }

  Future<void> updateActivityList(String activityListId, String newActivityName,
      String newActivityIcon) async {
    final db = await database;

    await db.update(
      'activity_list',
      {
        'activity_name': newActivityName,
        'activity_icon': newActivityIcon,
      },
      where: 'activity_list_id = ?', // activity_list_id를 사용해 업데이트 조건 지정
      whereArgs: [activityListId],
    );

    print('액티비티가 수정되었습니다: $newActivityName, 아이콘: $newActivityIcon');
  }

  Future<void> deleteActivity(String activityListId) async {
    final db = await database;

    // activity_list_id를 기준으로 활동 삭제
    await db.delete(
      'activity_list',
      where: 'activity_list_id = ?',
      whereArgs: [activityListId],
    );
  }

  Future<List<Map<String, dynamic>>> getActivityList(String userId) async {
    final db = await database;
    // userId가 일치하는 activity_list를 가져오는 쿼리
    final List<Map<String, dynamic>> result = await db.query(
      'activity_list',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    print('액티비티 리스트: $result');

    return result;
  }

  Future<String?> getActivityListIdByName(String activityName) async {
    final db = await database;

    // activity_name에 해당하는 activity_list_id 가져오기
    final result = await db.query(
      'activity_list',
      where: 'activity_name = ?',
      whereArgs: [activityName],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['activity_list_id'] as String; // activity_list_id 반환
    }
    return null; // 찾지 못한 경우 null 반환
  }

  Future<void> createActivityLog(String activityId, String timerId) async {
    final db = await database;

    // UUID 생성
    const uuid = Uuid();
    final String activityLogId = uuid.v4(); // 고유 ID 생성

    // 로그 생성
    print('activity_logs 테이블에 데이터 삽입 시도');
    try {
      await db.insert('activity_logs', {
        'activity_log_id': activityLogId, // 생성한 고유 ID 저장
        'activity_id': activityId,
        'timer_id': timerId,
        'start_time': DateTime.now().toIso8601String(),
        'end_time': null,
        'activity_duration': null
      });
      print('데이터 삽입 성공: activity_log_id = $activityLogId');
    } catch (e) {
      print('데이터 삽입 실패: $e');
    }
  }

  Future<void> updateActivityLog(String activityLogId) async {
    final db = await database;

    // 해당 타이머와 마지막 액티비티에 대한 로그 가져오기
    final log = await db.query(
      'activity_logs',
      where: 'activity_log_id = ?',
      whereArgs: [activityLogId],
      limit: 1,
    );

    final startTime = DateTime.parse(log.first['start_time'] as String);
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inSeconds;

    // 로그 업데이트 (종료 시간과 활동 지속 시간)
    await db.update(
      'activity_logs',
      {
        'end_time': endTime.toIso8601String(),
        'activity_duration': duration, // 지속 시간 (초)
      },
      where: 'activity_log_id = ?',
      whereArgs: [activityLogId],
    );
  }

  Future<Map<String, dynamic>?> getActivityLog(String activityLogId) async {
    final db = await database;

    // timer_id에 해당하는 가장 최근 activity_logs 가져오기
    final result = await db.query(
      'activity_logs',
      where: 'activity_log_id = ?',
      whereArgs: [activityLogId],
    );

    // 만약 결과가 비어있지 않으면 첫 번째 로그 반환

    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getLastActivityLog(String timerId) async {
    final db = await database;

    // timer_id에 해당하는 가장 최근 activity_logs 가져오기
    final logs = await db.query(
      'activity_logs',
      where: 'timer_id = ?',
      whereArgs: [timerId],
      orderBy: 'start_time DESC', // 최신 로그가 가장 위로 오도록 내림차순 정렬
      limit: 1, // 가장 최근의 로그 하나만 가져옴
    );

    // 만약 결과가 비어있지 않으면 첫 번째 로그 반환
    return logs.isNotEmpty ? logs.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllActivityLogs() async {
    final db = await database; // 데이터베이스 연결
    // activity_logs와 activity_list를 JOIN하여 activity_name과 관련된 정보를 가져옴
    return await db.rawQuery('''
      SELECT activity_logs.*, activity_list.activity_name, activity_list.activity_icon
      FROM activity_logs
      JOIN activity_list
      ON activity_logs.activity_id = activity_list.activity_list_id
    ''');
  }
}
