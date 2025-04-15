import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:uuid/uuid.dart';

class TimerProvider with ChangeNotifier, WidgetsBindingObserver {
  final BuildContext context;
  DatabaseService _dbService;
  final StatsProvider _statsProvider;
  TimerProvider(
    this.context, {
    required DatabaseService dbService,
    required StatsProvider statsProvider,
  })  : _dbService = dbService,
        _statsProvider = statsProvider {
    try {
      // WidgetsBindingObserver 등록
      WidgetsBinding.instance.addObserver(this);
      setTimer();
      Future.delayed(Duration.zero, () {
        initializeFromLastSession();
      });
    } catch (e) {
      // error log
      print('Error initializing TimerProvider: $e');
    }
  }

  void updateDependencies({
    required DatabaseService dbService,
  }) {
    _dbService = dbService;
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
  final bool _shouldNotify = false;

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

  String get formattedTime => _formatTime(_remainingSeconds);
  String get formattedHour => _formatHour(_remainingSeconds);
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

  Future<void> initializeFromLastSession() async {
    try {
      // timer 불러오기
      String weekStart = getWeekStart(DateTime.now());
      final timer = await _dbService.getTimer(weekStart);

      if (timer == null) return;

      // current_session 불러오기
      String sessionId = timer['current_session_id'] ?? '';
      if (sessionId.isEmpty) return;

      // 진행 중이던 세션이 있는지 확인
      if (timer['timer_state'] == 'RUNNING') {
        // timer_state가 RUNNING일 경우
        // timer에 부착된 session 불러오기기
        final session = await _dbService.getSession(sessionId);
        if (session == null) return;

        // 타이머가 작동중인데 백그라운드로 이동했거나 강제종료 되었으므로 경과 시간 계산 필요
        // 시간 계산 - 앱 종료 시점부터 현재까지 경과 시간
        DateTime lastUpdatedAt = DateTime.parse(session['last_updated_at']);
        DateTime now = DateTime.now();
        int elapsedSeconds = now.difference(lastUpdatedAt).inSeconds;

        // 총 진행 시간 = 저장된 진행 시간 + 앱 종료 후 경과 시간
        int totalDuration = session['duration'] + elapsedSeconds;

        // 시간이 경과했으므로 목표 시간 초과 여부 확인
        int targetDuration = session['target_duration'] ?? _totalSeconds;
        if (totalDuration >= targetDuration) {
          // 초과했을 경우 세션 완료 처리
          await stopTimer(isExceeded: true, sessionId: sessionId);
          _isExceeded = true;
        } else {
          // 초과하지 않았을 경우 계속 작동해야 하므로 세션 상태 복원
          _currentSessionMode = session['mode'];
          _currentSessionDuration = totalDuration;
          _currentSessionTargetDuration = targetDuration;
          _currentActivityId = session['activity_id'];
          _currentActivityName = session['activity_name'];
          _currentActivityIcon = session['activity_icon'];
          _currentActivityColor = session['activity_color'];
          _currentState = 'RUNNING';
          _isRunning = true;

          // 타이머 재시작
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            _onTimerTick(sessionId: sessionId);
          });

          // DB 업데이트
          await _dbService.updateSession(
            sessionId: sessionId,
            seconds: totalDuration,
          );
        }

        notifyListeners();
      } else if (timer['timer_state'] == 'PAUSED') {
        // timer가 PAUSED일 경우
        // timer에 부착된 session 불러오기
        final session = await _dbService.getSession(sessionId);
        if (session == null) return;

        // 세션 상태 복원
        _currentSessionMode = session['mode'];
        _currentSessionDuration = session['duration'];
        _currentSessionTargetDuration = session['target_duration'];
        _currentActivityId = session['activity_id'];
        _currentActivityName = session['activity_name'];
        _currentActivityIcon = session['activity_icon'];
        _currentActivityColor = session['activity_color'];
        _currentState = 'PAUSED';
        _isRunning = true;
      }
    } catch (e) {
      logger.e('Error initializing from last session: $e');
    }
  }

  Future<void> setTimer() async {
    try {
      // 해당 주차의 타이머 가져오기
      String weekStart = getWeekStart(DateTime.now());
      final rawTimerData = await _dbService.getTimer(weekStart);

      if (rawTimerData != null) {
        _timerData = Map<String, dynamic>.from(rawTimerData);
        _totalSeconds = _timerData?['total_seconds'] ?? 360000;
        _isRunning = (_timerData?['timer_state'] ?? 'STOP') == 'RUNNING';
      } else {
        _timerData = await _createNewTimer(weekStart);
        _totalSeconds = _timerData?['total_seconds'] ?? 360000;
        _isRunning = false;
      }

      // 세션의 duration 합 계산
      _totalSessionDuration = await _statsProvider.getTotalDurationForCurrentWeek();

      // 세션 정보 확인
      if (_isRunning) {
        String lastSessionId = _timerData?['current_session_id'] ?? '';
        if (lastSessionId.isNotEmpty) {
          final lastSession = await _dbService.getSession(lastSessionId);
          if (lastSession != null && lastSession.isNotEmpty) {
            _currentSessionMode = lastSession['mode'];
            _currentSessionDuration = lastSession['duration'];
            _currentSessionTargetDuration = lastSession['target_duration'];
            _currentActivityId = lastSession['activity_id'];
            _currentActivityName = lastSession['activity_name'];
            _currentActivityIcon = lastSession['activity_icon'];
            _currentActivityColor = lastSession['activity_color'];

            // 현재 진행 중인 활동도 잔여시간에서 차감되어야 함
            _remainingSeconds = (_totalSeconds - _totalSessionDuration).clamp(0, _totalSeconds);
          }
        }
      }

      // 기타 현재 활동 정보 설정
      if (_currentActivityId != null && _currentActivityId!.isNotEmpty) {
        _setLastActivty(lastActivityId: _currentActivityId);
      } else {
        _setDefaultActivity();
      }

      _updateRemainingSeconds();

      notifyListeners();
    } catch (e) {
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
      // error log
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
      // error log
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
        // error log
      }
    } catch (e) {
      // error log
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
      // error log
    }
  }

  void _onAppPaused() async {
    print('_onAppPaused called');
    try {
      if (_currentState == 'RUNNING') {
        // 상태는 그대로 RUNNING으로 유지하고 마지막 업데이트 시간만 저장
        DateTime now = DateTime.now().toUtc();
        await _dbService.updateTimer(
          _timerData!['timer_id'],
          {
            'last_updated_at': now.toIso8601String(),
            // 'timer_state'는 변경하지 않음
          },
        );

        // 세션의 현재 진행 시간 저장
        String sessionId = _timerData?['current_session_id'] ?? '';
        if (sessionId.isNotEmpty) {
          await _dbService.updateSession(
            sessionId: sessionId,
            seconds: _currentSessionDuration,
          );
        }

        // 타이머는 취소하지만, 상태는 계속 'RUNNING'으로 유지
        _timer?.cancel();
      }
    } catch (e) {
      print('Error in _onAppPaused: $e');
    }
  }

  void _onAppResumed() async {
    print('_onAppResumed called');
    try {
      DateTime now = DateTime.now();
      String weekStart = getWeekStart(now);

      Map<String, dynamic>? timer = await _dbService.getTimer(weekStart);
      if (timer == null) return;

      String lastSessionId = timer['current_session_id'] ?? '';
      if (lastSessionId.isEmpty) return;

      // 작동 중이던 세션이 있는지 확인
      if (timer['timer_state'] == 'RUNNING') {
        final lastSession = await _dbService.getSession(lastSessionId);
        if (lastSession == null) return;

        // 마지막 업데이트 시간 이후 경과한 시간 계산
        DateTime lastUpdatedAt = DateTime.parse(lastSession['last_updated_at']);
        int elapsedSeconds = now.difference(lastUpdatedAt).inSeconds;

        // 세션의 진행 시간을 업데이트 (백그라운드에서 경과한 시간 포함)
        int updatedDuration = lastSession['duration'] + elapsedSeconds;
        await _dbService.updateSession(
          sessionId: lastSessionId,
          seconds: updatedDuration,
        );

        // 상태 업데이트
        _currentSessionDuration = updatedDuration;

        // 타이머 재시작
        restartTimer(sessionId: lastSessionId);
        notifyListeners();
      }
    } catch (e) {
      print('Error in _onAppResumed: $e');
    }
  }

  /*

      @refresh

    */

  void _updateRemainingSeconds() {
    _remainingSeconds = (_totalSeconds - _totalSessionDuration).clamp(0, _totalSeconds);
    notifyListeners();
  }

  Future<void> refreshRemainingSeconds() async {
    String weekStart = getWeekStart(DateTime.now());
    final totalSeconds = timerData!['total_seconds'];

    print("📅 Week start: $weekStart");
    print("🔄 기존 remainingSeconds: $_remainingSeconds");

    _totalSessionDuration = await _statsProvider.getTotalDurationForCurrentWeek();
    print("🕓 새 totalSessionDuration: $_totalSessionDuration");

    _updateRemainingSeconds();
    print("🟢 새 remainingSeconds: $_remainingSeconds");

    notifyListeners();
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
      // 현재 local날짜 계산해서 utc로 변환환
      DateTime now = DateTime.now();
      DateTime utcNow = now.toUtc();

      // 이미 실행중인 타이머가 있다면 cancel
      _timer?.cancel();

      // activityId를 통해 activity 호출
      final activity = await _statsProvider.getActivityById(activityId);

      // session 생성
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

      logger.d('timer_id: ${_timerData!['timer_id']}');
      logger.d('current_session_id: $sessionId');

      // timer에 current_session_id, timer_state를 업데이트트
      await _dbService.updateTimer(
        _timerData!['timer_id'],
        {
          'last_started_at': utcNow.toIso8601String(),
          'last_updated_at': utcNow.toIso8601String(),
          'current_session_id': sessionId,
          'timer_state': 'RUNNING',
        },
      );

      // 활동에 사용이력 남기기
      await _dbService.updateActivity(
        activityId: activity['activity_id'],
        isUsed: true,
      );

      // 업데이트한 timer를 다시 불러와 전역변수 업데이트
      _timerData = await _dbService.getTimer(_timerData!['week_start']);
      _currentState = "RUNNING";
      _currentSessionMode = mode;
      _currentSessionTargetDuration = targetDuration;
      _currentSessionDuration = 0;
      _isRunning = true;
      _currentActivityId = activity['activity_id'];
      _currentActivityName = activity['activity_name'];
      _currentActivityIcon = activity['activity_icon'];
      _currentActivityColor = activity['activity_color'];

      // 타이머 실행
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _onTimerTick(sessionId: sessionId);
      });
    } catch (e) {
      // 오류 발생 시 로그 기록 후 상위 호출자에게 예외 전파
      logger.e('타이머 시작 중 오류 발생: $e');
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
        // error log
        return;
      }

      _timer?.cancel();

      final lastSession = await _dbService.getSession(sessionId);

      DateTime lastUpdatedAt = DateTime.parse(lastSession!['last_updated_at']);
      int elapsedSeconds = now.difference(lastUpdatedAt).inSeconds;
      _currentState = 'RUNNING';
      _currentSessionMode = lastSession['mode'];
      _currentSessionTargetDuration = lastSession['target_duration'];
      _currentSessionDuration = lastSession['duration'] + elapsedSeconds;
      _isRunning = true;
      _currentActivityId = lastSession['activity_id'];
      _currentActivityName = lastSession['activity_name'];
      _currentActivityIcon = lastSession['activity_icon'];
      _currentActivityColor = lastSession['activity_color'];

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _onTimerTick(sessionId: timerData['current_session_id']);
      });
    } catch (e) {
      // error log
    }
  }

  Future<void> resumeTimer({required String sessionId, bool updateUIImmediately = false}) async {
    try {
      // sessionId 유효성 검사
      if (sessionId.isEmpty) {
        print('Warning: Invalid sessionId provided to resumeTimer');
        sessionId = _timerData?['current_session_id'];
      }

      // UI 즉시 업데이트
      if (updateUIImmediately) {
        _currentState = 'RUNNING';
        _isRunning = true;
        notifyListeners();

        // 타이머 즉시 시작
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _onTimerTick(sessionId: sessionId);
        });
      }

      // 필요한 경우에만 세션 정보 로드 (최소화)
      if (_currentSessionMode == null || _currentActivityId == null) {
        final lastSession = await _dbService.getSession(sessionId);
        if (lastSession != null) {
          _currentSessionMode = lastSession['mode'];
          _currentSessionTargetDuration = lastSession['target_duration'];
          _currentSessionDuration = lastSession['duration'];
          _currentActivityId = lastSession['activity_id'];
          _currentActivityName = lastSession['activity_name'];
          _currentActivityIcon = lastSession['activity_icon'];
          _currentActivityColor = lastSession['activity_color'];
        }
      }

      // 백그라운드에서 DB 업데이트
      DateTime now = DateTime.now().toUtc();
      await _dbService.updateTimer(
        _timerData!['timer_id'],
        {
          'last_updated_at': now.toIso8601String(),
          'timer_state': 'RUNNING',
        },
      );

      // UI 업데이트가 아직 안되었으면 처리
      if (!updateUIImmediately) {
        _currentState = 'RUNNING';
        _isRunning = true;

        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _onTimerTick(sessionId: sessionId);
        });

        notifyListeners();
      }
    } catch (e) {
      print('Error in resumeTimer: $e');
    }
  }

  Future<void> pauseTimer({bool updateUIImmediately = false}) async {
    if (updateUIImmediately) {
      // UI 즉시 업데이트
      _currentState = 'PAUSED';
      _timer?.cancel();
      notifyListeners();
    }

    // 백그라운드에서 DB 업데이트
    try {
      DateTime now = DateTime.now().toUtc();
      await _dbService.updateTimer(
        _timerData!['timer_id'],
        {
          'last_updated_at': now.toIso8601String(),
          'timer_state': 'PAUSED',
        },
      );

      if (!updateUIImmediately) {
        _currentState = 'PAUSED';
        _timer?.cancel();
        notifyListeners();
      }
    } catch (e) {
      print('Error in pauseTimer: $e');
    }
  }

  void clearNavigationRequest() {
    _navigationRequest = null;
    notifyListeners();
  }

  void _onTimerTick({required String sessionId}) async {
    try {
      _currentSessionDuration++;
      _updateRemainingSeconds();

      _dbService.updateSession(sessionId: sessionId, seconds: _currentSessionDuration);

      bool isExceeded = _currentSessionDuration >= (_currentSessionTargetDuration ?? _remainingSeconds) || _remainingSeconds <= 0;
      if (isExceeded) {
        // exceeded 시 세션 시간을 목표 시간으로 고정
        _currentSessionDuration = (_currentSessionTargetDuration ?? _remainingSeconds);
        _isExceeded = true;

        // 타이머 정지
        stopTimer(isExceeded: true, sessionId: sessionId);
        notifyListeners(); // duration 고정을 UI에 반영

        return;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stopTimer({required bool isExceeded, required String sessionId}) async {
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
        print('Error: _timerData or timer_id is null => cannot update timer status');
        return;
      }
      await _dbService.updateTimer(
        _timerData!['timer_id'],
        {
          'last_updated_at': DateTime.now().toUtc().toIso8601String(),
          'last_ended_at': DateTime.now().toUtc().toIso8601String(),
          'timer_state': 'STOP',
        },
      );
      _currentState = 'STOP';
      _timerData = await _dbService.getTimer(getWeekStart(DateTime.now()));
      _isExceeded = false;

      String weekStart = getWeekStart(DateTime.now());
      _totalSessionDuration = await _statsProvider.getTotalDurationForCurrentWeek();
      _updateRemainingSeconds();

      notifyListeners();
    } catch (e) {
      // error log
    }
  }

  void resetCurrentSession() {
    _currentSessionDuration = 0;
    _currentSessionMode = 'NORMAL';
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
        // error log
      }
    } catch (e) {
      // error log
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
    return '$hours';
  }

  String getWeekStart(DateTime date) {
    int weekday = date.weekday;
    // 월요일을 기준으로 주 시작일을 계산 (월요일이 1, 일요일이 7)
    DateTime weekStart = date.subtract(Duration(days: weekday - 1)).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
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
          if (log['start_time'] == null || log['start_time'] is! String) {
            throw Exception('Invalid or missing start_time in log: $log');
          }

          String startTimeString = log['start_time'];
          int duration = log['duration'] ?? 0;
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
          // error log
          continue; // 다른 로그 처리 계속
        }
      }

      if (!_disposed) {
        // dispose 여부 확인
        notifyListeners();
      }
    } catch (e) {
      // error log
    }
  }

  Future<List<Map<String, dynamic>>> get activityLogs async {
    try {
      DateTime now = DateTime.now();
      // _statsProvider.weekOffset을 사용하여 원하는 주(예: -1: 지난 주, 0: 이번 주, 1: 다음 주)를 계산
      int offset = _statsProvider.weekOffset;
      DateTime weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1)).add(Duration(days: offset * 7));
      DateTime weekEnd = weekStart.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));

      // 해당 주 범위의 활동 로그를 DB에서 가져오기
      List<Map<String, dynamic>> allLogs = await _dbService.getSessionsWithinDateRange(
        startDate: weekStart,
        endDate: weekEnd,
      );

      // 주간 활동 로그만 필터링
      List<Map<String, dynamic>> weeklyLogs = allLogs.where((log) {
        try {
          String? startTimeString = log['start_time'];
          if (startTimeString != null && startTimeString.isNotEmpty) {
            DateTime startTime = DateTime.parse(startTimeString).toLocal();
            return !startTime.isBefore(weekStart) && startTime.isBefore(weekEnd);
          }
        } catch (e) {
          // 에러 발생 시 해당 로그는 제외
        }
        return false;
      }).toList();

      return weeklyLogs;
    } catch (e) {
      // 에러 발생 시 빈 리스트 반환
      return [];
    }
  }

  // 활동 데이터를 저장할 맵
  Map<DateTime, int> _heatMapDataSet = {};

  // heatMapDataSet의 getter
  Map<DateTime, int> get heatMapDataSet => _heatMapDataSet;
  Future<void> initializeHeatMapData({int? year, int? month}) async {
    try {
      DateTime now = DateTime.now();
      int selectedYear = year ?? now.year;
      int selectedMonth = month ?? now.month;

      // 선택한 월의 시작일과 종료일 계산
      DateTime monthStart = DateTime(selectedYear, selectedMonth, 1);
      DateTime monthEnd;
      if (selectedMonth == 12) {
        monthEnd = DateTime(selectedYear + 1, 1, 1);
      } else {
        monthEnd = DateTime(selectedYear, selectedMonth + 1, 1);
      }

      // DB에서 세션 데이터를 가져옴
      List<Map<String, dynamic>> logs = await _dbService.getSessionsWithinDateRange(
        startDate: monthStart,
        endDate: monthEnd,
      );
      _heatMapDataSet = {};

      for (var log in logs) {
        try {
          String? startTimeString = log['start_time'];
          int duration = log['duration'] ?? 0;

          if (startTimeString != null && startTimeString.isNotEmpty) {
            DateTime date = DateTime.parse(startTimeString).toLocal();
            // 날짜만 사용하기 위해 시간 정보를 제거
            DateTime dateOnly = DateTime(date.year, date.month, date.day);
            int effectiveDuration = max(0, duration);

            _heatMapDataSet.update(
              dateOnly,
              (existing) {
                int newValue = existing + effectiveDuration;
                return newValue;
              },
              ifAbsent: () {
                return effectiveDuration;
              },
            );
          } else {}
        } catch (e) {}
      }

      if (_heatMapDataSet.isEmpty) {
      } else {
        _heatMapDataSet.forEach((date, seconds) {});
      }

      notifyListeners();
    } catch (e) {}
  }
}
