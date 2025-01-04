import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';
import 'package:project1/utils/auth_provider.dart';
import 'package:project1/utils/device_info_service.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project1/utils/error_service.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스 생성
  final ErrorService _errorService;
  final AuthProvider _authProvider;
  final DeviceInfoService _deviceInfoService;

  DatabaseService({
    required AuthProvider authProvider,
    required DeviceInfoService deviceInfoService,
    required ErrorService errorService,
  })  : _authProvider = authProvider,
        _errorService = errorService,
        _deviceInfoService = deviceInfoService;
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
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT,
        user_name TEXT,
        user_tag TEXT,
        profile_image TEXT,
        profile_message TEXT,
        verified_method TEXT,
        timezone TEXT,
        role TEXT,
        created_at TEXT,
        last_logged_in TEXT,
        last_activated_at TEXT,
        last_updated_at TEXT,
        login_count INTEGER,
        is_trial INTEGER,
        is_subscriber INTEGER,
        is_deleted INTEGER DEFAULT 0,
        is_banned INTEGER,
        ban_note TEXT,
        subscription_start_date TEXT,
        subscription_end_date TEXT,
        subscription_cycle INTEGER,
        total_seconds INTEGER,
        preference TEXT,
        notifications_enabled INTEGER,
        last_device_info TEXT,
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
        last_session_id TEXT,
        is_running INTEGER,
        created_at TEXT,
        deleted_at TEXT,
        last_started_at TEXT,
        last_ended_at TEXT,
        last_updated_at TEXT,
        last_notified_at TEXT,
        is_deleted INTEGER DEFAULT 0,
        sessions_over_1hour INTEGER,
        timezone TEXT,
        UNIQUE (uid, week_start)
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT,
        session_id TEXT,
        timer_id TEXT,
        mode TEXT,
        activity_id TEXT,
        activity_name TEXT,
        activity_icon TEXT,
        activity_color TEXT,
        start_time TEXT,
        end_time TEXT,
        session_duration INTEGER,
        target_duration INTEGER,
        previous_session_duration INTEGER,
        created_at TEXT,
        deleted_at TEXT,
        last_updated_at TEXT,
        is_modified INTEGER,
        is_deleted INTEGER DEFAULT 0,
        timezone TEXT,
        long_session_flag INTEGER,
        user_agent TEXT
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
        is_favorite INTEGER DEFAULT 0,
        is_default INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT,
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

    await db.execute('''
      CREATE TABLE errors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT,
        created_at TEXT,
        error_code TEXT,
        error_action TEXT,
        error_message TEXT,
        severity_level TEXT,
        device_info TEXT,
        app_version TEXT,
        os_version TEXT
      )
    ''');

    // last_sync_at을 저장하는 테이블 생성
    await db.execute('''
      CREATE TABLE sync_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT,
        sync_duration INTEGER,
        last_sync_at TEXT,
        device_info TEXT,
        app_version TEXT,
        is_auto_sync INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE contents (
        id TEXT PRIMARY KEY,
        content_id TEXT,
        type TEXT,
        title TEXT,
        content TEXT,
        priority INTEGER,
        start_date TEXT,
        end_date TEXT,
        is_pinned INTEGER,
        is_visible INTEGER,
        is_deleted INTEGER DEFAULT 0,
        due_date TEXT,
        target_audience TEXT,
        author TEXT,
        last_updated_at TEXT,
        related_content TEXT,
        language TEXT DEFAULT 'KR'
      )
    ''');

    await db.execute('''
      CREATE TABLE user_behavior (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT,
          event_type TEXT,
          event_name TEXT,
          event_timestamp TEXT,
          previous_page TEXT,
          current_page TEXT,
          navigation_type TEXT,
          referrer TEXT,
          destination_page TEXT,
          duration_in_previous_page INTEGER,
          scroll_depth_previous_page TEXT,
          is_redirect INTEGER DEFAULT 0,
          button_clicked TEXT,
          scroll_depth_current_page TEXT,
          interaction_duration INTEGER,
          device_type TEXT,
          os_type TEXT,
          browser_type TEXT,
          created_at TEXT
      );
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 1) {}
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'DB_UPGRADE_ERROR',
        errorMessage: 'Failed to upgrade database: $e',
        errorAction: 'Database upgrade from $oldVersion to $newVersion',
        severityLevel: 'high',
      );

      await insertErrorLog(errorData);
    }
  }

  /*

      @SYNC

      마지막 sync 가져오기
      sync 생성
      DB나 서버에서 user 가져오기 (서버에서 user를 가져올 때 data도 함께)
      유저 데이터 FireStore에서 가져오기
      FireStore에서 가져온 유저 데이터 SQLite에 맞게 변환하기 + 저장하기
      FireStore에서 가져온 유저 데이터 SQLite에 저장하기
      DB와 서버 데이터 sync
      DB 데이터 chunks로 만들기
      서버에 DB 데이터 업로드
      서버에서 데이터 다운로드
      다운받은 데이터 DB로 merge
      
  */

  // last_sync_at 가져오기
  Future<String?> getLastSyncAt() async {
    final db = await database;
    try {
      final result = await db.query(
        'sync_info',
        orderBy: 'id DESC',
        limit: 1,
      );
      if (result.isNotEmpty) {
        return result.first['last_sync_at'] as String?;
      }
      return null;
    } catch (e) {
      // 에러 발생 시 로그 기록
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'GET_LAST_SYNC_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Fetching last_sync_at from SQLite',
        severityLevel: 'medium',
      );
      await insertErrorLog(errorData);

      print('Error fetching last_sync_at: $e');
      return null; // 에러 발생 시 null 반환
    }
  }

  Future<void> createSyncLog({
    required int syncDuration,
    bool isAutoSync = false,
  }) async {
    final db = await database;
    final uid = _authProvider.user?.uid;
    final now = DateTime.now().toUtc().toIso8601String();
    final deviceInfo = await _deviceInfoService.getDeviceInfo();

    if (uid == null) {
      print('Error: UID is null. User might not be logged in.');
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'UID_MISSING',
        errorMessage: 'UID is null in createSync function',
        errorAction: 'Fetch user UID for sync operation',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      return;
    }

    try {
      await db.insert(
        'sync_info',
        {
          'uid': uid,
          'sync_duration': syncDuration,
          'last_sync_at': now,
          'device_info': deviceInfo['deviceInfo'] ?? 'unknown',
          'app_version': deviceInfo['appVersion'] ?? 'unknown',
          'os_version': deviceInfo['osVersion'] ?? 'unknown',
          'is_auto_sync': isAutoSync ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('last_sync_at updated successfully for uid: $uid.');
    } catch (e) {
      // 에러 발생 시 로그 기록
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'CREATE_SYNC_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Inserting sync info into SQLite',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error updating last_sync_at for uid $uid: $e');
    }
  }

  Future<Map<String, dynamic>> fetchOrDownloadUser() async {
    try {
      // 데이터베이스에서 사용자 데이터 검색
      final user = await getUser();

      if (user != null) {
        // 로컬 데이터 반환
        return user;
      } else {
        print('User not found locally. Downloading from server...');

        // 서버에서 사용자 데이터를 다운로드하는 함수 호출
        await fetchUserFromFireStoreAndSaveToSQLite();
        await downloadDataFromServer();

        // 서버에서 받은 데이터를 로컬 데이터베이스에 저장한 후 다시 검색
        final newUser = await getUser();

        if (newUser != null) {
          print('User successfully downloaded and saved: ${newUser['user_name']}');
          return newUser; // 다운로드된 데이터 반환
        } else {
          throw Exception('Failed to fetch user data from server.');
        }
      }
    } catch (e) {
      // 에러 발생 시 ErrorService를 통해 로그 기록
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'FETCH_USER_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Fetching or downloading user data',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error in fetchOrDownloadUser: $e');

      // 에러를 다시 throw하여 상위 호출자에게 전달
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserFromFireStore() async {
    final uid = _authProvider.user?.uid;

    if (uid == null) {
      handleUidNull(errorAction: "Attempting to fetch user from Firestore");
      print('Error: UID not available from AuthProvider.');
      return null;
    }

    try {
      DocumentSnapshot docSnapshot = await _firestore.collection('users').doc(uid).get();
      // 널 체크 강화 시작
      if (!docSnapshot.exists) {
        Map<String, dynamic> errorData = await _errorService.createError(
          errorCode: 'USER_NOT_FOUND',
          errorMessage: 'User with uid $uid does not exist in Firestore.',
          errorAction: 'Fetching user from Firestore',
          severityLevel: 'medium',
        );
        await insertErrorLog(errorData);

        print('User with uid $uid does not exist in Firestore.');
        return null;
      }

      final data = docSnapshot.data();
      if (data == null) {
        Map<String, dynamic> errorData = await _errorService.createError(
          errorCode: 'DATA_NULL',
          errorMessage: 'Data is null for uid $uid.',
          errorAction: 'Fetching user from Firestore',
          severityLevel: 'medium',
        );
        await insertErrorLog(errorData);

        print('Data is null for uid $uid');
        return null;
      }

      // 타입 안전성 검사 (Map으로 캐스팅 가능한지)
      if (data is! Map<String, dynamic>) {
        Map<String, dynamic> errorData = await _errorService.createError(
          errorCode: 'INVALID_DATA_TYPE',
          errorMessage: 'Data for uid $uid is not a Map<String, dynamic>. Actual type: ${data.runtimeType}',
          errorAction: 'Fetching user from Firestore',
          severityLevel: 'medium',
        );
        await insertErrorLog(errorData);

        print('Data for uid $uid is not a Map<String, dynamic>. Actual type: ${data.runtimeType}');
        return null;
      }

      return data; // 성공적으로 데이터 반환
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'FIRESTORE_FETCH_ERROR',
        errorMessage: 'Error fetching user from Firestore: $e',
        errorAction: 'Fetching user from Firestore',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error fetching user from Firestore: $e');
      return null;
    }
  }

  // Firestore에서 유저 데이터를 가져와 SQLite에 저장하기
  Future<void> fetchUserFromFireStoreAndSaveToSQLite() async {
    try {
      // Firestore에서 유저 데이터 가져오기
      Map<String, dynamic>? userData = await getUserFromFireStore();
      if (userData != null) {
        // SQLite 테이블에 맞게 데이터 변환
        Map<String, dynamic> sqliteUserData = {
          'uid': userData['uid'] ?? '',
          'user_name': userData['user_name'] ?? '',
          'user_tag': userData['user_tag'] ?? '',
          'profile_image': userData['profile_image'] ?? '',
          'profile_message': userData['profile_message'] ?? '',
          'verified_method': userData['verified_method'] ?? '',
          'timezone': userData['timezone'] ?? '',
          'role': userData['role'] ?? '',
          'created_at': userData['created_at'] ?? '',
          'last_logged_in': userData['last_logged_in'] ?? '',
          'last_activated_at': userData['last_activated_at'] ?? '',
          'last_updated_at': userData['last_updated_at'] ?? '',
          'login_count': userData['login_count'] ?? 0,
          'is_trial': userData['is_trial'] ?? 0,
          'is_subscriber': userData['is_subscriber'] ?? 0,
          'is_deleted': userData['is_deleted'] ?? 0,
          'is_banned': userData['is_banned'] ?? 0,
          'ban_note': userData['ban_note'] ?? '',
          'subscription_start_date': userData['subscription_start_date'] ?? '',
          'subscription_end_date': userData['subscription_end_date'] ?? '',
          'subscription_cycle': userData['subscription_cycle'] ?? 0,
          'total_seconds': userData['total_seconds'] ?? 0,
          'preference': userData['preference'] ?? '',
          'notifications_enabled': userData['notifications_enabled'] ?? 1,
          'last_device_info': userData['last_device_info'] ?? '',
        };

        // SQLite에 저장
        await saveUserToSQLite(sqliteUserData);
      } else {
        // Firestore에서 유저 데이터를 가져오지 못했을 경우
        Map<String, dynamic> errorData = await _errorService.createError(
          errorCode: 'FETCH_USER_FAILED',
          errorMessage: 'Failed to fetch user data from Firestore.',
          errorAction: 'Fetching user data',
          severityLevel: 'medium',
        );
        await insertErrorLog(errorData);

        print('Failed to fetch user data from Firestore.');
      }
    } catch (e) {
      // 예외 발생 시 에러 기록
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'EXCEPTION_FETCH_USER',
        errorMessage: e.toString(),
        errorAction: 'Fetching user data and saving to SQLite',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error occurred while fetching user data and saving to SQLite: $e');
    }
  }

  // SQLite에 유저 데이터 저장하기
  Future<void> saveUserToSQLite(Map<String, dynamic> userData) async {
    final db = await database;
    try {
      await db.insert(
        'users',
        userData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('User saved to SQLite successfully.');
    } catch (e) {
      // 에러 발생 시 ErrorService를 통해 에러 로그 기록
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'SAVE_USER_SQLITE_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Saving user to SQLite',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error saving user to SQLite: $e');
    }
  }

  // fireStore 서버의 데이터와 동기화
  Future<void> syncDataWithServer(bool isAutoSync) async {
    final startTime = DateTime.now(); // Start time for sync duration

    try {
      await uploadDataToServer();
      await downloadDataFromServer();

      final endTime = DateTime.now(); // End time for sync duration
      final syncDuration = endTime.difference(startTime).inSeconds;

      // 동기화 후 last_sync_at 업데이트
      await createSyncLog(syncDuration: syncDuration, isAutoSync: isAutoSync);
      print('Data synchronized successfully');
    } catch (e) {
      // 에러 발생 시 처리
      print('Error during data synchronization: $e');
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'SYNC_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Synchronizing data with server',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);
    }
  }

  // 동기화 데이터 업로드
  Future<void> uploadDataToServer() async {
    final db = await database;
    final uid = _authProvider.user?.uid;
    String now = DateTime.now().toUtc().toIso8601String();
    String syncId = now.replaceAll(RegExp(r'[:-]|\.\d{3}'), ''); // ':'와 '-' 및 밀리초 제거

    try {
      // 마지막 동기화 시점 가져오기
      String lastSyncAt = await getLastSyncAt() ?? DateTime(1970).toUtc().toIso8601String();

      // 변경된 활동 데이터 가져오기
      final activities = await db.query(
        'activities',
        where: 'uid = ? AND (last_updated_at > ? OR created_at > ? OR last_updated_at IS NULL)',
        whereArgs: [uid, lastSyncAt, lastSyncAt],
      );

      // 변경된 타이머 데이터 가져오기
      final timers = await db.query(
        'timers',
        where: 'uid = ? AND (last_updated_at > ? OR created_at > ? OR last_updated_at IS NULL)',
        whereArgs: [uid, lastSyncAt, lastSyncAt],
      );

      // 변경된 세션 데이터 가져오기
      final sessions = await db.query(
        'sessions',
        where: 'uid = ? AND (last_updated_at > ? OR created_at > ? OR last_updated_at IS NULL)',
        whereArgs: [uid, lastSyncAt, lastSyncAt],
      );

      // 변경된 데이터가 없으면 업로드하지 않음
      if (activities.isEmpty && timers.isEmpty && sessions.isEmpty) {
        print('No changes to upload.');
        return;
      }

      // 데이터 구조 생성
      Map<String, dynamic> data = {
        'uid': uid,
        'sync_id': syncId,
        'synced_at': now,
        'data': {
          'activities': {for (var activity in activities) activity['activity_id']: activity},
          'timers': {for (var timer in timers) timer['timer_id']: timer},
          'sessions': {for (var session in sessions) session['session_id']: session},
        },
      };

      // 데이터 분할 및 Firestore 업로드
      List<Map<String, dynamic>> chunks = splitDataIntoChunks(data);
      for (int i = 0; i < chunks.length; i++) {
        String chunkId = '${uid}_sync_chunk_${DateTime.now().millisecondsSinceEpoch}_$i';
        await _firestore.collection('user_sync_data').doc(chunkId).set({
          'chunk_index': i,
          'total_chunks': chunks.length,
          'user_id': uid,
          'data': chunks[i],
          'synced_at': now,
        });
        print('Uploaded chunk $i/${chunks.length}');
      }
    } catch (e) {
      print('Error during data upload: $e');

      // 에러 로그 기록
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'UPLOAD_DATA_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Uploading data to Firestore',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);
    }
  }

  Future<void> downloadDataFromServer() async {
    final firestore = FirebaseFirestore.instance;
    final uid = _authProvider.user?.uid;

    if (uid == null) {
      print('Error: UID is null. User might not be logged in.');
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'UID_NULL',
        errorMessage: 'UID is null. User might not be logged in.',
        errorAction: 'Downloading data from server',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      return;
    }

    try {
      // 마지막 동기화 시점 가져오기
      String? lastSyncAt = await getLastSyncAt();

      Query query = firestore.collection('user_sync_data').where('user_id', isEqualTo: uid).orderBy('synced_at', descending: false);

      if (lastSyncAt != null) {
        query = query.where('synced_at', isGreaterThan: lastSyncAt);
      }

      final querySnapshot = await query.get();

      await downloadNewContentsFromFirestore(lastSyncAt);

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
    } catch (e) {
      print('Error during data download from server: $e');
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'DOWNLOAD_DATA_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Downloading data from server',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);
    }
  }

  Future<void> mergeDataFromServer(Map<String, dynamic> data) async {
    try {
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
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'MERGE_DATA_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Merging data from server',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error during merging data from server: $e');
    }
  }

  Future<void> mergeActivityData(Map<String, dynamic> activityData) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String(); // 현재 시간 추가

    try {
      final existing = await db.query('activities', where: 'activity_id = ?', whereArgs: [activityData['activity_id']]);

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
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'MERGE_ACTIVITY_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Merging activity data',
        severityLevel: 'medium',
      );
      await insertErrorLog(errorData);

      print('Error merging activity data: $e');
    }
  }

  Future<void> mergeTimerData(Map<String, dynamic> timerData) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String(); // 현재 시간 추가

    try {
      final existing = await db.query('timers', where: 'timer_id = ?', whereArgs: [timerData['timer_id']]);

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
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'MERGE_TIMER_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Merging timer data',
        severityLevel: 'medium',
      );
      await insertErrorLog(errorData);

      print('Error merging timer data: $e');
    }
  }

  Future<void> mergeSessionData(Map<String, dynamic> sessionData) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String(); // 현재 시간 추가

    try {
      final existing = await db.query('sessions', where: 'session_id = ?', whereArgs: [sessionData['session_id']]);

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
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'MERGE_SESSION_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Merging session data',
        severityLevel: 'medium',
      );
      await insertErrorLog(errorData);

      print('Error merging session data: $e');
    }
  }

  /*

      @DATA

      데이터를 Chunks로 쪼개기

  */

  // firestore 1MB 업로드 제한을 고려하여 업로드 데이터 분할
  List<Map<String, dynamic>> splitDataIntoChunks(Map<String, dynamic> data) {
    const int maxChunkSize = 950 * 1024;
    List<Map<String, dynamic>> chunks = [];
    Map<String, dynamic> currentChunk = {};
    int currentChunkSize = 0;

    try {
      if (!data.containsKey('data') || data['data'] is! Map<String, dynamic>) {
        throw Exception("Invalid data format: 'data' key is missing or not a Map<String, dynamic>.");
      }

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
    } catch (e) {
      print('Error splitting data into chunks: $e');
    }

    return chunks;
  }

  /*

      userSetting

      user totalSeconds 수정

  */

  Future<void> updateUserTotalSeconds(int totalSeconds) async {
    final db = await database;
    final uid = _authProvider.user?.uid;

    if (uid == null) {
      handleUidNull(errorAction: "Attempting to update user's total_seconds in SQLite");

      print('Error: UID is null. User might not be logged in.');
      return;
    }

    String now = DateTime.now().toUtc().toIso8601String();

    try {
      await db.update(
        'users',
        {
          'total_seconds': totalSeconds,
          'last_updated_at': now,
        },
        where: 'uid = ?',
        whereArgs: [uid],
      );
      print('Total seconds updated successfully for uid: $uid.');
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'UPDATE_TOTAL_SECONDS_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Updating total_seconds in SQLite',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error updating total_seconds for uid $uid: $e');
    }
  }

  /*
      @USER 

      유저 데이터 생성
      유저 데이터 SQLite에서 가져오기

  */

  // 유저데이터 생성
  Future<void> createUser(String userId, Map<String, dynamic> userData) async {
    final db = await database;

    try {
      await db.insert('users', userData, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'USER_CREATION_ERROR',
        errorMessage: e.toString(),
        errorAction: '유저 생성 중',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    final db = await database;
    final uid = _authProvider.user?.uid;

    if (uid == null) {
      handleUidNull(errorAction: "Attempting to fetch user from database");

      print('Error: UID not available from AuthProvider.');
      return null;
    }

    try {
      final List<Map<String, dynamic>> results = await db.query(
        'users',
        where: 'uid = ?',
        whereArgs: [uid],
        limit: 1,
      );

      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'DB_QUERY_ERROR',
        errorMessage: 'Failed to fetch user: $e',
        errorAction: 'Query user with UID: $uid',
        severityLevel: 'medium',
      );
      await insertErrorLog(errorData);

      print('Error fetching user with UID $uid: $e');
      return null;
    }
  }

  /*

      @Timer

      Timer 생성
      Timer 가져오기
      Timer 업데이트
      Timer 삭제

  */

  // 타이머 생성
  Future<void> createTimer(Map<String, dynamic> timerData) async {
    final db = await database;
    final uid = _authProvider.user?.uid;

    if (uid == null) {
      handleUidNull(errorAction: "Attempting to create timer in SQLite");

      print('Error: UID is null. User might not be logged in.');
      return;
    }

    try {
      // 해당 주차에 이미 타이머가 있는지 확인
      final weekStart = timerData['week_start'];
      final existingTimers = await db.query(
        'timers',
        where: 'uid = ? AND week_start = ? AND is_deleted = 0',
        whereArgs: [uid, weekStart],
        limit: 1,
      );

      if (existingTimers.isNotEmpty) {
        // 주차 타이머 중복 발견 시 로그 생성 및 함수 종료
        print('Timer already exists for user $uid in week starting $weekStart.');
        Map<String, dynamic> errorData = await _errorService.createError(
          errorCode: 'TIMER_ALREADY_EXISTS',
          errorMessage: 'Timer already exists for the specified week.',
          errorAction: 'Attempted to create a duplicate timer.',
          severityLevel: 'low',
        );
        await insertErrorLog(errorData);

        return;
      }

      await db.insert('timers', timerData, conflictAlgorithm: ConflictAlgorithm.replace);
      print('Timer created successfully for user: $uid.');
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'CREATE_TIMER_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Creating timer in SQLite',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error creating timer for user $uid: $e');
    }
  }

  Future<Map<String, dynamic>?> getTimer(String weekStart) async {
    final uid = _authProvider.user?.uid;

    if (uid == null) {
      handleUidNull(errorAction: "Attempting to fetch timer");

      print('Error: UID is null. User might not be logged in.');
      return null;
    }

    final db = await database;

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'timers',
        where: 'uid = ? AND week_start = ? AND is_deleted = 0',
        whereArgs: [uid, weekStart],
      );

      if (result.isNotEmpty) {
        print('Timer fetched successfully for UID: $uid, Week Start: $weekStart');
        return result.first;
      } else {
        print('No timer found for UID: $uid, Week Start: $weekStart');
        return null;
      }
    } catch (e) {
      // 쿼리 실행 중 에러 발생 시 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'FETCH_TIMER_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Fetching timer from SQLite',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error fetching timer. UID: $uid, Week Start: $weekStart, Error: $e');
      return null;
    }
  }

  // 타이머 업데이트
  Future<void> updateTimer(String timerId, Map<String, dynamic> updatedData) async {
    final uid = _authProvider.user?.uid;
    String now = DateTime.now().toUtc().toIso8601String();

    if (uid == null) {
      handleUidNull(errorAction: "Attempting to update timer");
      print('Error: UID is null. User might not be logged in.');
      return;
    }

    updatedData['last_updated_at'] = now; // 마지막 업데이트 시간 설정

    final db = await database;
    try {
      final updatedRows = await db.update(
        'timers',
        updatedData,
        where: 'timer_id = ? AND uid = ?',
        whereArgs: [timerId, uid],
      );

      if (updatedRows == 0) {
        // 업데이트할 타이머가 없는 경우 에러 생성
        Map<String, dynamic> errorData = await _errorService.createError(
          errorCode: 'TIMER_NOT_FOUND',
          errorMessage: 'No timer found with timer_id: $timerId for user: $uid',
          errorAction: 'Attempting to update non-existent timer',
          severityLevel: 'low',
        );
        await insertErrorLog(errorData);

        print('Error: Timer not found. Timer ID: $timerId, UID: $uid');
      } else {
        print('Timer updated successfully. Timer ID: $timerId, UID: $uid');
      }
    } catch (e) {
      // 업데이트 중 에러 발생 시 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'UPDATE_TIMER_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Updating timer in SQLite',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error updating timer. Timer ID: $timerId, UID: $uid, Error: $e');
    }
  }

// 특정 타이머 삭제 (소프트 딜리션)
  Future<void> deleteTimer(String timerId) async {
    final uid = _authProvider.user?.uid;
    String now = DateTime.now().toUtc().toIso8601String();

    if (uid == null) {
      handleUidNull(errorAction: "Attempting to delete timer");

      print('Error: UID is null. User might not be logged in.');
      return;
    }

    final db = await database;

    try {
      final updatedRows = await db.update(
        'timers',
        {
          'is_deleted': 1,
          'deleted_at': now,
          'last_updated_at': now,
        },
        where: 'timer_id = ? AND uid = ?',
        whereArgs: [timerId, uid],
      );

      if (updatedRows == 0) {
        // 삭제할 타이머가 없을 경우 에러 로그 생성
        Map<String, dynamic> errorData = await _errorService.createError(
          errorCode: 'TIMER_NOT_FOUND',
          errorMessage: 'No timer found with timer_id: $timerId for user: $uid',
          errorAction: 'Attempting to delete non-existent timer',
          severityLevel: 'low',
        );
        await insertErrorLog(errorData);

        print('Error: Timer not found. Timer ID: $timerId, UID: $uid');
      } else {
        print('Timer deleted successfully. Timer ID: $timerId, UID: $uid');
      }
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'DELETE_TIMER_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Deleting timer from SQLite',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error deleting timer. Timer ID: $timerId, UID: $uid, Error: $e');
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
  Future<void> addActivity(String activityName, String activityIcon, String activityColor, bool isDefault) async {
    final db = await database;
    final uid = _authProvider.user?.uid;

    if (uid == null) {
      handleUidNull(errorAction: "Attempting to add activity");

      print('Error: UID is null. User might not be logged in.');
      return;
    }

    final activityId = const Uuid().v4();
    String now = DateTime.now().toUtc().toIso8601String();
    final activity = {
      'uid': uid,
      'activity_id': activityId,
      'activity_name': activityName,
      'activity_icon': activityIcon,
      'activity_color': activityColor,
      'created_at': now,
      'deleted_at': null,
      'last_updated_at': now,
      'is_default': isDefault ? 1 : 0,
      'is_favorite': 0,
      'is_deleted': 0,
    };

    try {
      await db.insert('activities', activity, conflictAlgorithm: ConflictAlgorithm.replace);
      print('Activity added successfully for UID: $uid');
    } catch (e) {
      // 에러 발생 시 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'ADD_ACTIVITY_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Adding activity to SQLite',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error adding activity. UID: $uid, Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getActivities() async {
    final uid = _authProvider.user?.uid;
    final db = await database;
    if (uid == null) {
      handleUidNull(errorAction: "Attempting to fetch all activities");

      print('Error: UID is null. User might not be logged in.');
      return [];
    }

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'activities',
        where: 'uid = ? AND is_deleted = 0',
        whereArgs: [uid],
      );

      return result;
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'GET_ACTIVITIES_FAILED',
        errorMessage: e.toString(),
        errorAction: 'getting activities from SQLite',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error getting activities. UID: $uid, Error: $e');
      return [];
    }
  }

  // 활동 업데이트
  Future<void> updateActivity(
      String activityId, String newActivityName, String newActivityIcon, String newActivityColor, bool newIsFavorite) async {
    final uid = _authProvider.user?.uid; // AuthProvider에서 UID 가져오기
    final db = await database; // 데이터베이스 객체 가져오기

    if (uid == null) {
      handleUidNull(errorAction: "Attempting to update activity");
      print('Error: UID is null. User might not be logged in.');
      return;
    }

    String now = DateTime.now().toUtc().toIso8601String(); // 현재 시간
    final update = {
      'activity_name': newActivityName,
      'activity_icon': newActivityIcon,
      'activity_color': newActivityColor,
      'is_favorite': newIsFavorite,
      'last_updated_at': now,
    };

    try {
      // 데이터 업데이트
      final rowsAffected = await db.update(
        'activities',
        update,
        where: 'activity_id = ? AND uid = ? AND is_deleted = 0',
        whereArgs: [activityId, uid],
      );

      // 업데이트가 적용되지 않은 경우 처리
      if (rowsAffected == 0) {
        Map<String, dynamic> errorData = await _errorService.createError(
          errorCode: 'UPDATE_ACTIVITY_NOT_FOUND',
          errorMessage: 'No activity found with ID $activityId for UID $uid.',
          errorAction: 'Updating activity',
          severityLevel: 'medium',
        );
        await insertErrorLog(errorData);

        print('Warning: No rows updated for activity ID $activityId.');
      }
    } catch (e) {
      // 에러 발생 시 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'UPDATE_ACTIVITY_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Updating activity',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error updating activity. Activity ID: $activityId, UID: $uid, Error: $e');
    }
  }

  // 활동 삭제 (소프트 딜리션)
  Future<void> deleteActivity(String activityId) async {
    final uid = _authProvider.user?.uid; // AuthProvider에서 UID 가져오기
    final db = await database; // 데이터베이스 객체 가져오기

    if (uid == null) {
      handleUidNull(errorAction: "Attempting to delete activity");

      print('Error: UID is null. User might not be logged in.');
      return;
    }

    String now = DateTime.now().toUtc().toIso8601String(); // 현재 시간

    try {
      // 활동 삭제 (소프트 딜리션)
      final rowsAffected = await db.update(
        'activities',
        {
          'is_deleted': 1,
          'deleted_at': now,
          'last_updated_at': now,
        },
        where: 'activity_id = ? AND uid = ?',
        whereArgs: [activityId, uid],
      );

      // 삭제가 적용되지 않은 경우 처리
      if (rowsAffected == 0) {
        Map<String, dynamic> errorData = await _errorService.createError(
          errorCode: 'DELETE_ACTIVITY_NOT_FOUND',
          errorMessage: 'No activity found with ID $activityId for UID $uid.',
          errorAction: 'Deleting activity',
          severityLevel: 'medium',
        );
        await insertErrorLog(errorData);

        print('Warning: No rows updated for activity ID $activityId.');
      }
    } catch (e) {
      // 에러 발생 시 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'DELETE_ACTIVITY_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Deleting activity',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error deleting activity. Activity ID: $activityId, UID: $uid, Error: $e');
    }
  }

// isActivityNameDuplicate 메서드 추가
  Future<bool> isActivityNameDuplicate(String activityName) async {
    final uid = _authProvider.user?.uid; // AuthProvider에서 UID 가져오기
    final db = await database; // 데이터베이스 객체 가져오기

    if (uid == null) {
      handleUidNull(errorAction: "Attempting to check duplicate activity name");

      print('Error: UID is null. User might not be logged in.');
      return false; // 중복 확인 불가능한 경우 false 반환
    }

    try {
      // 중복 확인 쿼리 실행
      final List<Map<String, dynamic>> result = await db.query(
        'activities',
        where: 'uid = ? AND activity_name = ? AND is_deleted = 0',
        whereArgs: [uid, activityName],
      );
      return result.isNotEmpty; // 중복 여부 반환
    } catch (e) {
      // 에러 발생 시 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'CHECK_DUPLICATE_ACTIVITY_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Checking duplicate activity name',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error checking duplicate activity name. Activity Name: $activityName, UID: $uid, Error: $e');
      return false; // 중복 확인 불가능한 경우 false 반환
    }
  }

  /*

      @todo




  */
  Future<List<Map<String, dynamic>>> getTodos() async {
    final uid = _authProvider.user?.uid;
    final db = await database;

    // 삭제되지 않았고 완료되지 않은 항목만 조회
    return await db.query(
      'todos',
      where: 'uid = ? AND is_deleted = 0 AND is_completed = 0',
      whereArgs: [uid],
      orderBy: 'position DESC',
    );
  }

  Future<void> createTodo(Map<String, dynamic> todo) async {
    final db = await database;
    final uid = _authProvider.user?.uid;
    if (uid == null) return;

    // position 값 가져오기
    final maxPosition = await _getMaxPosition();

    final todoId = Uuid().v4();

    await db.insert('todos', {
      'uid': uid,
      'todo_id': todoId,
      'todo_name': todo['todo_name'],
      'todo_detail': todo['todo_detail'],
      'priority': todo['priority'],
      'activity_id': todo['activity_id'],
      'activity_name': todo['activity_name'],
      'activity_icon': todo['activity_icon'],
      'activity_color': todo['activity_color'],
      'created_at': DateTime.now().toIso8601String(),
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
      print(e);
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
    final uid = _authProvider.user?.uid;
    final db = await database;

    final result = await db.rawQuery('SELECT MAX(COALESCE(position, 0)) as maxPosition FROM todos WHERE uid = ? AND is_deleted = 0', [uid]);

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
      required int targetDuration}) async {
    final uid = _authProvider.user?.uid;
    final db = await database;
    final deviceInfo = await _deviceInfoService.getDeviceInfo();

    if (uid == null) {
      handleUidNull(errorAction: "Attempting to create session");

      print('Error: UID is null. User might not be logged in.');
      return; // 세션 생성 불가
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final timezone = DateTime.now().timeZoneName;

    try {
      final _session = {
        'uid': uid,
        'session_id': sessionId,
        'timer_id': timerId,
        'activity_id': activityId,
        'mode': mode,
        'activity_name': activityName,
        'activity_icon': activityIcon,
        'activity_color': activityColor,
        'start_time': now,
        'end_time': null,
        'session_duration': 0,
        'target_duration': targetDuration,
        'previous_session_duration': null,
        'created_at': now,
        'deleted_at': null,
        'last_updated_at': now,
        'is_modified': 0,
        'is_deleted': 0,
        'timezone': timezone,
        'long_session_flag': 0,
        'user_agent': deviceInfo['deviceInfo'] ?? '',
      };

      await db.insert('sessions', _session);

      print('Session created successfully for session_id: $sessionId');
    } catch (e) {
      // 에러 발생 시 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'SESSION_CREATION_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Creating session in SQLite',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error creating session. Session ID: $sessionId, UID: $uid, Error: $e');
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
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'SESSION_FETCH_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Fetching session by sessionId',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error fetching session with sessionId: $sessionId, Error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllSessions() async {
    final db = await database;

    try {
      final results = await db.rawQuery('''
      SELECT sessions.*
      FROM sessions
      WHERE sessions.is_deleted = 0
    ''');

      return results;
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'FETCH_ALL_SESSIONS_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Fetching all sessions',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSessionsWithinDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        s.activity_id,
        s.activity_name,
        s.activity_icon,
        s.activity_color,
        SUM(s.session_duration) as total_duration
      FROM sessions s
      WHERE s.start_time >= ? 
        AND s.start_time < ?
        AND s.is_deleted = 0
        AND s.session_duration > 0
      GROUP BY s.activity_id, s.activity_name, s.activity_icon, s.activity_color
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

      return results;
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'GET_SESSIONS_FAILED',
        errorMessage: e.toString(),
        errorAction: 'getting sessions with date range from SQLite',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);
      return [];
    }
  }

  Future<void> endSession({required String? sessionId, required String endTime, required int duration}) async {
    final db = await database;
    final uid = _authProvider.user?.uid; // AuthProvider에서 UID 가져오기
    final now = DateTime.now().toUtc();

    if (uid == null) {
      handleUidNull(errorAction: 'Attempting to end session');

      print('Error: UID is null. User might not be logged in.');
      return; // 세션 생성 불가
    }

    if (sessionId == null || sessionId.isEmpty) {
      // Session ID가 없거나 비어 있는 경우 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'SESSION_ID_MISSING',
        errorMessage: 'Session ID is null or empty. ${sessionId}',
        errorAction: 'end session',
        severityLevel: 'medium',
      );
      await insertErrorLog(errorData);

      print('Error: Session ID is null or empty.');
      return;
    }

    final log = await db.query(
      'sessions',
      where: 'session_id = ? AND is_deleted = 0',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (log.isEmpty) {
      // 세션을 찾을 수 없는 경우 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'SESSION_NOT_FOUND',
        errorMessage: 'Session not found for sessionId: $sessionId',
        errorAction: 'Updating session',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error: Session not found for sessionId: $sessionId');
      return;
    }

    try {
      await db.transaction((txn) async {
        // 업데이트할 데이터 구성
        Map<String, dynamic> updateData = {
          'last_updated_at': now.toIso8601String(),
          'long_session_flag': duration >= 3600 ? 1 : 0,
        };

        updateData.addAll({
          'end_time': endTime,
          'session_duration': duration,
          'previous_session_duration': duration,
        });

        await txn.update(
          'sessions',
          updateData,
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
      });

      print('Session ended successfully for sessionId: $sessionId ');
    } catch (e) {
      // 트랜잭션 중 에러 발생 시 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'SESSION_END_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Ending session for sessionId: $sessionId',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error ending session: $e');
    }
  }

  Future<void> updateSessionDuration({
    required String sessionId,
    required int additionalDurationSeconds,
  }) async {
    final db = await database;

    if (sessionId.isEmpty) {
      // sessionId가 없는 경우 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'SESSION_ID_MISSING',
        errorMessage: 'Session ID is empty.',
        errorAction: 'Updating session duration',
        severityLevel: 'medium',
      );
      await insertErrorLog(errorData);

      print('Error: sessionId is empty.');
      return;
    }

    // 세션 데이터 조회
    final log = await db.query(
      'sessions',
      where: 'session_id = ? AND is_deleted = 0',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (log.isEmpty) {
      // 세션을 찾을 수 없는 경우 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'SESSION_NOT_FOUND',
        errorMessage: 'Session not found for sessionId=$sessionId',
        errorAction: 'Updating session duration',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error: session not found for sessionId=$sessionId');
      return;
    }

    await db.transaction((txn) async {
      try {
        final now = DateTime.now().toUtc().toIso8601String();

        // 기존 데이터 가져오기
        final existingDuration = (log.first['session_duration'] ?? 0) as int;

        // 새로운 duration 계산
        final newDuration = min(86400, max(0, existingDuration + additionalDurationSeconds));

        // 세션 업데이트
        final sessionUpdateData = {
          'session_duration': newDuration,
          'previous_session_duration': existingDuration,
          'last_updated_at': now,
          'is_modified': 1,
        };

        print('Updating sessionId=$sessionId with newDuration=$newDuration');

        await txn.update(
          'sessions',
          sessionUpdateData,
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
      } catch (e) {
        // 트랜잭션 중 에러 발생 시 에러 로그 생성
        Map<String, dynamic> errorData = await _errorService.createError(
          errorCode: 'SESSION_UPDATE_FAILED',
          errorMessage: e.toString(),
          errorAction: 'Updating session duration for sessionId=$sessionId',
          severityLevel: 'high',
        );
        await insertErrorLog(errorData);

        print('Transaction error: $e');
        throw Exception('Transaction failed: $e');
      }
    });
  }

  // 세션 삭제 (소프트 딜리션)
  Future<void> deleteSession(String sessionId) async {
    final db = await database;
    final uid = _authProvider.user?.uid; // AuthProvider에서 UID 가져오기
    final now = DateTime.now().toUtc().toIso8601String();

    if (uid == null) {
      handleUidNull(errorAction: 'Attempting to delete session');

      print('Error: UID is null. User might not be logged in.');
      return;
    }

    if (sessionId.isEmpty) {
      // Session ID가 없는 경우 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'SESSION_ID_MISSING',
        errorMessage: 'Session ID is null or empty.',
        errorAction: 'Deleting session',
        severityLevel: 'medium',
      );
      await insertErrorLog(errorData);

      print('Error: Session ID is null or empty.');
      return;
    }

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

      if (result == 0) {
        // 세션이 존재하지 않는 경우 에러 로그 생성
        Map<String, dynamic> errorData = await _errorService.createError(
          errorCode: 'SESSION_NOT_FOUND',
          errorMessage: 'No session found for sessionId: $sessionId',
          errorAction: 'Deleting session',
          severityLevel: 'medium',
        );
        await insertErrorLog(errorData);

        print('Error: No session found for sessionId: $sessionId');
      } else {
        print('Session soft-deleted successfully for sessionId: $sessionId');
      }
    } catch (e) {
      // 데이터베이스 작업 중 에러 발생 시 에러 로그 생성
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'SESSION_DELETE_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Deleting session for sessionId: $sessionId',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error deleting session: $e');
    }
  }

  /*

      @Content


  */

  Future<List<Map<String, dynamic>>> getContents() async {
    final db = await database;

    try {
      final results = await db.query(
        'contents',
        where: 'is_visible = 1 AND is_deleted = 0',
        orderBy: 'priority DESC, last_updated_at DESC',
      );

      return results;
    } catch (e) {
      // 에러 발생 시 로그 기록
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'FETCH_CONTENTS_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Fetching contents from database',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error fetching contents: $e');
      return [];
    }
  }

  Future<void> markContentAsCompleted(String contentId) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await db.update(
        'contents',
        {
          'is_visible': 0,
          'last_updated_at': now,
        },
        where: 'content_id = ?',
        whereArgs: [contentId],
      );

      print('Content marked as completed: $contentId');
    } catch (e) {
      // 에러 발생 시 로그 기록
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'MARK_CONTENT_AS_COMPLETED_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Marking content as completed for contentId: $contentId',
        severityLevel: 'medium',
      );
      await insertErrorLog(errorData);

      print('Error marking content as completed: $e');
    }
  }

  void uploadInitialContents() async {
    final firestore = FirebaseFirestore.instance;

    final List<Map<String, dynamic>> initialContents = [
      {
        'id': '1',
        'content_id': '1',
        'type': 'tip',
        'title': '도전 시간 변경',
        'content': '매주 도전 시간을 설정에서 원하는 시간으로 변경할 수 있어요.',
        'priority': 1,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '2',
        'content_id': '2',
        'type': 'tip',
        'title': '활동 변경',
        'content': '메인 화면에서 활동을 변경할 수 있어요.',
        'priority': 1,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '3',
        'content_id': '3',
        'type': 'tip',
        'title': '활동 생성',
        'content': '메인 화면에서 활동 이름을 클릭하여 새로운 활동을 생성할 수 있어요.',
        'priority': 1,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '4',
        'content_id': '4',
        'type': 'tip',
        'title': '기록 새로고침',
        'content': '내 기록 페이지에서 새로고침을 눌러 데이터를 최신 상태로 업데이트하세요.',
        'priority': 2,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '5',
        'content_id': '5',
        'type': 'tip',
        'title': '활동 기록 관리',
        'content': '전체 활동 기록 페이지에서 기록을 옆으로 슬라이드하여 수정하거나 삭제할 수 있어요.',
        'priority': 2,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '6',
        'content_id': '6',
        'type': 'tip',
        'title': '친구 추가',
        'content': '상단의 친구 추가 아이콘을 클릭하여 친구를 추가할 수 있어요.',
        'priority': 2,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '7',
        'content_id': '7',
        'type': 'tip',
        'title': '친구 활동 확인',
        'content': '친구를 추가하면 친구의 활동 상태와 잔여 시간을 확인할 수 있어요.',
        'priority': 2,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '8',
        'content_id': '8',
        'type': 'tip',
        'title': '활동중인 친구 확인',
        'content': '메인 화면에서 활동 중인 친구의 수를 확인할 수 있어요.',
        'priority': 2,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '9',
        'content_id': '9',
        'type': 'tip',
        'title': '활동 이어가기',
        'content': '활동을 멈춘 후 11분 이내에 다시 시작하면 기존 활동을 이어갈 수 있어요.',
        'priority': 1,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '10',
        'content_id': '10',
        'type': 'tip',
        'title': '활동 종료 기준',
        'content': '활동을 멈춘 후 11분 동안은 휴식으로 기록되고, 11분 이상 지나면 활동이 종료된 것으로 간주해요.',
        'priority': 1,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '11',
        'content_id': '11',
        'type': 'tip',
        'title': '활동 색상 변경',
        'content': '활동 색깔을 원하는 색으로 변경할 수 있어요.',
        'priority': 2,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '12',
        'content_id': '12',
        'type': 'tip',
        'title': '시간대 생략',
        'content': '이번주 히트맵 옆의 토글 버튼을 클릭하면 비어있는 시간대를 생략할 수 있어요.',
        'priority': 2,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '13',
        'content_id': '13',
        'type': 'tip',
        'title': '잔디 심기',
        'content': '매일 꾸준히 활동하면 잔디를 심을 수 있어요.',
        'priority': 2,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '14',
        'content_id': '14',
        'type': 'tip',
        'title': '다크모드 지원',
        'content': '디바이스의 다크모드 설정에 따라 어플의 다크모드가 자동으로 변경돼요.',
        'priority': 2,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
      {
        'id': '15',
        'content_id': '15',
        'type': 'tip',
        'title': '업적 확인',
        'content': '업적을 클릭하면 해당 업적에 대한 상세 정보를 확인할 수 있어요.',
        'priority': 2,
        'start_date': null,
        'end_date': null,
        'is_pinned': 0,
        'is_visible': 1,
        'is_deleted': 0,
        'due_date': null,
        'target_audience': 'all',
        'author': 'admin',
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'related_content': null,
        'language': 'KR',
      },
    ];

    final data = {
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'contents': initialContents,
    };

    await firestore.collection('contents').add(data);

    print('초기 콘텐츠 업로드 완료');
  }

  // Firestore에서 팁 동기화
  Future<void> downloadNewContentsFromFirestore(String? lastSyncedAt) async {
    final db = await database;

    List<Map<String, dynamic>> newContents = [];

    try {
      final querySnapshot = await _firestore
          .collection('contents')
          .where('updated_at', isGreaterThan: lastSyncedAt ?? DateTime(1970).toUtc().toIso8601String())
          .orderBy('updated_at', descending: false)
          .get();

      // Firestore에서 가져온 콘텐츠 데이터 추출
      newContents = querySnapshot.docs.expand((doc) => List<Map<String, dynamic>>.from(doc.data()['contents'])).toList();

      print('newContents : $newContents');

      // SQLite에서 기존 데이터 ID 조회
      final existingContents = await db.query('contents', columns: ['content_id']);
      final existingIds = existingContents.map((e) => e['content_id']).toSet();

      // Firestore에서 SQLite에 없는 데이터만 필터링
      final contentsToInsert = newContents.where((content) => !existingIds.contains(content['content_id'])).toList();

      // SQLite에 새 데이터 삽입
      final batch = db.batch();
      for (var content in contentsToInsert) {
        batch.insert('contents', {
          'id': content['id'],
          'content_id': content['content_id'],
          'type': content['type'],
          'title': content['title'],
          'content': content['content'],
          'priority': content['priority'] ?? 0,
          'start_date': content['start_date'],
          'end_date': content['end_date'],
          'is_pinned': content['is_pinned'] ?? 0,
          'is_visible': content['is_visible'] ?? 1,
          'is_deleted': content['is_deleted'] ?? 0,
          'due_date': content['due_date'],
          'target_audience': content['target_audience'],
          'author': content['author'],
          'last_updated_at': content['last_updated_at'] ?? DateTime.now().toUtc().toIso8601String(),
          'related_content': content['related_content'],
          'language': content['language'] ?? 'KR',
        });
      }

      await batch.commit();

      print('${contentsToInsert.length}개의 새 콘텐츠가 SQLite에 추가되었습니다.');
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'CONTENT_SYNC_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Downloading new contents from Firestore',
        severityLevel: 'high',
      );
      await insertErrorLog(errorData);

      print('Error syncing contents: $e');
    }
  }

  /*

      @Error

  */

  Future<void> insertErrorLog(Map<String, dynamic> errorData) async {
    final db = await database;

    if (errorData['uid'] == null) {
      print('UID is null, cannot insert error log into DB.');
      return;
    }

    try {
      await db.insert('errors', errorData);
      print('Error logged into DB for UID: ${errorData['uid']}');
    } catch (e) {
      print('Error inserting error log into DB: $e');
      // 여기서는 ErrorService를 다시 호출하지 않음.
      // 상위 레벨에서 에러 처리를 하거나 로그를 남길 수 있음.
    }
  }

  /// 모든 에러 로그 조회
  Future<List<Map<String, dynamic>>> getAllErrors() async {
    final db = await database;

    try {
      return await db.query(
        'errors',
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print('Error fetching all error logs: $e');
      return [];
    }
  }

  /// 특정 에러 코드로 에러 로그 조회
  Future<List<Map<String, dynamic>>> getErrorsByCode(String errorCode) async {
    final db = await database;

    try {
      return await db.query(
        'errors',
        where: 'error_code = ?',
        whereArgs: [errorCode],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print('Error fetching errors by code: $e');
      return [];
    }
  }

  /// 특정 유저의 에러 로그 조회
  Future<List<Map<String, dynamic>>> getErrorsByUser(String uid) async {
    final db = await database;

    try {
      return await db.query(
        'errors',
        where: 'uid = ?',
        whereArgs: [uid],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print('Error fetching errors by user: $e');
      return [];
    }
  }

  /// 심각도(severity_level)로 에러 로그 조회
  Future<List<Map<String, dynamic>>> getErrorsBySeverity(String severityLevel) async {
    final db = await database;

    try {
      return await db.query(
        'errors',
        where: 'severity_level = ?',
        whereArgs: [severityLevel],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print('Error fetching errors by severity level: $e');
      return [];
    }
  }

  /// 특정 에러 로그 삭제
  Future<void> deleteError(int id) async {
    final db = await database;

    try {
      await db.delete(
        'errors',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting error log: $e');
    }
  }

  /// 에러 로그 모두 삭제
  Future<void> deleteAllErrors() async {
    final db = await database;

    try {
      await db.delete('errors');
    } catch (e) {
      print('Error deleting all error logs: $e');
    }
  }

  /// 에러 로그 업데이트
  Future<void> updateError({
    required int id,
    String? errorCode,
    String? errorMessage,
    String? errorAction,
    String? severityLevel,
  }) async {
    final db = await database;

    try {
      final now = DateTime.now().toUtc().toIso8601String();

      final updateData = {
        if (errorCode != null) 'error_code': errorCode,
        if (errorMessage != null) 'error_message': errorMessage,
        if (errorAction != null) 'error_action': errorAction,
        if (severityLevel != null) 'severity_level': severityLevel,
        'last_updated_at': now,
      };

      await db.update(
        'errors',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error updating error log: $e');
    }
  }

  // Helper methods
  Future<void> handleUidNull({
    required String errorAction,
    String errorCode = 'UID_NOT_FOUND',
  }) async {
    final errorData = await _errorService.createError(
      errorCode: errorCode,
      errorMessage: 'UID is null. User might not be logged in.',
      errorAction: errorAction,
      severityLevel: 'high',
    );
    await insertErrorLog(errorData);

    print('Error: UID is null. $errorAction');
  }
}
