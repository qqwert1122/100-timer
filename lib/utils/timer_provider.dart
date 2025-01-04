import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:project1/screens/timer_page.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/utils/auth_provider.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/error_service.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:uuid/uuid.dart';

class TimerProvider with ChangeNotifier, WidgetsBindingObserver {
  final BuildContext context;
  DatabaseService _dbService;
  final StatsProvider _statsProvider;
  final AuthProvider _authProvider;
  final ErrorService _errorService; // ErrorService 주입
  TimerProvider(
    this.context, {
    required DatabaseService dbService,
    required StatsProvider statsProvider,
    required ErrorService errorService,
    required AuthProvider authProvider,
  })  : _dbService = dbService,
        _statsProvider = statsProvider,
        _errorService = errorService,
        _authProvider = authProvider {
    try {
      // WidgetsBindingObserver 등록
      WidgetsBinding.instance.addObserver(this);
      _initializeTimerData(); // 초기화
    } catch (e) {
      _errorService.createError(
        errorCode: 'TIMER_INIT_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Initializing Timer Data in TimerProvider',
        severityLevel: 'high',
      );
      print('Error initializing TimerProvider: $e');
    }
  }

  late final Completer<void> _initializedCompleter = Completer();
  Future<void> get initialized => _initializedCompleter.future;

  void initializeWithDB(DatabaseService db) {
    _dbService = db;
    _initializedCompleter.complete();
    notifyListeners();
  }

  Timer? _timer;

  bool _disposed = false; // dispose 여부를 추적

  Map<String, dynamic>? _timerData;
  Map<String, dynamic>? get timerData => _timerData;

  final Map<String, double> _weeklyActivityData = {
    '월': 0.0,
    '화': 0.0,
    '수': 0.0,
    '목': 0.0,
    '금': 0.0,
    '토': 0.0,
    '일': 0.0,
  };

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  int _totalSeconds = 360000;
  int get totalSeconds => _totalSeconds;

  int _totalSessionDuration = 0;
  int get totalSessionDuration => _totalSessionDuration;

  int _remainingSeconds = 360000; // 기본값 100시간 (초 단위)
  int get remainingSeconds => _remainingSeconds.clamp(0, _totalSeconds);

  String get formattedTime => _formatTime(remainingSeconds);
  String get formattedHour => _formatHour(remainingSeconds);
  String get formattedActivityTime => _formatTime(_currentSessionDuration.clamp(0, _totalSeconds));
  String get formattedTotalSessionDuration => _formatTime(_totalSessionDuration);
  String get formattedTotalSessionHour => _formatHour(_totalSessionDuration);

  // activity
  String? _currentActivityId;
  String? get currentActivityId => _currentActivityId;

  String _currentActivityName = '전체';
  String get currentActivityName => _currentActivityName;

  String _currentActivityIcon = 'category_rounded';
  String get currentActivityIcon => _currentActivityIcon;

  String _currentActivityColor = '#B7B7B7';
  String get currentActivityColor => _currentActivityColor;

  // session
  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  String? _currentSessionMode;
  String? get currentSessionMode => _currentSessionMode;

  int _currentSessionDuration = 0;
  int get currentSessionDuration => _currentSessionDuration;

  int? _currentSessionTargetDuration;
  int? get currentSessionTargetDuration => _currentSessionTargetDuration;

  bool _isExceeded = false;
  bool get isExceeded => _isExceeded;

  // 타이머의 활성 상태를 확인하는 getter 추가
  bool get isTimerActive => _timer?.isActive ?? false;

  String? _navigationRequest;
  String? get navigationRequest => _navigationRequest;

  /*

      @Init

  */

  Future<void> _initializeTimerData() async {
    try {
      // user 가져오기
      final uid = _authProvider.user?.uid;
      if (uid == null) {
        await _errorService.createError(
          errorCode: 'USER_ID_NOT_FOUND',
          errorMessage: 'UID is null. User might not be logged in.',
          errorAction: 'Initializing Timer Data',
          severityLevel: 'high',
        );
        print('Error: UID is null. User might not be logged in.');
        return;
      }

      // 해당 주차의 타이머 가져오기
      String weekStart = getWeekStart(DateTime.now());
      _timerData = await _dbService.getTimer(weekStart);

      if (_timerData != null) {
        _totalSeconds = _timerData?['total_seconds'];
        _isRunning = (_timerData?['is_running'] ?? 0) == 1;
      } else {
        // 타이머 데이터가 없으면 새로 생성
        _timerData = await _createNewTimer(uid, weekStart);
        _totalSeconds = _timerData?['total_seconds'] ?? 360000;
      }

      // 세션의 duration 합 계산
      _totalSessionDuration = await _statsProvider.getTotalDurationForWeek(weekStart);

      // 남은 시간 계산
      _remainingSeconds = (_totalSeconds - _totalSessionDuration).clamp(0, _totalSeconds);

      // 10분 이상 세션 수 갱신
      int sessionsOver1hour = await _statsProvider.getSessionsOver1HourCount(weekStart);
      _timerData?['sessions_over_1hour'] = sessionsOver1hour;
      _dbService.updateTimer(_timerData?['timer_id'], {
        'sessions_over_1hour': sessionsOver1hour,
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (_currentActivityId != null && _currentActivityId!.isNotEmpty) {
        _setLastActivty(lastActivityId: _currentActivityId);
      } else {
        _setDefaultActivity();
      }

      notifyListeners();
    } catch (e) {
      await _errorService.createError(
        errorCode: 'TIMER_INITIALIZATION_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Initializing Timer Data',
        severityLevel: 'high',
      );
      print('Error initializing timer data: $e');
    }
  }

  Future<Map<String, dynamic>> _createNewTimer(String uid, String weekStart) async {
    try {
      Map<String, dynamic>? userData = await _dbService.getUser();
      int userTotalSeconds = userData?['total_seconds'] ?? 360000; // 기본값은 100시간

      String timerId = const Uuid().v4();
      String now = DateTime.now().toUtc().toIso8601String();
      Map<String, dynamic> timerData = {
        'uid': uid,
        'timer_id': timerId,
        'week_start': weekStart,
        'total_seconds': userTotalSeconds,
        'last_session_id': null,
        'is_running': 0,
        'created_at': now,
        'deleted_at': null,
        'last_started_at': null,
        'last_ended_at': null,
        'last_updated_at': now,
        'last_notified_at': null,
        'sessions_over_1hour': 0,
        'timezone': DateTime.now().timeZoneName,
        'is_deleted': 0,
      };

      await _dbService.createTimer(timerData);
      return timerData;
    } catch (e) {
      await _errorService.createError(
        errorCode: 'CREATE_NEW_TIMER_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Creating New Timer',
        severityLevel: 'high',
      );
      print('Error creating new timer: $e');
      return {};
    }
  }

  // 현재 활동 정보를 설정하는 메서드
  void setCurrentActivity(String activityId, String activityName, String activityIcon, String activityColor) {
    _currentActivityId = activityId;
    _currentActivityName = activityName;
    _currentActivityIcon = activityIcon;
    _currentActivityColor = activityColor;
    notifyListeners();
  }

  void setTimerData(Map<String, dynamic> timerData) async {
    try {
      print('setTimerData 호출!');
      _timerData = timerData;

      // 마지막 session 불러오기

      String weekStart = _timerData?['week_start'] ?? getWeekStart(DateTime.now());
      _totalSessionDuration = await _statsProvider.getTotalDurationForWeek(weekStart);
      int totalSeconds = _timerData?['total_seconds'] ?? 360000; // 기본값 100시간
      _remainingSeconds = (totalSeconds - _totalSessionDuration).clamp(0, totalSeconds);

      _isRunning = (_timerData!['is_running'] ?? 0) == 1;

      if (_isRunning) {
        String lastSessionId = _timerData?['last_session_id'] ?? '';
        final lastSession = await _dbService.getSession(lastSessionId);
        DateTime now = DateTime.now().toUtc();
        DateTime startTime = DateTime.parse(lastSession!['start_time']).toUtc();
        _currentSessionId = lastSessionId;
        _currentSessionMode = lastSession['mode'];
        _currentSessionDuration = now.difference(startTime).inSeconds;
        _currentSessionTargetDuration = lastSession['target_duration'];
        _currentActivityId = lastSession['activity_id'];

        Fluttertoast.showToast(
          msg: "활동 재개",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.redAccent.shade200,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      } else {
        // 새로운 세션 시작을 위한 초기화
        print("새로운세션을 위한 초기화작업");
        _timer?.cancel();
        _currentSessionDuration = 0;
        _currentSessionMode = "";
        _currentSessionTargetDuration = _remainingSeconds;
        _currentSessionId = null;
      }

      // setting
      print('_currentActivityId: $_currentActivityId');
      if (_currentActivityId != null && _currentActivityId!.isNotEmpty) {
        _setLastActivty(lastActivityId: _currentActivityId);
      } else {
        _setDefaultActivity();
      }
      notifyListeners();
    } catch (e) {
      await _errorService.createError(
        errorCode: 'SET_TIMER_DATA_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Setting Timer Data',
        severityLevel: 'high',
      );
      print('Error in setTimerData: $e');
    }
  }

  Future<void> _setLastActivty({required lastActivityId}) async {
    try {
      final lastActivity = await _statsProvider.getActivityById(lastActivityId);
      if (lastActivity != null && lastActivity.isNotEmpty) {
        _currentActivityId = lastActivity['activity_id'];
        _currentActivityName = lastActivity['activity_name'];
        _currentActivityIcon = lastActivity['activity_icon'];
        _currentActivityColor = lastActivity['activity_color'];
        notifyListeners();
      } else {
        await _setDefaultActivity();
      }
    } catch (e) {
      await _errorService.createError(
        errorCode: 'UPDATE_ACTIVITY_DETAILS_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Updating last Activity Details',
        severityLevel: 'high',
      );
      print('Error updating last activity details: $e');
    }
  }

  Future<void> _setDefaultActivity() async {
    try {
      final defaultActivity = await _statsProvider.getDefaultActivity();
      if (defaultActivity != null) {
        _currentActivityId = defaultActivity['activity_id'];
        _currentActivityName = defaultActivity['activity_name'];
        _currentActivityIcon = defaultActivity['activity_icon'];
        _currentActivityColor = defaultActivity['activity_color'];
        notifyListeners();
      } else {
        // 기본 활동이 없을 경우 에러 처리
        await _errorService.createError(
          errorCode: 'DEFAULT_ACTIVITY_NOT_FOUND',
          errorMessage: 'No default activity found for the user.',
          errorAction: 'Setting Default Activity',
          severityLevel: 'medium',
        );
        print('Error: No default activity found for the user.');
      }
    } catch (e) {
      await _errorService.createError(
        errorCode: 'SET_DEFAULT_ACTIVITY_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Setting Default Activity',
        severityLevel: 'high',
      );
      print('Error setting default activity: $e');
    }
  }

/*

    @Dispose
    @Lifecycle
    @Background

*/

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    try {
      if (state == AppLifecycleState.paused) {
        _onAppPaused();
      } else if (state == AppLifecycleState.resumed) {
        _onAppResumed();
      }
    } catch (e) {
      _errorService.createError(
        errorCode: 'APP_LIFECYCLE_ERROR',
        errorMessage: e.toString(),
        errorAction: 'Handling AppLifecycleState',
        severityLevel: 'high',
      );
      print('Error in didChangeAppLifecycleState: $e');
    }
  }

  void _onAppPaused() async {
    print('_onAppPaused called');
    try {
      // 현재 상태를 데이터베이스에 저장
      await _updateTimerDataInDatabase();
      // 타이머 정지
      _timer?.cancel();
    } catch (e) {
      await _errorService.createError(
        errorCode: 'APP_PAUSED_ERROR',
        errorMessage: e.toString(),
        errorAction: 'Pausing App Timer',
        severityLevel: 'high',
      );
      print('Error during _onAppPaused: $e');
    }
  }

  void _onAppResumed() async {
    print('_onAppResumed called');
    try {
      DateTime now = DateTime.now();
      String weekStart = getWeekStart(now);

      Map<String, dynamic>? timer = await _dbService.getTimer(weekStart);
      if (timer == null) return;

      String lastSessionId = timer['last_session_id'] ?? '';
      final session = await _dbService.getSession(lastSessionId);

      // 작동 중이던 세션이 있는지 확인
      if (session != null && session['end_time'] == null && timer['is_running'] == 1) {
        // resumeTimer를 통해 타이머 재시작
        resumeTimer(sessionId: lastSessionId);

        notifyListeners();
      }
    } catch (e) {
      await _errorService.createError(
        errorCode: 'APP_RESUMED_ERROR',
        errorMessage: e.toString(),
        errorAction: 'Resuming App Timer',
        severityLevel: 'high',
      );
      print('Error during _onAppResumed: $e');
    }
  }

  /*

      @start Timer


  */

  void setSessionModeAndTargetDuration({required String mode, required int targetDuration}) {
    _currentSessionMode = mode;
    _currentSessionTargetDuration = targetDuration;
  }

  Future<void> startTimer({required String activityId, required String mode, required int targetDuration}) async {
    try {
      _isExceeded = false;
      _currentSessionId = null;
      print("스타트 타이머~");
      DateTime now = DateTime.now();
      DateTime utcNow = now.toUtc();
      String weekStart = getWeekStart(now);

      // 타이머 데이터 가져오기
      final timerData = _timerData;

      if (timerData == null) {
        print('타이머 데이터를 찾을 수 없습니다.');
        await _errorService.createError(
          errorCode: 'TIMER_NOT_FOUND',
          errorMessage: 'Timer data not found for weekStart: $weekStart.',
          errorAction: 'Starting timer',
          severityLevel: 'medium',
        );
        return;
      }

      _timer?.cancel();

      final defaultActivity = await _statsProvider.getDefaultActivity();

      // 새 session 생성
      try {
        final sessionId = const Uuid().v4();
        await _dbService.createSession(
          sessionId: sessionId,
          timerId: _timerData!['timer_id'],
          activityId: _currentActivityId ?? defaultActivity!['activity_id'],
          activityName: _currentActivityName,
          activityIcon: _currentActivityIcon,
          activityColor: _currentActivityColor,
          mode: mode,
          targetDuration: targetDuration,
        );
        _currentActivityId = activityId;
        _currentSessionId = sessionId;
        _currentSessionMode = mode;
        _currentSessionTargetDuration = targetDuration;
        _currentSessionDuration = 0;
        _setLastActivty(lastActivityId: _currentActivityId);
      } catch (e) {
        print("Error creating new session: $e");
        await _errorService.createError(
          errorCode: 'SESSION_CREATION_FAILED',
          errorMessage: e.toString(),
          errorAction: 'Creating new session',
          severityLevel: 'high',
        );
        return;
      }

      // 타이머 데이터 업데이트
      try {
        await _dbService.updateTimer(
          _timerData!['timer_id'],
          {
            'last_started_at': utcNow.toIso8601String(),
            'last_updated_at': utcNow.toIso8601String(),
            'last_session_id': _currentSessionId,
            'is_running': 1,
          },
        );
      } catch (e) {
        print("Error updating timer data: $e");
        await _errorService.createError(
          errorCode: 'TIMER_UPDATE_FAILED',
          errorMessage: e.toString(),
          errorAction: 'Updating timer data',
          severityLevel: 'high',
        );
        return;
      }

      // 타이머 시작
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _onTimerTick();
      });

      print('Timer started. _isRunning: $_isRunning');
    } catch (e) {
      print("Error in startTimer: $e");
      await _errorService.createError(
        errorCode: 'TIMER_START_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Starting timer',
        severityLevel: 'critical',
      );
    }
  }

  Future<void> resumeTimer({required String sessionId}) async {
    try {
      print("resume 타이머~");
      DateTime now = DateTime.now().toUtc();

      // 타이머 데이터 가져오기
      final timerData = _timerData;

      if (timerData == null) {
        print('타이머 데이터를 찾을 수 없습니다.');
        await _errorService.createError(
          errorCode: 'TIMER_NOT_FOUND',
          errorMessage: 'Timer data not found for weekStart',
          errorAction: 'Starting timer',
          severityLevel: 'medium',
        );
        return;
      }

      _timer?.cancel();

      final lastSession = await _dbService.getSession(sessionId);

      if (lastSession != null && lastSession.isNotEmpty) {
        DateTime startTime = DateTime.parse(lastSession['start_time']);
        int elapsedSeconds = now.difference(startTime).inSeconds;

        _currentSessionId = sessionId;
        _currentSessionMode = lastSession['mode'];
        _currentSessionDuration = elapsedSeconds;
        _currentSessionTargetDuration = lastSession['target_duration'];
        _currentActivityId = lastSession['activity_id'];
        _currentActivityName = lastSession['activity_name'];
        _currentActivityIcon = lastSession['activity_icon'];
        _currentActivityColor = lastSession['activity_color'];
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _onTimerTick();
      });
    } catch (e) {
      print("Error in resuming: $e");
      await _errorService.createError(
        errorCode: 'TIMER_RESUME_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Resuming timer',
        severityLevel: 'critical',
      );
    }
  }

  void clearNavigationRequest() {
    _navigationRequest = null;
    notifyListeners();
  }

  void _onTimerTick() async {
    try {
      // 1. 시간 업데이트
      _currentSessionDuration++;
      _remainingSeconds--;

      // 2. exceeded 체크 (목표 시간 도달 또는 remaining seconds 소진)
      bool isExceeded = _currentSessionDuration >= (_currentSessionTargetDuration ?? _remainingSeconds) || _remainingSeconds <= 0;

      if (isExceeded) {
        // exceeded 시 세션 시간을 목표 시간으로 고정
        _currentSessionDuration = (_currentSessionTargetDuration ?? _remainingSeconds);
        _isExceeded = true;

        // 타이머 정지
        stopTimer(isExceeded: true, sessionId: _currentSessionId!);
        notifyListeners(); // duration 고정을 UI에 반영

        return;
      }

      notifyListeners();
    } catch (e) {
      print('Error during timer tick: $e');
      await _errorService.createError(
        errorCode: 'TIMER_TICK_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Timer tick update failed',
        severityLevel: 'high',
      );
    }
  }

  Future<void> stopTimer({required bool isExceeded, required String sessionId}) async {
    print('stopTimer called : $sessionId');

    try {
      // 타이머 즉시 중지
      _timer?.cancel();
      _isRunning = false;

      // 세션 종료
      final currentSession = await _dbService.getSession(sessionId);

      final startTime = DateTime.parse(currentSession!['start_time'] as String);
      DateTime endTime;
      int totalDuration = _currentSessionDuration;

      if (isExceeded) {
        // exceeded인 경우 시작시간 + 현재 세션 지속시간을 끝 시간으로 설정
        endTime = startTime.add(Duration(seconds: _currentSessionDuration));
      } else {
        // 일반 종료인 경우 현재 시간을 끝 시간으로
        endTime = DateTime.now().toUtc();
      }

      await _dbService.endSession(
        sessionId: sessionId,
        endTime: endTime.toIso8601String(),
        duration: totalDuration,
      );

      // 타이머 상태 업데이트
      print('timerID : ${_timerData!['timer_id']}');
      await _dbService.updateTimer(_timerData!['timer_id'], {
        'is_running': 0,
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
        'last_ended_at': DateTime.now().toUtc().toIso8601String(),
      });
      _timerData = await _dbService.getTimer(getWeekStart(DateTime.now()));

      // session 초기화
      resetCurrentSession();
      print("초기화 결과 : ${_currentSessionId}");

      notifyListeners();
    } catch (e) {
      print('Error stopping timer: $e');
      await _errorService.createError(
        errorCode: 'TIMER_STOP_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Stopping timer',
        severityLevel: 'critical',
      );
    }
  }

  void resetCurrentSession() {
    _currentSessionId = null;
    _currentSessionDuration = 0;
    _currentSessionMode = 'SESINORM';
    _currentSessionTargetDuration = _remainingSeconds;
  }

  Future<void> _updateTimerDataInDatabase() async {
    try {
      DateTime now = DateTime.now();
      DateTime utcNow = now.toUtc();
      String weekStart = getWeekStart(now);
      final timerData = await _dbService.getTimer(weekStart);

      if (timerData != null) {
        final String timerId = timerData['timer_id'];

        Map<String, dynamic> updatedData = {
          'is_running': _isRunning ? 1 : 0,
          'last_updated_at': utcNow.toIso8601String(),
        };

        await _dbService.updateTimer(timerId, updatedData);
      } else {
        print('Timer data not found for weekStart: $weekStart');
        await _errorService.createError(
          errorCode: 'TIMER_DATA_NOT_FOUND',
          errorMessage: 'No timer data found for weekStart: $weekStart',
          errorAction: 'Fetching timer data in _updateTimerDataInDatabase',
          severityLevel: 'medium',
        );
      }
    } catch (e) {
      print('Error updating timer data in database: $e');
      await _errorService.createError(
        errorCode: 'UPDATE_TIMER_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Updating timer data in _updateTimerDataInDatabase',
        severityLevel: 'high',
      );
    }
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  String _formatHour(int seconds) {
    final hours = seconds ~/ 3600;
    return '${hours}h';
  }

  String getWeekStart(DateTime date) {
    int weekday = date.weekday;
    DateTime weekStart = date.subtract(Duration(days: weekday - 1));
    return weekStart.toIso8601String().split('T').first;
  }

  List<Map<String, dynamic>> get weeklyActivityData {
    return _weeklyActivityData.entries.map((entry) {
      int hours = entry.value ~/ 60;
      int minutes = (entry.value % 60).toInt(); // double을 int로 변환
      return {'day': entry.key, 'hours': hours, 'minutes': minutes};
    }).toList();
  }

// 주간 활동 데이터 초기화 메서드
  void initializeWeeklyActivityData() async {
    try {
      List<Map<String, dynamic>> logs = await activityLogs; // 활동 로그 데이터 가져오기

      // 주간 데이터를 초기화
      _weeklyActivityData.updateAll((key, value) => 0.0);

      for (var log in logs) {
        try {
          // 로그 데이터의 필드 유효성 검사
          if (log['start_time'] == null || !(log['start_time'] is String)) {
            throw Exception('Invalid or missing start_time in log: $log');
          }

          String startTimeString = log['start_time'];
          int duration = log['session_duration'] ?? 0;
          int restTime = log['rest_time'] ?? 0; // rest_time 가져오기

          if (startTimeString.isNotEmpty) {
            DateTime startTime = DateTime.parse(startTimeString).toLocal();
            String dayOfWeek = DateFormat.E('ko_KR').format(startTime);

            // 실제 활동 시간 계산
            double actualDuration = (duration - restTime) / 60.0;

            // 주간 활동 데이터에 추가 (분 단위)
            _weeklyActivityData[dayOfWeek] = (_weeklyActivityData[dayOfWeek] ?? 0) + actualDuration;
          }
        } catch (e) {
          // 개별 로그 처리 중 에러 발생 시 로그 기록 및 저장
          print('Error processing log: $log, Error: $e');
          await _errorService.createError(
            errorCode: 'PROCESS_LOG_FAILED',
            errorMessage: e.toString(),
            errorAction: 'Processing individual log in initializeWeeklyActivityData',
            severityLevel: 'medium',
          );
          continue; // 다른 로그 처리 계속
        }
      }

      if (!_disposed) {
        // dispose 여부 확인
        notifyListeners();
      }
    } catch (e) {
      // 메서드 전체 실행 중 에러 처리
      print('Error initializing weekly activity data: $e');
      await _errorService.createError(
        errorCode: 'INITIALIZE_WEEKLY_ACTIVITY_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Initializing weekly activity data in initializeWeeklyActivityData',
        severityLevel: 'high',
      );
    }
  }

// activityLogs 메서드 추가 - 활동 로그 가져오기
  Future<List<Map<String, dynamic>>> get activityLogs async {
    try {
      DateTime now = DateTime.now();
      // 주 시작과 종료 날짜 설정
      DateTime weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      DateTime weekEnd = weekStart.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));

      // 모든 활동 로그 가져오기
      List<Map<String, dynamic>> allLogs = await _dbService.getAllSessions();

      // 이번 주의 활동 로그만 필터링
      List<Map<String, dynamic>> weeklyLogs = allLogs.where((log) {
        try {
          // 로그의 시작 시간 유효성 검사
          String? startTimeString = log['start_time'];

          if (startTimeString != null && startTimeString.isNotEmpty) {
            DateTime startTime = DateTime.parse(startTimeString).toLocal();
            return !startTime.isBefore(weekStart) && startTime.isBefore(weekEnd);
          }
        } catch (e) {
          print('Error parsing log: $log, Error: $e');
          _errorService.createError(
            errorCode: 'ACTIVITY_LOG_PARSE_FAILED',
            errorMessage: e.toString(),
            errorAction: 'Filtering logs in activityLogs',
            severityLevel: 'medium',
          );
        }
        return false; // 유효하지 않은 로그는 제외
      }).toList();

      return weeklyLogs;
    } catch (e) {
      print('Error fetching activity logs: $e');
      await _errorService.createError(
        errorCode: 'FETCH_ACTIVITY_LOGS_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Fetching all activity logs in activityLogs',
        severityLevel: 'high',
      );
      return []; // 에러 발생 시 빈 리스트 반환
    }
  }

// 활동 데이터를 저장할 맵
  Map<DateTime, int> _heatMapDataSet = {};

// heatMapDataSet의 getter
  Map<DateTime, int> get heatMapDataSet => _heatMapDataSet;

// 활동 로그 데이터를 기반으로 heatmap 데이터를 초기화하는 메서드
  Future<void> initializeHeatMapData() async {
    try {
      // DB에서 모든 세션 데이터를 가져옴
      List<Map<String, dynamic>> logs = await _dbService.getAllSessions();

      // 맵 초기화
      _heatMapDataSet = {};

      for (var log in logs) {
        try {
          String? startTimeString = log['start_time'];
          int duration = log['session_duration'] ?? 0;

          // 시작 시간이 존재하고 비어있지 않은 경우만 처리
          if (startTimeString != null && startTimeString.isNotEmpty) {
            DateTime date = DateTime.parse(startTimeString).toLocal();

            // 날짜만 사용하는 방식으로 변환
            DateTime dateOnly = DateTime(date.year, date.month, date.day);

            // duration이 음수인 경우 0으로 처리
            int effectiveDuration = max(0, duration);

            // 기존 값이 있으면 누적, 없으면 새로 추가
            _heatMapDataSet.update(
              dateOnly,
              (existing) => existing + (effectiveDuration ~/ 60), // 분 단위로 변환하여 누적
              ifAbsent: () => (effectiveDuration ~/ 60), // 분 단위로 변환하여 저장
            );
          } else {
            // 시작 시간이 없는 경우 에러 기록
            throw Exception('Missing or invalid start_time in log: $log');
          }
        } catch (e) {
          // 개별 로그 처리 중 에러 발생 시 에러 서비스에 기록
          print('Error processing log: $log, Error: $e');
          await _errorService.createError(
            errorCode: 'HEATMAP_LOG_PROCESS_FAILED',
            errorMessage: e.toString(),
            errorAction: 'Processing individual log in initializeHeatMapData',
            severityLevel: 'medium',
          );
        }
      }

      // 데이터 갱신 알림
      notifyListeners();
    } catch (e) {
      // 전체 초기화 과정에서 에러 발생 시 에러 서비스에 기록
      print('Error initializing heatmap data: $e');
      await _errorService.createError(
        errorCode: 'HEATMAP_INITIALIZATION_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Initializing heatmap data in initializeHeatMapData',
        severityLevel: 'high',
      );
    }
  }
}
