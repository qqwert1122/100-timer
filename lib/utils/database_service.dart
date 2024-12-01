import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스 생성

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
      version: 6,
      onCreate: _createDb,
      onUpgrade: _onUpgrade, // 마이그레이션 처리
    );
  }

  // 테이블 생성
  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT,
        user_name TEXT,
        profile_image TEXT,
        created_at TEXT,
        last_logged_in TEXT,
        verified_method TEXT,
        role TEXT,
        total_seconds INTEGER,
        preference TEXT,
        UNIQUE (uid)
      )
    ''');

    await db.execute('''
      CREATE TABLE timers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT,
        timer_id TEXT,
        week_start TEXT,
        total_seconds INTEGER,
        remaining_seconds INTEGER,
        last_session_id TEXT,
        is_running INTEGER,
        created_at TEXT,
        deleted_at TEXT,
        last_started_at TEXT,
        last_ended_at TEXT,
        last_updated_at TEXT,
        is_deleted INTEGER DEFAULT 0,
        UNIQUE (uid, week_start)
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT,
        session_id TEXT,
        timer_id TEXT,
        activity_id TEXT,
        start_time TEXT,
        end_time TEXT,
        session_duration INTEGER,
        rest_time INTEGER,
        created_at TEXT,
        deleted_at TEXT,
        last_updated_at TEXT,
        is_updated INTEGER,
        is_deleted INTEGER DEFAULT 0,    
        FOREIGN KEY (activity_id) REFERENCES activities(activity_id) ON DELETE NO ACTION,
        FOREIGN KEY (timer_id) REFERENCES timers(timer_id) ON DELETE CASCADE
      ) 
    ''');

    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT,
        activity_id TEXT,
        activity_name TEXT,
        activity_icon TEXT,
        activity_color TEXT,
        created_at TEXT,
        deleted_at TEXT,
        last_updated_at TEXT,
        is_default INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE errors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT,
        created_at TEXT,
        error_message TEXT,
        error_action TEXT
      )
    ''');

    // last_sync_at을 저장하는 테이블 생성
    await db.execute('''
      CREATE TABLE sync_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_sync_at TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 6) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sync_info (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            last_sync_at TEXT
          )
        ''');
        print('sync_info table created successfully');
      }
    } catch (e) {
      print('error : Can not upgrade DB, $e');
    }
  }

  // last_sync_at 가져오기
  Future<String?> getLastSyncAt() async {
    final db = await database;
    final result = await db.query(
      'sync_info',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['last_sync_at'] as String?;
    }
    return null;
  }

  // last_sync_at 업데이트
  Future<void> updateLastSyncAt(String syncAt) async {
    final db = await database;
    await db.insert(
      'sync_info',
      {'last_sync_at': syncAt},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 유저데이터 생성
  Future<void> createUser(String userId, Map<String, dynamic> userData) async {
    final db = await database;
    String now = DateTime.now().toUtc().toIso8601String();

    try {
      await db.insert('users', userData, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      final error = {
        'uid': userId,
        'created_at': now,
        'error_message': e.toString(),
        'error_action': '유저 생성 중',
      };
      await db.insert('errors', error);
    }
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final db = await database; // 데이터베이스 객체 가져오기

    // 쿼리 실행
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );

    // 결과 반환
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateUserTotalSeconds(String userId, int totalSeconds) async {
    final db = await database;
    String now = DateTime.now().toUtc().toIso8601String();

    try {
      await db.update(
        'users',
        {
          'total_seconds': totalSeconds,
          'last_updated_at': now,
        },
        where: 'uid = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      final error = {
        'uid': userId,
        'created_at': now,
        'error_message': e.toString(),
        'error_action': 'total_seconds 업데이트 중',
      };
      await db.insert('errors', error);
    }
  }

  Future<Map<String, dynamic>> fetchOrDownloadUser(String uid) async {
    // 데이터베이스에서 사용자 데이터 검색
    final user = await getUser(uid);

    if (user != null) {
      return user; // 로컬 데이터 반환
    } else {
      print('User not found locally. Downloading from server...');

      // 서버에서 사용자 데이터를 다운로드하는 함수 호출
      await downloadDataFromServer(uid);

      // 서버에서 받은 데이터를 로컬 데이터베이스에 저장한 후 다시 검색
      final newUser = await getUser(uid);

      if (newUser != null) {
        print('User successfully downloaded and saved: ${newUser['user_name']}');
        return newUser; // 다운로드된 데이터 반환
      } else {
        throw Exception('Failed to fetch user data from server.');
      }
    }
  }

  // 동기화
  Future<void> syncDataWithServer(String userId) async {
    await uploadDataToServer(userId);
    await downloadDataFromServer(userId);

    // 동기화 후 last_sync_at 업데이트
    String now = DateTime.now().toUtc().toIso8601String();
    await updateLastSyncAt(now);
    print('Data synchronized successfully at $now');
  }

  // 동기화 데이터 업로드
  Future<void> uploadDataToServer(String userId) async {
    final db = await database;
    final firestore = FirebaseFirestore.instance;
    String now = DateTime.now().toUtc().toIso8601String();
    String syncId = now.replaceAll(RegExp(r'[:-]|\.\d{3}'), ''); // ':'와 '-' 및 밀리초 제거

    // 마지막 동기화 시점 가져오기
    String lastSyncAt = await getLastSyncAt() ?? DateTime(1970).toUtc().toIso8601String();

    // 변경된 활동 데이터 가져오기
    final activities = await db.query(
      'activities',
      where: 'uid = ? AND (last_updated_at > ? OR created_at > ? OR last_updated_at IS NULL)',
      whereArgs: [userId, lastSyncAt, lastSyncAt],
    );

    // 변경된 타이머 데이터 가져오기
    final timers = await db.query(
      'timers',
      where: 'uid = ? AND (last_updated_at > ? OR created_at > ? OR last_updated_at IS NULL)',
      whereArgs: [userId, lastSyncAt, lastSyncAt],
    );

    // 변경된 세션 데이터 가져오기
    final sessions = await db.query(
      'sessions',
      where: 'uid = ? AND (last_updated_at > ? OR created_at > ? OR last_updated_at IS NULL)',
      whereArgs: [userId, lastSyncAt, lastSyncAt],
    );

    // 변경된 데이터가 없으면 업로드하지 않음
    if (activities.isEmpty && timers.isEmpty && sessions.isEmpty) {
      print('No changes to upload.');
      return;
    }

    // 데이터 구조 생성
    Map<String, dynamic> data = {
      'uid': userId,
      'sync_id': syncId,
      'synced_at': now,
      'data': {
        'activities': {for (var activity in activities) activity['activity_id']: activity},
        'timers': {for (var timer in timers) timer['timer_id']: timer},
        'sessions': {for (var session in sessions) session['session_id']: session},
      },
    };

    List<Map<String, dynamic>> chunks = splitDataIntoChunks(data);
    for (int i = 0; i < chunks.length; i++) {
      String chunkId = '${userId}_sync_chunk_${DateTime.now().millisecondsSinceEpoch}_$i';
      await _firestore.collection('user_sync_data').doc(chunkId).set({
        'chunk_index': i,
        'total_chunks': chunks.length,
        'user_id': userId,
        'data': chunks[i],
        'synced_at': now,
      });
      print('Uploaded chunk $i/${chunks.length}');
    }
  }

  // firestore 1MB 업로드 제한을 고려하여 업로드 데이터 분할
  List<Map<String, dynamic>> splitDataIntoChunks(Map<String, dynamic> data) {
    const int maxChunkSize = 950 * 1024;
    List<Map<String, dynamic>> chunks = [];
    Map<String, dynamic> currentChunk = {};
    int currentChunkSize = 0;

    data['data'].forEach((key, value) {
      final encodedItem = utf8.encode(jsonEncode({key: value}));
      final itemSize = encodedItem.length;

      if (currentChunkSize + itemSize > maxChunkSize) {
        chunks.add(currentChunk);
        currentChunk = {};
        currentChunkSize = 0;
      }

      currentChunk[key] = value;
      currentChunkSize += itemSize;
    });

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }

    return chunks;
  }

  Future<void> downloadDataFromServer(String userId) async {
    final firestore = FirebaseFirestore.instance;

    // 마지막 동기화 시점 가져오기
    String? lastSyncAt = await getLastSyncAt();

    Query query = firestore.collection('user_sync_data').where('user_id', isEqualTo: userId).orderBy('synced_at', descending: false);

    if (lastSyncAt != null) {
      query = query.where('synced_at', isGreaterThan: lastSyncAt);
    }

    final querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        final syncData = doc.data() as Map<String, dynamic>?; // 타입 캐스팅 추가
        if (syncData != null && syncData.containsKey('data')) {
          final data = syncData['data'] as Map<String, dynamic>?; // 타입 캐스팅 추가
          if (data != null) {
            await mergeDataFromServer(data);
            print('Data merged from server sync_id: ${syncData['sync_id']}');
          } else {
            print('Skipped sync_id: ${syncData['sync_id']} due to null data.');
          }
        } else {
          print('Skipped document with ID: ${doc.id} due to missing data field.');
        }
      }
    } else {
      print('No new sync data found on server.');
    }
  }

  Future<void> mergeDataFromServer(Map<String, dynamic> data) async {
    // 'activities' 처리
    if (data['activities'] is Map<String, dynamic>) {
      for (var activityData in (data['activities'] as Map<String, dynamic>).values) {
        await mergeActivityData(activityData);
      }
    }

    // 'timers' 처리
    if (data['timers'] is Map<String, dynamic>) {
      for (var timerData in (data['timers'] as Map<String, dynamic>).values) {
        await mergeTimerData(timerData);
      }
    }

    // 'sessions' 처리
    if (data['sessions'] is Map<String, dynamic>) {
      for (var sessionData in (data['sessions'] as Map<String, dynamic>).values) {
        await mergeSessionData(sessionData);
      }
    }
  }

  Future<void> mergeActivityData(Map<String, dynamic> activityData) async {
    final db = await database;
    final existing = await db.query('activities', where: 'activity_id = ?', whereArgs: [activityData['activity_id']]);
    final now = DateTime.now().toUtc().toIso8601String(); // 현재 시간 추가

    if (existing.isNotEmpty) {
      final existingUpdatedAt = existing.first['last_updated_at'] ?? existing.first['created_at'];
      final newUpdatedAt = activityData['last_updated_at'] ?? activityData['created_at'];
      if (newUpdatedAt.compareTo(existingUpdatedAt) > 0) {
        activityData['last_updated_at'] = now; // 최신 업데이트 시간 추가
        await db.update('activities', activityData, where: 'activity_id = ?', whereArgs: [activityData['activity_id']]);
      }
    } else {
      activityData['last_updated_at'] = now; // 생성 시에도 추가
      await db.insert('activities', activityData, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> mergeTimerData(Map<String, dynamic> timerData) async {
    final db = await database;
    final existing = await db.query('timers', where: 'timer_id = ?', whereArgs: [timerData['timer_id']]);
    final now = DateTime.now().toUtc().toIso8601String(); // 현재 시간 추가

    if (existing.isNotEmpty) {
      final existingUpdatedAt = existing.first['last_updated_at'] ?? existing.first['created_at'];
      final newUpdatedAt = timerData['last_updated_at'] ?? timerData['created_at'];
      if (newUpdatedAt.compareTo(existingUpdatedAt) > 0) {
        timerData['last_updated_at'] = now; // 최신 업데이트 시간 추가
        await db.update('timers', timerData, where: 'timer_id = ?', whereArgs: [timerData['timer_id']]);
      }
    } else {
      timerData['last_updated_at'] = now; // 생성 시에도 추가
      await db.insert('timers', timerData, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> mergeSessionData(Map<String, dynamic> sessionData) async {
    final db = await database;
    final existing = await db.query('sessions', where: 'session_id = ?', whereArgs: [sessionData['session_id']]);
    final now = DateTime.now().toUtc().toIso8601String(); // 현재 시간 추가

    if (existing.isNotEmpty) {
      final existingUpdatedAt = existing.first['last_updated_at'] ?? existing.first['created_at'];
      final newUpdatedAt = sessionData['last_updated_at'] ?? sessionData['created_at'];
      if (newUpdatedAt.compareTo(existingUpdatedAt) > 0) {
        sessionData['last_updated_at'] = now; // 최신 업데이트 시간 추가
        await db.update('sessions', sessionData, where: 'session_id = ?', whereArgs: [sessionData['session_id']]);
      }
    } else {
      sessionData['last_updated_at'] = now; // 생성 시에도 추가
      await db.insert('sessions', sessionData, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // 타이머 생성
  Future<void> createTimer(String userId, Map<String, dynamic> timerData) async {
    final db = await database;
    String now = DateTime.now().toUtc().toIso8601String();

    try {
      await db.insert('timers', timerData, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      final error = {
        'uid': timerData['uid'],
        'created_at': now,
        'error_message': e.toString(),
        'error_action': '타이머 생성 중',
      };
      await db.insert('errors', error);
    }
  }

  // 특정 타이머 삭제 (소프트 딜리션) : 디바이스에만 적용
  Future<void> deleteTimer(String timerId, String userId) async {
    String now = DateTime.now().toUtc().toIso8601String();

    final db = await database;
    try {
      await db.update(
        'timers',
        {
          'is_deleted': 1,
          'deleted_at': now,
          'last_updated_at': now,
        },
        where: 'timer_id = ? AND uid = ?',
        whereArgs: [timerId, userId],
      );
    } catch (e) {
      final _e = {
        'uid': userId,
        'created_at': now,
        'error_message': e.toString(),
        'error_action': '타이머 삭제 중',
      };
      await db.insert('errors', _e);
    }
  }

  // 타이머 업데이트 (로컬 디바이스에만 적용)
  Future<void> updateTimer(String timerId, String userId, Map<String, dynamic> updatedData) async {
    String now = DateTime.now().toUtc().toIso8601String();
    updatedData['last_updated_at'] = now;

    final db = await database;
    try {
      await db.update(
        'timers',
        updatedData,
        where: 'timer_id = ? AND uid = ?',
        whereArgs: [timerId, userId],
      );
    } catch (e) {
      final _e = {
        'uid': userId,
        'created_at': now,
        'error_message': e.toString(),
        'error_action': '타이머 업데이트 중',
      };
      await db.insert('errors', _e);
    }
  }

  Future<Map<String, dynamic>?> getTimer(String userId, String weekStart) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      'timers',
      where: 'uid = ? AND week_start = ? AND is_deleted = 0',
      whereArgs: [userId, weekStart],
    );

    return result.isNotEmpty ? result.first : null;
  }

  // 활동 추가
  Future<void> addActivity(String userId, String activityName, String activityIcon, String activityColor, bool isDefault) async {
    final db = await database;
    print(db); // null인지 확인

    final activityId = const Uuid().v4();
    String now = DateTime.now().toUtc().toIso8601String();
    final activity = {
      'uid': userId,
      'activity_id': activityId,
      'activity_name': activityName,
      'activity_icon': activityIcon,
      'activity_color': activityColor,
      'created_at': now,
      'deleted_at': null,
      'last_updated_at': now,
      'is_default': isDefault ? 1 : 0,
      'is_deleted': 0,
    };
    try {
      await db.insert('activities', activity, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      final _e = {
        'uid': userId,
        'created_at': now,
        'error_message': e.toString(),
        'error_action': '활동 추가 중',
      };
      await db.insert('errors', _e);
    }
  }

  // 활동 업데이트
  Future<void> updateActivity(
      String userId, String activityId, String newActivityName, String newActivityIcon, String newActivityColor) async {
    final db = await database;
    String now = DateTime.now().toUtc().toIso8601String();
    final update = {
      'activity_name': newActivityName,
      'activity_icon': newActivityIcon,
      'activity_color': newActivityColor,
      'last_updated_at': now,
    };
    try {
      await db.update(
        'activities',
        update,
        where: 'activity_id = ?',
        whereArgs: [activityId],
      );
    } catch (e) {
      final _e = {
        'uid': userId,
        'created_at': now,
        'error_message': e.toString(),
        'error_action': '활동 수정 중',
      };
      await db.insert('errors', _e);
    }
  }

  // 활동 삭제 (소프트 딜리션)
  Future<void> deleteActivity(String userId, String activityId) async {
    final db = await database;
    String now = DateTime.now().toUtc().toIso8601String();

    try {
      await db.update(
        'activities',
        {
          'is_deleted': 1,
          'deleted_at': now,
          'last_updated_at': now,
        },
        where: 'activity_id = ?',
        whereArgs: [activityId],
      );
    } catch (e) {
      final _e = {
        'uid': userId,
        'created_at': now,
        'error_message': e.toString(),
        'error_action': '활동 삭제 중',
      };
      await db.insert('errors', _e);
    }
  }

  Future<List<Map<String, dynamic>>> getActivities(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'activities',
      where: 'uid = ? AND is_deleted = 0',
      whereArgs: [userId],
    );

    return result;
  }

  Future<Map<String, dynamic>?> getDefaultActivity(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'activities',
      where: 'uid = ? AND is_deleted = 0 AND is_default = 1',
      whereArgs: [userId],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getActivityById(String activityId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'activities',
      where: 'activity_id = ? AND is_deleted = 0',
      whereArgs: [activityId],
    );
    return result;
  }

  // isActivityNameDuplicate 메서드 추가
  Future<bool> isActivityNameDuplicate(String userId, String activityName) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'activities',
      where: 'uid = ? AND activity_name = ? AND is_deleted = 0',
      whereArgs: [userId, activityName],
    );
    return result.isNotEmpty;
  }

  // 세션 생성
  Future<void> createSession(String userId, String activityId, String timerId, String sessionId) async {
    final db = await database;

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      final _session = {
        'uid': userId,
        'session_id': sessionId,
        'timer_id': timerId,
        'activity_id': activityId,
        'start_time': now,
        'end_time': null,
        'session_duration': null,
        'rest_time': 0,
        'is_updated': 0,
        'is_deleted': 0,
        'created_at': now,
        'deleted_at': null,
        'last_updated_at': now,
      };
      await db.insert('sessions', _session);
    } catch (e) {
      final _e = {
        'uid': userId,
        'created_at': now,
        'error_message': e.toString(),
        'error_action': '세션 생성 중',
      };
      await db.insert('errors', _e);
    }
  }

  // 세션 업데이트 (로컬 디바이스에만 적용)
  Future<void> updateSession(String userId, String? sessionId, {required bool resetEndTime}) async {
    final db = await database;

    if (sessionId == null || sessionId.isEmpty) {
      print('sessionId가 없습니다.');
      return;
    }

    final log = await db.query(
      'sessions',
      where: 'session_id = ? AND is_deleted = 0',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (log.isEmpty) {
      print('session을 찾을 수 없습니다.');
      return;
    }

    // 트랜잭션 시작
    await db.transaction((txn) async {
      final now = DateTime.now().toUtc();

      final lastEndTimeString = log.first['end_time'] as String?;
      final lastEndTime = (lastEndTimeString != null) ? DateTime.parse(lastEndTimeString).toUtc() : null;

      // 휴게시간을 최대 11분(660초)으로 제한
      final restTime = lastEndTime != null ? min(now.difference(lastEndTime).inSeconds, 660) : 0;

      final existingRestTime = log.first['rest_time'] as int? ?? 0;
      final totalRestTime = existingRestTime + restTime;

      final startTime = DateTime.parse(log.first['start_time'] as String).toUtc();
      final endTime = resetEndTime ? null : now;
      final duration = now.difference(startTime).inSeconds - totalRestTime;

      // 업데이트할 데이터 구성
      Map<String, dynamic> updateData = {
        'rest_time': totalRestTime,
        'end_time': endTime?.toIso8601String(),
        'session_duration': duration,
        'last_updated_at': now.toIso8601String(),
      };

      if (resetEndTime) {
        updateData['end_time'] = null;
        updateData['session_duration'] = null;
      }

      await txn.update(
        'sessions',
        updateData,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    });
  }

  Future<void> updateSessionRestTime({required String sessionId, required int additionalRestSeconds, required String userId}) async {
    final db = await database;

    if (sessionId == null || sessionId.isEmpty) {
      print('sessionId가 없습니다.');
      return;
    }

    final log = await db.query(
      'sessions',
      where: 'session_id = ? AND is_deleted = 0',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (log.isEmpty) {
      print('session을 찾을 수 없습니다.');
      return;
    }

    await db.transaction((txn) async {
      final now = DateTime.now().toUtc().toIso8601String();

      final restTime = log.first['rest_time'] as int;
      final newRestTime = restTime + additionalRestSeconds;
      final duration = log.first['session_duration'] as int;
      final newDuration = duration - additionalRestSeconds;

      final updateData = {
        'session_duration': newDuration,
        'rest_time': newRestTime,
        'last_updated_at': now,
      };

      await db.update(
        'sessions',
        updateData,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    });
  }

  Future<void> updateSessionDuration({required String sessionId, required int additionalDuraionSeconds, required String userId}) async {
    final db = await database;

    if (sessionId == null || sessionId.isEmpty) {
      print('sessionId가 없습니다.');
      return;
    }

    final log = await db.query(
      'sessions',
      where: 'session_id = ? AND is_deleted = 0',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (log.isEmpty) {
      print('session을 찾을 수 없습니다.');
      return;
    }

    await db.transaction((txn) async {
      final now = DateTime.now().toUtc().toIso8601String();

      final duration = log.first['session_duration'] as int;
      final newDuration = duration + additionalDuraionSeconds;

      final updateData = {
        'session_duration': newDuration,
        'last_updated_at': now,
      };

      await db.update(
        'sessions',
        updateData,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    });
  }

  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    final db = await database;

    final result = await db.query(
      'sessions',
      where: 'session_id = ? AND is_deleted = 0',
      whereArgs: [sessionId],
    );

    return result.isNotEmpty ? result.first : null;
  }

  Future<String?> getLastSessionId(String timerId) async {
    final db = await database;

    final logs = await db.query(
      'sessions',
      where: 'timer_id = ? AND is_deleted = 0',
      whereArgs: [timerId],
      orderBy: 'start_time DESC',
      limit: 1,
    );

    return logs.isNotEmpty ? logs.first['session_id'] as String? : null;
  }

  Future<List<Map<String, dynamic>>> getSessionsForToday(String userId) async {
    final db = await database;
    DateTime now = DateTime.now();
    String todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    String tomorrowStart = DateTime(now.year, now.month, now.day + 1).toUtc().toIso8601String();

    final result = await db.query(
      'sessions',
      where: 'start_time >= ? AND start_time < ? AND is_deleted = 0',
      whereArgs: [todayStart, tomorrowStart],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getAllSessions() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT sessions.*, activities.activity_name, activities.activity_icon, activities.activity_color
      FROM sessions
      JOIN activities
      ON sessions.activity_id = activities.activity_id
      WHERE sessions.is_deleted = 0 AND activities.is_deleted = 0
    ''');
  }

  // 세션 삭제 (소프트 딜리션)
  Future<void> deleteSession(String userId, String sessionId) async {
    String now = DateTime.now().toUtc().toIso8601String();

    final db = await database;
    try {
      await db.update(
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
      final _e = {
        'uid': userId,
        'created_at': now,
        'error_message': e.toString(),
        'error_action': '세션 삭제 중',
      };
      await db.insert('errors', _e);
    }
  }

  Future<List<Map<String, dynamic>>> getSessionsForCurrentWeek(String userId) async {
    final db = await database;

    DateTime now = DateTime.now().toUtc();
    DateTime weekStartDate = now.subtract(Duration(days: now.weekday - 1));
    String weekStart = weekStartDate.toIso8601String().split('T').first;

    final logs = await db.rawQuery('''
      SELECT sessions.*, activities.activity_name, activities.activity_icon, activities.activity_color
      FROM sessions
      JOIN activities ON sessions.activity_id = activities.activity_id
      WHERE sessions.uid = ? AND sessions.is_deleted = 0 AND activities.is_deleted = 0
    ''', [userId]);

    return logs;
  }

  Future<List<Map<String, dynamic>>> getSessionsForWeek(String userId, int weekOffset) async {
    final db = await database;

    // 현재 날짜로부터 weekOffset만큼 이전의 주차 계산
    DateTime now = DateTime.now().toLocal();
    DateTime startOfWeek = DateTime.utc(now.year, now.month, now.day, 0, 0, 0).subtract(Duration(days: now.weekday - 1 + 7 * weekOffset));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 7)).subtract(Duration(seconds: 1));

    String startOfWeekStr = startOfWeek.toIso8601String();
    String endOfWeekStr = endOfWeek.toIso8601String();

    print('Fetching sessions from $startOfWeekStr to $endOfWeekStr for userId=$userId');

    List<Map<String, dynamic>> results = await db.rawQuery('''
    SELECT sessions.*, activities.activity_name, activities.activity_icon, activities.activity_color
    FROM sessions
    JOIN activities ON sessions.activity_id = activities.activity_id
    WHERE sessions.uid = ? 
      AND sessions.is_deleted = 0 
      AND activities.is_deleted = 0
      AND (
        (sessions.start_time BETWEEN ? AND ?)
        OR (sessions.end_time BETWEEN ? AND ?)
        OR (sessions.start_time < ? AND (sessions.end_time > ? OR sessions.end_time IS NULL))
      )
    ORDER BY sessions.start_time DESC, sessions.end_time DESC;
    ''', [
      userId,
      startOfWeekStr,
      endOfWeekStr,
      startOfWeekStr,
      endOfWeekStr,
      startOfWeekStr,
      startOfWeekStr,
    ]);

    return results;
  }
}
