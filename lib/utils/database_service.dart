import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DatabaseService();
  /*

      @DATABASE

      database 가져오기
      database 세팅
      database 생성
      database 마이그레이션

  */

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
      version: 1,
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
        current_session_id TEXT,
        week_start TEXT,
        total_seconds INTEGER,
        timer_state TEXT,
        created_at TEXT,
        deleted_at TEXT,
        last_started_at TEXT,
        last_ended_at TEXT,
        last_updated_at TEXT,
        is_deleted INTEGER DEFAULT 0,
        timezone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT,
        timer_id TEXT,
        activity_id TEXT,
        activity_name TEXT,
        activity_icon TEXT,
        activity_color TEXT,
        mode TEXT,
        session_state TEXT,
        start_time TEXT,
        end_time TEXT,
        duration INTEGER,
        target_duration INTEGER,
        original_duration INTEGER,
        created_at TEXT,
        deleted_at TEXT,
        last_updated_at TEXT,
        is_modified INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        is_ended INTEGER DEFAULT 0,
        is_force_terminated INTEGER DEFAULT 0,
        timezone TEXT,
        long_session_flag INTEGER
      ) 
    ''');

    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id TEXT,
        parent_activity_id TEXT,
        activity_name TEXT,
        activity_icon TEXT,
        activity_color TEXT,
        created_at TEXT,
        deleted_at TEXT,
        last_updated_at TEXT,
        last_used_at TEXT,
        is_favorite INTEGER DEFAULT 0,
        is_default INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        sort_order INTEGER,
        favorite_order INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        todo_id TEXT,
        todo_name TEXT,
        todo_detail TEXT,
        priority TEXT,
        activity_id TEXT,
        activity_name TEXT,
        activity_icon TEXT,
        activity_color TEXT,
        created_at TEXT,
        deleted_at TEXT,
        last_updated_at TEXT,
        due_date TEXT,
        position INTEGER,
        is_completed INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // last_sync_at을 저장하는 테이블 생성
    await db.execute('''
      CREATE TABLE sync_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_duration INTEGER,
        last_sync_at TEXT,
        device_info TEXT,
        app_version TEXT,
        is_auto_sync INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 1) {}
    } catch (e) {
      // error log
    }
  }

  /*

    TIMER

  */

  // 타이머 생성
  Future<void> createTimer(Map<String, dynamic> timerData) async {
    // timerData를 입력받아서 db에 생성
    logger.d('[databaseService] create Timer');
    final db = await database;

    try {
      // 해당 주차에 이미 타이머가 있는지 확인
      final weekStart = timerData['week_start'];
      final existingTimers = await db.query(
        'timers',
        where: 'week_start = ? AND is_deleted = 0',
        whereArgs: [weekStart],
        limit: 1,
      );

      if (existingTimers.isNotEmpty) return; // 이미 해당 주차 타이머가 있다면 return. 중복 생성 방지

      await db.insert(
        'timers',
        timerData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      ); // 충돌할 경우 대체
    } catch (e) {
      logger.e('''
        [databaseService]
        - 위치 : createTimer
        - 오류 유형: ${e.runtimeType}
        - 메시지: ${e.toString()}
      ''');
    }
  }

  Future<Map<String, dynamic>?> getTimer(String weekStart) async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'timers',
        where: 'week_start = ? AND is_deleted = 0',
        whereArgs: [weekStart],
      );

      if (result.isNotEmpty) {
        return result.first;
      } else {
        return null;
      }
    } catch (e) {
      // error log
      return null;
    }
  }

  // 타이머 업데이트
  Future<void> updateTimer(String timerId, Map<String, dynamic> updatedData) async {
    final db = await database;
    String now = DateTime.now().toUtc().toIso8601String();

    updatedData['last_updated_at'] = now; // 마지막 업데이트 시간 설정

    try {
      final updatedRows = await db.update(
        'timers',
        updatedData,
        where: 'timer_id = ?',
        whereArgs: [timerId],
      );

      if (updatedRows == 0) {
        // error log
      } else {
        // error log
      }
    } catch (e) {
      // error log
    }
  }

// 특정 타이머 삭제 (소프트 딜리션)
  Future<void> deleteTimer(String timerId) async {
    final db = await database;
    String now = DateTime.now().toUtc().toIso8601String();

    try {
      final updatedRows = await db.update(
        'timers',
        {
          'is_deleted': 1,
          'deleted_at': now,
          'last_updated_at': now,
        },
        where: 'timer_id = ?',
        whereArgs: [timerId],
      );

      if (updatedRows == 0) {
        // error log
      } else {
        // error log
      }
    } catch (e) {
      // error log
    }
  }

  /*

      @Activity

      Activity 생성
      Activities 가져오기
      Activity 가져오기
      Default Activity 가져오기
      Activity 수정
      Activity 삭제
      Activity Name 중복 체크

  */

  // 활동 추가
  Future<void> addActivity({
    required String activityName,
    required String activityIcon,
    required String activityColor,
    required bool isDefault,
    required String? parentActivityId,
  }) async {
    final db = await database;
    final activityId = const Uuid().v4();
    String now = DateTime.now().toUtc().toIso8601String();

    final result = await db.rawQuery("SELECT MAX(sort_order) as maxSortOrder FROM activities WHERE is_deleted = 0");
    int sortOrder = 1;
    if (result.isNotEmpty && result.first["maxSortOrder"] != null) {
      // 조회된 최대값에 1을 더해 다음 순서를 지정합니다.
      sortOrder = (result.first["maxSortOrder"] as int) + 1;
    }

    final activity = {
      'activity_id': activityId,
      'parent_activity_id': parentActivityId,
      'activity_name': activityName,
      'activity_icon': activityIcon,
      'activity_color': activityColor,
      'created_at': now,
      'deleted_at': null,
      'last_updated_at': now,
      'last_used_at': null,
      'is_favorite': 0,
      'is_default': isDefault ? 1 : 0,
      'is_deleted': 0,
      'sort_order': sortOrder,
      'favorite_order': null,
    };

    try {
      await db.insert(
        'activities',
        activity,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // error log
    }
  }

  Future<List<Map<String, dynamic>>> getActivities() async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'activities',
        where: 'is_deleted = ?',
        whereArgs: [0],
      );

      return result;
    } catch (e) {
      // error log
      return [];
    }
  }

  // 활동 업데이트
  Future<void> updateActivity({
    required String activityId,
    String? newActivityName,
    String? newActivityIcon,
    String? newActivityColor,
    int? newIsFavorite,
    bool? isUsed,
  }) async {
    final db = await database;
    String now = DateTime.now().toUtc().toIso8601String();

    final Map<String, dynamic> update = {};

    if (newActivityName != null) {
      update['activity_name'] = newActivityName;
    }
    if (newActivityIcon != null) {
      update['activity_icon'] = newActivityIcon;
    }
    if (newActivityColor != null) {
      update['activity_color'] = newActivityColor;
    }
    // 즐겨찾기 상태 변경 시 처리
    if (newIsFavorite != null) {
      update['is_favorite'] = newIsFavorite;

      // 즐겨찾기 해제(0)인 경우 favorite_order를 null로 설정
      if (newIsFavorite == 0) {
        update['favorite_order'] = null;
      }
      // 즐겨찾기 추가(1)인 경우 새로운 favorite_order 값 부여
      else if (newIsFavorite == 1) {
        // 현재 최대 favorite_order 값을 조회하여 +1 부여
        try {
          final maxOrderResult =
              await db.rawQuery('SELECT MAX(favorite_order) as max_order FROM activities WHERE is_favorite = 1 AND is_deleted = 0');

          int maxOrder = 0;
          if (maxOrderResult.isNotEmpty && maxOrderResult[0]['max_order'] != null) {
            maxOrder = maxOrderResult[0]['max_order'] as int;
          }

          // 최대값 + 1로 새 순서 설정
          update['favorite_order'] = maxOrder + 1;
          print('새로운 즐겨찾기 순서 할당: ${maxOrder + 1}');
        } catch (e) {
          print('즐겨찾기 순서 조회 오류: $e');
          // 오류 시 기본값 할당
          update['favorite_order'] = 999;
        }
      }
    }
    // isUsed 플래그가 true이면 last_used_at 업데이트
    if (isUsed == true) {
      update['last_used_at'] = now;
    }

    // 업데이트할 필드가 없으면 불필요한 작업을 피하기 위해 종료
    if (update.isEmpty) {
      return;
    }

    // 마지막 업데이트 시간 갱신
    update['last_updated_at'] = now;

    try {
      // 데이터 업데이트
      final rowsAffected = await db.update(
        'activities',
        update,
        where: 'activity_id = ? AND is_deleted = ?',
        whereArgs: [activityId, 0],
      );

      // 업데이트가 적용되지 않은 경우 처리
      if (rowsAffected == 0) {
        // error log
      }
    } catch (e) {
      // error log
    }
  }

  Future<void> updateActivityOrder({
    required String activityId,
    int? newSortOrder,
    int? newFavoriteOrder,
  }) async {
    final db = await database;
    String now = DateTime.now().toUtc().toIso8601String();

    final update = {
      'sort_order': newSortOrder,
      'last_updated_at': now,
    };

    if (newFavoriteOrder != null) {
      update['favorite_order'] = newFavoriteOrder;
    }

    try {
      final rowsAffected = await db.update(
        'activities',
        update,
        where: 'activity_id = ? AND is_deleted = ?',
        whereArgs: [activityId, 0],
      );

      if (rowsAffected == 0) {
        // 업데이트가 적용되지 않은 경우에 대한 에러 처리
      }
    } catch (e) {
      // 에러 로깅 처리
    }
  }

  // 활동 삭제 (소프트 딜리션)
  Future<void> deleteActivity(String activityId) async {
    final db = await database;
    String now = DateTime.now().toUtc().toIso8601String();

    try {
      // 활동 삭제 (소프트 딜리션)
      final rowsAffected = await db.update(
        'activities',
        {
          'is_deleted': 1,
          'deleted_at': now,
          'last_updated_at': now,
        },
        where: 'activity_id = ?',
        whereArgs: [activityId],
      );

      // 삭제가 적용되지 않은 경우 처리
      if (rowsAffected == 0) {
        // error log
      }
    } catch (e) {
      // error log
    }
  }

// isActivityNameDuplicate 메서드 추가
  Future<bool> isActivityNameDuplicate(String activityName) async {
    final db = await database; // 데이터베이스 객체 가져오기

    try {
      // 중복 확인 쿼리 실행
      final List<Map<String, dynamic>> result = await db.query(
        'activities',
        where: 'activity_name = ? AND is_deleted = 0',
        whereArgs: [activityName],
      );
      return result.isNotEmpty; // 중복 여부 반환
    } catch (e) {
      // error log
      return false; // 중복 확인 불가능한 경우 false 반환
    }
  }

  /*

      @todo

  */

  Future<List<Map<String, dynamic>>> getTodos() async {
    final db = await database;

    // 삭제되지 않았고 완료되지 않은 항목만 조회
    return await db.query(
      'todos',
      where: 'is_deleted = ? AND is_completed = ?',
      whereArgs: [0, 0],
      orderBy: 'position DESC',
    );
  }

  Future<void> createTodo(Map<String, dynamic> todo) async {
    final db = await database;

    // position 값 가져오기
    final maxPosition = await _getMaxPosition();

    final todoId = const Uuid().v4();

    await db.insert('todos', {
      'todo_id': todoId,
      'todo_name': todo['todo_name'],
      'todo_detail': todo['todo_detail'],
      'priority': todo['priority'],
      'activity_id': todo['activity_id'],
      'activity_name': todo['activity_name'],
      'activity_icon': todo['activity_icon'],
      'activity_color': todo['activity_color'],
      'created_at': DateTime.now().toIso8601String(),
      'deleted_at': null,
      'last_updated_at': DateTime.now().toIso8601String(),
      'due_date': todo['due_date'],
      'position': maxPosition + 10000,
      'is_completed': 0,
      'is_deleted': 0,
    });
  }

  // 3. 드래그로 순서 변경
  Future<void> reorderTodo(int oldIndex, int newIndex) async {
    final db = await database;

    try {
      // 읽기 전용 리스트 복제
      final todos = List<Map<String, dynamic>>.from(await getTodos());

      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final item = todos.removeAt(oldIndex);
      todos.insert(newIndex, item);

      // 트랜잭션으로 일괄 업데이트
      await db.transaction((txn) async {
        for (int i = 0; i < todos.length; i++) {
          await txn.update(
            'todos',
            {
              'position': (todos.length - i) * 10000, // 역순으로 높은 position 값 할당
              'last_updated_at': DateTime.now().toIso8601String(),
            },
            where: 'todo_id = ?',
            whereArgs: [todos[i]['todo_id']],
          );
        }
      });
    } catch (e) {
      // error log
    }
  }

  // 4. Todo 삭제 (소프트 삭제)
  Future<void> deleteTodo(String todoId) async {
    final db = await database;

    await db.update(
      'todos',
      {'is_deleted': 1, 'deleted_at': DateTime.now().toIso8601String(), 'last_updated_at': DateTime.now().toIso8601String()},
      where: 'todo_id = ?',
      whereArgs: [todoId],
    );
  }

  // 5. Todo 완료 상태 변경
  Future<void> toggleComplete(String todoId, bool isCompleted) async {
    final db = await database;

    await db.update(
      'todos',
      {'is_completed': isCompleted ? 1 : 0, 'last_updated_at': DateTime.now().toIso8601String()},
      where: 'todo_id = ?',
      whereArgs: [todoId],
    );
  }

  // 6. Todo 수정
  Future<void> updateTodo(String todoId, Map<String, dynamic> updates) async {
    final db = await database;

    await db.update(
      'todos',
      {...updates, 'last_updated_at': DateTime.now().toIso8601String()},
      where: 'todo_id = ?',
      whereArgs: [todoId],
    );
  }

  // 헬퍼 메서드: 최대 position 값 조회
  Future<int> _getMaxPosition() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT MAX(COALESCE(position, 0)) as maxPosition FROM todos WHERE is_deleted = ?',
      [0],
    );

    // Object를 int로 변환
    return (result.first['maxPosition'] as num?)?.toInt() ?? 0;
  }

  /*

      @Session

      Session 생성
      Session 가져오기


  */

  // 세션 생성
  Future<void> createSession(
      {required String sessionId,
      required String timerId,
      required String activityId,
      required String activityName,
      required String activityIcon,
      required String activityColor,
      required String mode,
      int? targetDuration}) async {
    final db = await database;

    final now = DateTime.now().toUtc().toIso8601String();
    final timezone = DateTime.now().timeZoneName;

    try {
      final session = {
        'session_id': sessionId,
        'timer_id': timerId,
        'activity_id': activityId,
        'activity_name': activityName,
        'activity_icon': activityIcon,
        'activity_color': activityColor,
        'mode': mode,
        'session_state': 'RUNNING',
        'start_time': now,
        'end_time': null,
        'duration': 0,
        'target_duration': targetDuration,
        'original_duration': null,
        'created_at': now,
        'deleted_at': null,
        'last_updated_at': now,
        'is_modified': 0,
        'is_deleted': 0,
        'is_ended': 0,
        'timezone': timezone,
        'long_session_flag': 0,
      };

      await db.insert('sessions', session);
    } catch (e) {
      // error log
    }
  }

  Future<void> updateSession({
    required sessionId,
    required seconds,
  }) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await db.transaction((txn) async {
        Map<String, dynamic> updateData = {
          'duration': seconds,
          'last_updated_at': now,
        };

        await txn.update(
          'sessions',
          updateData,
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
      });
    } catch (e) {
      // error log
    }
  }

  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    final db = await database;

    try {
      final result = await db.query(
        'sessions',
        where: 'session_id = ? AND is_deleted = 0',
        whereArgs: [sessionId],
      );

      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      // error log
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSessionsWithinDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await database;
      // ISO 문자열 생성 (UTC 기준)
      String startStr = startDate.toIso8601String();
      String endStr = endDate.toIso8601String();

      final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT *      
      FROM sessions
      WHERE start_time >= ? 
        AND start_time < ?
        AND is_deleted = 0
    ''', [startStr, endStr]);

      return results;
    } catch (e) {
      print("Error in getSessionsWithinDateRange: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSessionsWithinDateRangeAndActivityId({
    required DateTime startDate,
    required DateTime endDate,
    required String activityId,
  }) async {
    try {
      final db = await database;
      // ISO 문자열 생성 (UTC 기준)
      String startStr = startDate.toIso8601String();
      String endStr = endDate.toIso8601String();

      final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT *      
      FROM sessions
      WHERE start_time >= ? 
        AND start_time < ?
        AND is_deleted = 0
        AND activity_id = ?
    ''', [startStr, endStr, activityId]);

      return results;
    } catch (e) {
      print("Error in getSessionsWithinDateRangeAndActivityId: $e");
      return [];
    }
  }

  Future<void> endSession({
    required String sessionId,
    required String endTime,
    required int duration,
  }) async {
    logger.d('### dbService ### : endSession({$sessionId, $endTime, $duration})');
    final db = await database;
    final now = DateTime.now().toUtc();

    try {
      await db.transaction((txn) async {
        final updateData = {
          'last_updated_at': now.toIso8601String(),
          'long_session_flag': duration >= 3600 ? 1 : 0,
          'end_time': endTime,
          'duration': duration,
          'original_duration': duration,
          'session_state': 'ENDED',
          'is_ended': 1,
        };

        await txn.update(
          'sessions',
          updateData,
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
      });
    } catch (e) {
      // error log
    }
  }

  Future<void> terminateSession({required String sessionId}) async {
    logger.d('### dbService ### : terminateSession({$sessionId})');
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await db.transaction((txn) async {
        final updateData = {
          'last_updated_at': now,
          'end_time': now,
          'session_state': 'ENDED',
          'is_ended': 1,
          'is_force_terminated': 1,
        };

        await txn.update(
          'sessions',
          updateData,
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
      });
    } catch (e) {
      // error log
    }
  }

  Future<void> modifySession({
    required String sessionId,
    required int newDuration,
    required String activityId,
    required String activityName,
    required String activityColor,
    required String activityIcon,
  }) async {
    final db = await database;

    // 세션 데이터 조회
    final session = await db.query(
      'sessions',
      where: 'session_id = ? AND is_deleted = 0',
      whereArgs: [sessionId],
      limit: 1,
    );

    await db.transaction((txn) async {
      try {
        final now = DateTime.now().toUtc().toIso8601String();

        // 기존 데이터 가져오기
        final existingDuration = (session.first['duration'] ?? 0) as int;

        // 세션 업데이트
        final updateData = {
          'duration': newDuration,
          'original_duration': existingDuration,
          'last_updated_at': now,
          'is_modified': 1,
          'activity_id': activityId,
          'activity_name': activityName,
          'activity_color': activityColor,
          'activity_icon': activityIcon,
        };

        await txn.update(
          'sessions',
          updateData,
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
      } catch (e) {
        // error log
      }
    });
  }

  // 세션 삭제 (소프트 딜리션)
  Future<void> deleteSession(String sessionId) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      final result = await db.update(
        'sessions',
        {
          'is_deleted': 1,
          'deleted_at': now,
          'last_updated_at': now,
        },
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    } catch (e) {
      // error log
    }
  }
}
