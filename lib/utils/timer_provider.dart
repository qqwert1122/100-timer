import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/error_service.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:uuid/uuid.dart';

class TimerProvider with ChangeNotifier, WidgetsBindingObserver {
  final BuildContext context;
  DatabaseService _dbService;
  final StatsProvider _statsProvider;
  ErrorService _errorService; // ErrorService 주입
  TimerProvider(
    this.context, {
    required DatabaseService dbService,
    required StatsProvider statsProvider,
    required ErrorService errorService,
  })  : _dbService = dbService,
        _statsProvider = statsProvider,
        _errorService = errorService {
    try {
      // WidgetsBindingObserver 등록
      WidgetsBinding.instance.addObserver(this);
      setTimer(); // 초기화
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

  void updateDependencies({
    required DatabaseService dbService,
    required ErrorService errorService,
  }) {
    _dbService = dbService;
    _errorService = errorService;
    // statsProvider, authProvider는 수정이 필요하면 인자로 추가하세요.
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
  bool _shouldNotify = false;

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
  String get formattedActivityTime =>
      _formatTime(_currentSessionDuration.clamp(0, _totalSeconds));
  String get formattedTotalSessionDuration =>
      _formatTime(_totalSessionDuration);
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

  String _currentState = 'STOP';
  String get currentState => _currentState;

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

  Future<void> setTimer() async {
    try {
      // 해당 주차의 타이머 가져오기
      String weekStart = getWeekStart(DateTime.now());
      final rawTimerData = await _dbService.getTimer(weekStart);

      if (rawTimerData != null) {
        _timerData = Map<String, dynamic>.from(rawTimerData);
        _totalSeconds = _timerData?['total_seconds'];
        _isRunning = (_timerData?['state'] ?? 'STOP') != 'STOP';
      } else {
        _timerData = await _createNewTimer(weekStart);
        _totalSeconds = _timerData?['total_seconds'] ?? 360000;
        _isRunning = false;
      }

      // 세션의 duration 합 계산
      _totalSessionDuration =
          await _statsProvider.getTotalDurationForWeek(weekStart);

      // 남은 시간 계산
      _remainingSeconds =
          (_totalSeconds - _totalSessionDuration).clamp(0, _totalSeconds);

      // (3) 만약 타이머가 'RUNNING','PAUSED' 상태라면, 마지막 세션 정보를 불러오고 세팅
      if (_isRunning) {
        String lastSessionId = _timerData?['session_id'] ?? '';
        if (lastSessionId.isNotEmpty) {
          final lastSession = await _dbService.getSession(lastSessionId);
          if (lastSession != null && lastSession.isNotEmpty) {
            _currentSessionMode = lastSession['mode'];
            _currentSessionDuration = lastSession['session_duration'];
            _currentSessionTargetDuration = lastSession['target_duration'];
            _currentActivityId = lastSession['activity_id'];
            _currentActivityName = lastSession['activity_name'];
            _currentActivityIcon = lastSession['activity_icon'];
            _currentActivityColor = lastSession['activity_color'];
          }
        }
      }

      // 10분 이상 세션 수 갱신
      int sessionsOver1hour =
          await _statsProvider.getSessionsOver1HourCount(weekStart);
      _dbService.updateTimer(_timerData?['timer_id'], {
        'sessions_over_1hour': sessionsOver1hour,
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      _timerData = await _dbService.getTimer(weekStart);

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

  Future<Map<String, dynamic>> _createNewTimer(String weekStart) async {
    try {
      // int userTotalSeconds = userData?['total_seconds'] ?? 360000;
      int userTotalSeconds = 360000;

      String timerId = const Uuid().v4();
      String now = DateTime.now().toUtc().toIso8601String();
      Map<String, dynamic> timerData = {
        'timer_id': timerId,
        'current_session_id': null,
        'week_start': weekStart,
        'total_seconds': userTotalSeconds,
        'timer_state': 'STOP',
        'created_at': now,
        'deleted_at': null,
        'last_started_at': null,
        'last_ended_at': null,
        'last_updated_at': now,
        'is_deleted': 0,
        'timezone': DateTime.now().timeZoneName,
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
  void setCurrentActivity(String activityId, String activityName,
      String activityIcon, String activityColor) {
    _currentActivityId = activityId;
    _currentActivityName = activityName;
    _currentActivityIcon = activityIcon;
    _currentActivityColor = activityColor;
    notifyListeners();
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

      String lastSessionId = timer['session_id'] ?? '';

      // 작동 중이던 세션이 있는지 확인
      if (timer['state'] == 'RUNNING') {
        // restartTimer 통해 타이머 재시작
        restartTimer(sessionId: lastSessionId);

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

    @refrest

  */

  void refreshRemainingSeconds() async {
    String weekStart = getWeekStart(DateTime.now());
    final _totalSeconds = timerData!['total_seconds'];

    _totalSessionDuration =
        await _statsProvider.getTotalDurationForWeek(weekStart);
    _remainingSeconds =
        (_totalSeconds - _totalSessionDuration).clamp(0, _totalSeconds);
  }

  /*

      @start Timer


  */

  void setSessionModeAndTargetDuration(
      {required String mode, required int targetDuration}) {
    _currentSessionMode = mode;
    _currentSessionTargetDuration = targetDuration;
  }

  Future<void> startTimer(
      {required String activityId,
      required String mode,
      required int targetDuration}) async {
    try {
      DateTime now = DateTime.now();
      DateTime utcNow = now.toUtc();

      _timer?.cancel();

      // activity?
      final activity = await _statsProvider.getActivityById(activityId);

      // create Session
      final sessionId = const Uuid().v4();
      await _dbService.createSession(
        sessionId: sessionId,
        timerId: _timerData!['timer_id'],
        activityId: activity!['activity_id'],
        activityName: activity['activity_name'],
        activityIcon: activity['activity_icon'],
        activityColor: activity['activity_color'],
        mode: mode,
        targetDuration: targetDuration,
      );

      await _dbService.updateTimer(
        _timerData!['timer_id'],
        {
          'last_started_at': utcNow.toIso8601String(),
          'last_updated_at': utcNow.toIso8601String(),
          'session_id': sessionId,
          'state': 'RUNNING',
        },
      );
      _currentState = "RUNNING";
      _currentSessionMode = mode;
      _currentSessionTargetDuration = targetDuration;
      _currentSessionDuration = 0;
      _isRunning = true;
      _currentActivityId = activity['activity_id'];
      _currentActivityName = activity['activity_name'];
      _currentActivityIcon = activity['activity_icon'];
      _currentActivityColor = activity['activity_color'];

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _onTimerTick(sessionId: sessionId);
      });
    } catch (e) {
      rethrow;
    }
  }

  // AppResume 시 state == 'RUNNING'일 경우
  Future<void> restartTimer({required String sessionId}) async {
    try {
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

      DateTime lastUpdatedAt = DateTime.parse(lastSession!['last_updated_at']);
      int elapsedSeconds = now.difference(lastUpdatedAt).inSeconds;
      _currentState = 'RUNNING';
      _currentSessionMode = lastSession['mode'];
      _currentSessionTargetDuration = lastSession['target_duration'];
      _currentSessionDuration =
          lastSession['session_duration'] + elapsedSeconds;
      _isRunning = true;
      _currentActivityId = lastSession['activity_id'];
      _currentActivityName = lastSession['activity_name'];
      _currentActivityIcon = lastSession['activity_icon'];
      _currentActivityColor = lastSession['activity_color'];

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _onTimerTick(sessionId: timerData['session_id']);
      });
    } catch (e) {
      print("Error in restarting: $e");
      await _errorService.createError(
        errorCode: 'TIMER_RESTART_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Restart timer',
        severityLevel: 'critical',
      );
    }
  }

  Future<void> resumeTimer({required String sessionId}) async {
    try {
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

      await _dbService.updateTimer(
        _timerData!['timer_id'],
        {
          'last_updated_at': now.toIso8601String(),
          'state': 'RUNNING',
        },
      );
      _currentState = 'RUNNING';
      _currentSessionMode = lastSession!['mode'];
      _currentSessionTargetDuration = lastSession['target_duration'];
      _currentSessionDuration = lastSession['session_duration'];
      _isRunning = true;
      _currentActivityId = lastSession['activity_id'];
      _currentActivityName = lastSession['activity_name'];
      _currentActivityIcon = lastSession['activity_icon'];
      _currentActivityColor = lastSession['activity_color'];

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _onTimerTick(sessionId: timerData['session_id']);
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

  Future<void> pauseTimer() async {
    DateTime now = DateTime.now();
    DateTime utcNow = now.toUtc();

    try {
      _timer?.cancel();
      await _dbService.updateTimer(
        _timerData!['timer_id'],
        {
          'last_updated_at': utcNow.toIso8601String(),
          'state': 'PAUSED',
        },
      );
      _currentState = 'PAUSED';
    } catch (e) {
      rethrow;
    }
  }

  void clearNavigationRequest() {
    _navigationRequest = null;
    notifyListeners();
  }

  void _onTimerTick({required String sessionId}) async {
    try {
      _currentSessionDuration++;
      _remainingSeconds--;

      _dbService.updateSession(
          sessionId: sessionId, seconds: _currentSessionDuration);

      bool isExceeded = _currentSessionDuration >=
              (_currentSessionTargetDuration ?? _remainingSeconds) ||
          _remainingSeconds <= 0;
      if (isExceeded) {
        // exceeded 시 세션 시간을 목표 시간으로 고정
        _currentSessionDuration =
            (_currentSessionTargetDuration ?? _remainingSeconds);
        _isExceeded = true;

        // 타이머 정지
        stopTimer(isExceeded: true, sessionId: sessionId);
        notifyListeners(); // duration 고정을 UI에 반영

        return;
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stopTimer(
      {required bool isExceeded, required String sessionId}) async {
    print('stopTimer called : $sessionId');

    try {
      // 타이머 즉시 중지
      _timer?.cancel();
      _isRunning = false;

      // 세션 종료 로직
      final currentSession = await _dbService.getSession(sessionId);

      // 1) currentSession null 체크
      if (currentSession == null) {
        print('No session found for sessionId: $sessionId');
        return;
      }
      if (currentSession['start_time'] == null) {
        print('Session has no start_time. sessionId: $sessionId');
        return;
      }

      final startTime = DateTime.parse(currentSession['start_time'] as String);
      DateTime endTime;
      int totalDuration = _currentSessionDuration;

      if (isExceeded) {
        endTime = startTime.add(Duration(seconds: _currentSessionDuration));
      } else {
        endTime = DateTime.now().toUtc();
      }

      await _dbService.endSession(
        sessionId: sessionId,
        endTime: endTime.toIso8601String(),
        duration: totalDuration,
      );

      // 2) _timerData 및 'timer_id' 체크
      if (_timerData == null || !_timerData!.containsKey('timer_id')) {
        print(
            'Error: _timerData or timer_id is null => cannot update timer status');
        return;
      }
      await _dbService.updateTimer(
        _timerData!['timer_id'],
        {
          'last_updated_at': DateTime.now().toUtc().toIso8601String(),
          'last_ended_at': DateTime.now().toUtc().toIso8601String(),
          'state': 'STOP',
        },
      );
      _currentState = 'STOP';
      _timerData = await _dbService.getTimer(getWeekStart(DateTime.now()));
      _isExceeded = false;

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
    _currentSessionDuration = 0;
    _currentSessionMode = 'SESSIONNORMAL';
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
          'state': _isRunning ? 'RUNNING' : 'STOP',
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
            _weeklyActivityData[dayOfWeek] =
                (_weeklyActivityData[dayOfWeek] ?? 0) + actualDuration;
          }
        } catch (e) {
          // 개별 로그 처리 중 에러 발생 시 로그 기록 및 저장
          print('Error processing log: $log, Error: $e');
          await _errorService.createError(
            errorCode: 'PROCESS_LOG_FAILED',
            errorMessage: e.toString(),
            errorAction:
                'Processing individual log in initializeWeeklyActivityData',
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
        errorAction:
            'Initializing weekly activity data in initializeWeeklyActivityData',
        severityLevel: 'high',
      );
    }
  }

// activityLogs 메서드 추가 - 활동 로그 가져오기
  Future<List<Map<String, dynamic>>> get activityLogs async {
    try {
      DateTime now = DateTime.now();
      // 주 시작과 종료 날짜 설정
      DateTime weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      DateTime weekEnd = weekStart
          .add(const Duration(days: 7))
          .subtract(const Duration(seconds: 1));

      // 모든 활동 로그 가져오기
      List<Map<String, dynamic>> allLogs =
          await _dbService.getSessionsWithinDateRange(
        startDate: weekStart,
        endDate: weekEnd,
      );

      // 이번 주의 활동 로그만 필터링
      List<Map<String, dynamic>> weeklyLogs = allLogs.where((log) {
        try {
          // 로그의 시작 시간 유효성 검사
          String? startTimeString = log['start_time'];

          if (startTimeString != null && startTimeString.isNotEmpty) {
            DateTime startTime = DateTime.parse(startTimeString).toLocal();
            return !startTime.isBefore(weekStart) &&
                startTime.isBefore(weekEnd);
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
      DateTime now = DateTime.now();
      // 주 시작과 종료 날짜 설정
      DateTime weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      DateTime weekEnd = weekStart
          .add(const Duration(days: 7))
          .subtract(const Duration(seconds: 1));

      // DB에서 모든 세션 데이터를 가져옴
      List<Map<String, dynamic>> logs =
          await _dbService.getSessionsWithinDateRange(
        startDate: weekStart,
        endDate: weekEnd,
      );

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
              (existing) =>
                  existing + (effectiveDuration ~/ 60), // 분 단위로 변환하여 누적
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
