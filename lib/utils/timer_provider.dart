import 'dart:async';
import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/notification_service.dart';
import 'package:project1/utils/prefs_service.dart';
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
      logger.d('[timerProvider] 생성자 실행');
      WidgetsBinding.instance.addObserver(this); // WidgetsBindingObserver 등록
      _bootstrap();
    } catch (e) {
      logger.e('[timerProvider] error: $e');
    }
  }

  Future<void> _bootstrap() async {
    logger.d('[timerProvider] bootstrap 실행');
    await setTimer(); // timer setting
    await initializeFromLastSession(); // restore session
    _isTimerProviderInit = true; // (기존 flag 유지해도 OK)
    _readyCompleter.complete(); // 🔹 준비 완료 신호
    notifyListeners();
  }

  void updateDependencies({
    required DatabaseService dbService,
  }) {
    _dbService = dbService;
  }

  // Completer
  late final Completer<void> _initializedCompleter = Completer();
  Future<void> get initialized => _initializedCompleter.future;

  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  void initializeWithDB(DatabaseService db) {
    logger.d('[timerProvider] timerProvider init');
    _dbService = db;
    _initializedCompleter.complete();
    notifyListeners();
  }

  Timer? _timer;

  Map<String, dynamic>? _timerData;
  Map<String, dynamic>? get timerData => _timerData;

  bool _disposed = false; // dispose 여부를 추적

  bool _isTimerProviderInit = false;
  bool get isTimerProviderInit => _isTimerProviderInit;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  int _totalSeconds = 360000;
  int get totalSeconds => _totalSeconds;

  int _totalSessionDuration = 0;
  int get totalSessionDuration => _totalSessionDuration;

  int _remainingSeconds = 360000; // 기본값 100시간 (초 단위)
  int get remainingSeconds => _remainingSeconds.clamp(0, _totalSeconds);

  String get formattedTime => _formatTime(isWeeklyTargetExceeded ? _totalSessionDuration : _remainingSeconds);
  String get formattedExceededTime => _formatHour(_totalSessionDuration - _totalSeconds);
  String get formattedActivityTime => _formatTime(_currentSessionDuration.clamp(0, _totalSeconds));
  String get formattedTotalSessionDuration => _formatTime(_totalSessionDuration);
  String get formattedTotalSessionHour => _formatHour(_totalSessionDuration);

  // 현재 activity 전역 변수
  String? _currentActivityId;
  String? get currentActivityId => _currentActivityId;
  String _currentActivityName = '전체';
  String get currentActivityName => _currentActivityName;
  String _currentActivityIcon = 'category';
  String get currentActivityIcon => _currentActivityIcon;
  String _currentActivityColor = '#B7B7B7';
  String get currentActivityColor => _currentActivityColor;

  String _currentState = 'STOP';
  String get currentState => _currentState;

  int _currentSessionDuration = 0;
  int get currentSessionDuration => _currentSessionDuration;

  String? _currentSessionMode;
  String? get currentSessionMode => _currentSessionMode;
  int? _currentSessionTargetDuration;
  int? get currentSessionTargetDuration => _currentSessionTargetDuration;

  // session의 targetDuration 초과 여부
  bool _isSessionTargetExceeded = false;
  bool get isSessionTargetExceeded => _isSessionTargetExceeded;
  bool _isWeeklyTargetExceeded = false;
  bool get isWeeklyTargetExceeded => _isWeeklyTargetExceeded;

  // 일회성 이벤트 flag
  bool _justFinishedByExceeding = false;
  bool get justFinishedByExceeding => _justFinishedByExceeding;

  /*

      @Init

  */

  Future<void> initializeFromLastSession() async {
    try {
      print('### timerProvider ### : initializeFromLastSession()');

      // 이미 초기화되었는지 확인
      if (_isTimerProviderInit) return;

      // timer 불러오기
      String weekStart = getWeekStart(DateTime.now());
      final timer = await _dbService.getTimer(weekStart);
      if (timer == null) return;

      // cleanupSession Logic
      await _cleanupSessions();

      // current_session 불러오기
      String sessionId = timer['current_session_id'];
      if (sessionId.isEmpty) return;
      final session = await _dbService.getSession(sessionId);
      if (session == null) return;

      // currentSession이 없으면 안불러와짐. NULL CHECK ERROR
      _currentSessionMode = session['mode'];
      _currentSessionDuration = session['duration'];
      _currentSessionTargetDuration = session['target_duration'];
      _currentActivityId = session['activity_id'];
      _currentActivityName = session['activity_name'];
      _currentActivityIcon = session['activity_icon'];
      _currentActivityColor = session['activity_color'];

      // timer_state가 RUNNING일 경우
      if (timer['timer_state'] == 'RUNNING') {
        logger.d('### timerProvider ### : initializeFromLastSession >> timer[timer_state] == RUNNING');
        _currentState = 'RUNNING';
        _isRunning = true;

        // 앱 종료 시점부터 현재까지 경과 시간 계산
        DateTime lastUpdatedAt = DateTime.parse(session['last_updated_at']);
        DateTime now = DateTime.now();
        int elapsedSeconds = now.difference(lastUpdatedAt).inSeconds;

        // 총 진행 시간 = 저장된 진행 시간 + 앱 종료 후 경과 시간
        int totalDuration = session['duration'] + elapsedSeconds;

        // 시간이 경과했으므로 목표 시간 초과 여부 확인
        int? sessiontargetDuration = session['target_duration'];
        if (sessiontargetDuration != null && totalDuration >= sessiontargetDuration) {
          print(
              'timerProvider: initializeFromLastSession >> timer[timer_state] == RUNNING >> sessiontargetDuration != null && totalDuration >= sessiontargetDuration');
          // session의 targetDuration을 초과했을 경우 세션 완료 처리
          await stopTimer(isSessionTargetExceeded: true, sessionId: sessionId);
          _isSessionTargetExceeded = true;
        } else {
          print('timerProvider: initializeFromLastSession >> timer[timer_state] == RUNNING >> else');

          // targetDuration이 null일 경우
          // 또는 targetDuration을 초과하지 않았을 경우 duration과 targetDuration 업데이트
          _currentSessionDuration = totalDuration;
          _currentSessionTargetDuration = sessiontargetDuration;

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
      } else if (timer['timer_state'] == 'PAUSED') {
        print('timerProvider: initializeFromLastSession >> timer[timer_state] == PAUSED');
        // 세션 상태 복원
        _currentState = 'PAUSED';
        _isRunning = true;
      } else {
        _currentState = 'STOP';
        _isRunning = false;
      }
      _isTimerProviderInit = true;
      notifyListeners();
    } catch (e) {
      logger.e('Error initializing from last session: $e');
    }
  }

  Future<void> setTimer() async {
    try {
      logger.d('[timerProvider] setTimer');

      String weekStart = getWeekStart(DateTime.now()); // 해당 주차
      final rawTimerData = await _dbService.getTimer(weekStart); // 해당 주차의 timerData

      if (rawTimerData == null) {
        // 해당 주차의 timerData가 null일 경우
        _timerData = await _createNewTimer(weekStart); // 신규 타이머를 생성하고 _timerData 변수에 값 저장
        _totalSeconds = _timerData?['total_seconds'] ?? 360000; // 신규 타이머의 totalSeconds 불러오기
        _isRunning = false; // 신규 생성이므로 _isRunning은 false
      } else {
        // 해당 주차의 timerData가 이미 있을 때
        _timerData = Map<String, dynamic>.from(rawTimerData); // _timerData 변수에 값 저장
        _totalSeconds = _timerData?['total_seconds'] ?? 360000; // 기존 타이머의 totalSeconds 불러오기
        _isRunning = (_timerData?['timer_state'] ?? 'STOP') == 'RUNNING'; // 기존 타이머의 timerState 토대로 isRunning
      }

      _totalSessionDuration = await _statsProvider.getTotalDurationForCurrentWeek(); // 세션의 duration 합 계산

      if (_isRunning) {
        // timer가 작동중이라면 session Data 초기화
        String lastSessionId = _timerData?['current_session_id'] ?? '';
        if (lastSessionId.isNotEmpty) {
          final lastSession = await _dbService.getSession(lastSessionId);
          if (lastSession != null && lastSession.isNotEmpty) {
            logger.d('[timerProvider] setTimer 중 session Data 초기화');
            _currentSessionMode = lastSession['mode'];
            _currentSessionDuration = lastSession['duration'];
            _currentSessionTargetDuration = lastSession['target_duration'];
            _currentActivityId = lastSession['activity_id'];
            _currentActivityName = lastSession['activity_name'];
            _currentActivityIcon = lastSession['activity_icon'];
            _currentActivityColor = lastSession['activity_color'];
            _remainingSeconds = (_totalSeconds - _totalSessionDuration).clamp(0, _totalSeconds);
          }
        }
      }

      // 기타 현재 활동 정보 설정
      if (_currentActivityId != null && _currentActivityId!.isNotEmpty) {
        // currentActivityId에 값이 있을 경우
        _setLastActivty(lastActivityId: _currentActivityId);
      } else {
        // currentActivityId에 값이 없을 경우
        setDefaultActivity();
      }

      _updateRemainingSeconds();

      notifyListeners();
    } catch (e) {
      logger.e('''
        [timerProvider]
        - 위치 : set Timer
        - 오류 유형: ${e.runtimeType}
        - 메시지: ${e.toString()}
      ''');
    }
  }

  Future<Map<String, dynamic>> _createNewTimer(String weekStart) async {
    try {
      logger.d('[timerProvider] create New Timer');
      int userTotalSeconds = PrefsService().totalSeconds;

      String timerId = const Uuid().v4();
      String nowUtcStr = DateTime.now().toUtc().toIso8601String();
      Map<String, dynamic> timerData = {
        'timer_id': timerId,
        'current_session_id': null,
        'week_start': weekStart,
        'total_seconds': userTotalSeconds,
        'timer_state': 'STOP',
        'created_at': nowUtcStr,
        'deleted_at': null,
        'last_started_at': null,
        'last_ended_at': null,
        'last_updated_at': nowUtcStr,
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
      logger.d('[timerProvider] set Last Activty');
      final lastActivity = await _statsProvider.getActivityById(lastActivityId);
      if (lastActivity != null && lastActivity.isNotEmpty) {
        _currentActivityId = lastActivity['activity_id'];
        _currentActivityName = lastActivity['activity_name'];
        _currentActivityIcon = lastActivity['activity_icon'];
        _currentActivityColor = lastActivity['activity_color'];
        notifyListeners();
      } else {
        await setDefaultActivity();
      }
    } catch (e) {
      logger.e('''
        [timerProvider]
        - 위치 : _setLastActivty
        - 오류 유형: ${e.runtimeType}
        - 메시지: ${e.toString()}
      ''');
    }
  }

  Future<void> setDefaultActivity() async {
    try {
      logger.d('[timerProvider] set Default Activity');
      final defaultActivity = await _statsProvider.getDefaultActivity();
      if (defaultActivity != null) {
        // defaultActivity가 있고 무사히 불러왔다면 이를 currentActivity에 세팅
        logger.d('[timerProvider] defaultActivity: $defaultActivity');
        _currentActivityId = defaultActivity['activity_id'];
        _currentActivityName = defaultActivity['activity_name'];
        _currentActivityIcon = defaultActivity['activity_icon'];
        _currentActivityColor = defaultActivity['activity_color'];
        notifyListeners();
      } else {
        logger.e('''
          [timerProvider]
          - 위치 : _setDefaultActivity
          - 오류 유형: ${e.runtimeType}
          - 메시지: ${e.toString()}
        ''');
      }
    } catch (e) {
      logger.e('''
        [timerProvider]
        - 위치 : _setDefaultActivity
        - 오류 유형: ${e.runtimeType}
        - 메시지: ${e.toString()}
      ''');
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
    logger.d('_onAppPaused called');
    if (_currentState == 'RUNNING') {
      _timer?.cancel();
    }
  }

  void _onAppResumed() async {
    logger.d('_onAppResumed called');
    try {
      await AwesomeNotifications().resetGlobalBadge();

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

        logger.d('onAppresumed에 따른 session 시간 계산 : $lastUpdatedAt');
        logger.d('onAppresumed에 따른 session 시간 계산 : $elapsedSeconds');
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

  void clearEventFlags() {
    logger.d('###timerProvider : clearEventFlags()');
    _justFinishedByExceeding = false;
  }

  /*

      @refresh

  */

  Future<void> updateTotalSeconds(int hours) async {
    try {
      logger.d('[timerProvider] updateTotalSeconds: $hours hours');

      // 초 단위로 변환
      int totalSecondsValue = hours * 3600;

      // 현재 타이머 데이터 확인
      if (_timerData == null || !_timerData!.containsKey('timer_id')) {
        logger.e('[timerProvider] updateTotalSeconds: Timer data is null or invalid');
        return;
      }

      // DB 업데이트 - 기존의 updateTimer 활용
      await _dbService.updateTimer(
        _timerData!['timer_id'],
        {
          'total_seconds': totalSecondsValue,
        },
      );

      // 로컬 상태 업데이트
      _totalSeconds = totalSecondsValue;

      // 타이머 데이터를 새로고침
      refreshTimer();

      // 남은 시간 업데이트
      _updateRemainingSeconds();
      await _statsProvider.refreshWeeklyStats();

      // 리스너에게 알림
      notifyListeners();

      logger.d('[timerProvider] Total seconds updated successfully');
    } catch (e) {
      logger.e('''
      [timerProvider]
      - 위치 : updateTotalSeconds
      - 오류 유형: ${e.runtimeType}
      - 메시지: ${e.toString()}
    ''');
      rethrow; // 호출자에게 예외 전파
    }
  }

  void refreshTimer() async {
    String weekStart = getWeekStart(DateTime.now());
    _timerData = await _dbService.getTimer(weekStart);
  }

  void _updateRemainingSeconds() {
    _remainingSeconds = _totalSeconds - _totalSessionDuration;
    _isWeeklyTargetExceeded = _remainingSeconds <= 0;
    notifyListeners();
  }

  Future<void> refreshRemainingSeconds() async {
    refreshTimer();
    _totalSeconds = _timerData?['total_seconds'] ?? _totalSeconds;

    _totalSessionDuration = await _statsProvider.getTotalDurationForCurrentWeek();
    _updateRemainingSeconds();
  }

  /*

        @start Timer


    */

  void setSessionModeAndTargetDuration({required String mode, int? targetDuration}) {
    _currentSessionMode = mode;
    _currentSessionTargetDuration = targetDuration;
  }

  Future<void> startTimer({required String activityId, required String mode, int? targetDuration}) async {
    logger.d('### timerProvider ### : startTimer()');
    logger.d('_isRunning: $_isRunning');

    if (_isRunning) return; // 중복 실행 방지
    _timer?.cancel(); // 이미 실행중인 타이머가 있다면 cancel

    try {
      DateTime now = DateTime.now();
      DateTime utcNow = now.toUtc();
      String weekStart = getWeekStart(now);

      Map<String, dynamic>? timer = await _dbService.getTimer(weekStart);

      if (_isRunning && timer!['current_session_id'] != null) {
        await stopTimer(
          isSessionTargetExceeded: false,
          sessionId: timer['current_session_id']!,
        );
      }

      // activityId를 통해 activity 호출
      final activity = await _statsProvider.getActivityById(activityId);

      // 불러온 activity 토대로 session 생성
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

      // timer DB 업데이트
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

      // 업데이트한 timer를 다시 불러오기
      _timerData = await _dbService.getTimer(_timerData!['week_start']);

      if (_isWeeklyTargetExceeded == true && mode == 'NORMAL') {
        targetDuration = null;
      }

      // timer 전역변수 업데이트
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

      if (mode == 'PMDR' && targetDuration != null) {
        logger.d('push test : _currentSessionMode ${_currentSessionMode}');
        logger.d('push test : _currentSessionTargetDuration ${_currentSessionTargetDuration}');
        await _schedulePmdrCompletion(scheduledSec: targetDuration, targetSec: targetDuration);
      }
    } catch (e) {
      // 오류 발생 시 로그 기록 후 상위 호출자에게 예외 전파
      logger.e('타이머 시작 중 오류 발생: $e');
      rethrow;
    }
  }

  // AppResume 시 state == 'RUNNING'일 경우
  Future<void> restartTimer({required String sessionId}) async {
    logger.d('### timerProvider ### : restartTimer({$sessionId})');
    try {
      DateTime now = DateTime.now().toUtc();

      // 타이머 데이터 가져오기
      final timerData = _timerData;

      if (timerData == null) {
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
      if (_currentSessionMode == 'PMDR' && _currentSessionTargetDuration != null) {
        final remaining = (_currentSessionTargetDuration ?? 0) - _currentSessionDuration;
        await _schedulePmdrCompletion(scheduledSec: remaining, targetSec: _currentSessionTargetDuration!);
      }
    } catch (e) {
      // error log
    }
  }

  Future<void> resumeTimer({required String sessionId, bool updateUIImmediately = false}) async {
    logger.d('timerProvider : resumeTimer');
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

      if (_currentSessionMode == 'PMDR' && _currentSessionTargetDuration != null) {
        final remaining = (_currentSessionTargetDuration ?? 0) - _currentSessionDuration;
        await _schedulePmdrCompletion(scheduledSec: remaining, targetSec: _currentSessionTargetDuration!);
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

      refreshTimer();

      // 집중모드일 경우 알림 취소
      if (_currentSessionMode == 'PMDR') {
        await _cancelPmdrCompletion();
      }
    } catch (e) {
      print('Error in pauseTimer: $e');
    }
  }

  void _onTimerTick({required String sessionId}) async {
    logger.d('### timerProvider ### : _onTimerTick({$sessionId})');
    try {
      // 1초 증가
      _currentSessionDuration++;
      _updateRemainingSeconds();
      _dbService.updateSession(sessionId: sessionId, seconds: _currentSessionDuration);

      _isWeeklyTargetExceeded = _remainingSeconds <= 0; // 주간 targetDuration 초과 여부
      bool reachedSessionTarget = _currentSessionTargetDuration != null && _currentSessionDuration >= _currentSessionTargetDuration!;
      _isSessionTargetExceeded = reachedSessionTarget; // 해당 session의 targetDuration 초과 여부
      logger.d('[timerProvider] _onTimerTick() >> _currentSessionTargetDuration: $_currentSessionTargetDuration');
      logger.d('[timerProvider] _onTimerTick() >> _currentSessionDuration: $_currentSessionDuration');
      logger.d('[timerProvider] _onTimerTick() >> reachedSessionTarget : $reachedSessionTarget');
      logger.d('[timerProvider] _onTimerTick() >> _isSessionTargetExceeded : $_isSessionTargetExceeded');
      logger.d('[timerProvider] _onTimerTick() >> _isWeeklyTargetExceeded: $_isWeeklyTargetExceeded');
      logger.d('[timerProvider] _onTimerTick() >> _isSessionTargetExceeded: $_isSessionTargetExceeded');
      logger.d('[timerProvider] _onTimerTick() >> _justFinishedByExceeding: $_justFinishedByExceeding');

      // 해당 session 목표 초과 시 타이머 종료
      if (_isSessionTargetExceeded) {
        logger.d('### timerProvider ### : _onTimerTick() >> isSessionTargetExceeded');

        _justFinishedByExceeding = true;
        notifyListeners();
        await stopTimer(
          sessionId: sessionId,
          isSessionTargetExceeded: _isSessionTargetExceeded, // 주간 초과 여부 함께 전달
        );
        return;
      }

      logger.d('### timerProvider ### : _onTimerTick() >> isSessionTarget Not Exceeded');
      if (!_disposed) notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stopTimer({required bool isSessionTargetExceeded, required String sessionId}) async {
    print('### timerProvider ### : stopTimer($isSessionTargetExceeded, $sessionId)');
    try {
      // 타이머 즉시 중지
      _timer?.cancel();
      _isRunning = false;

      // session 불러오기
      final currentSession = await _dbService.getSession(sessionId);
      if (currentSession == null) return;
      if (currentSession['start_time'] == null) return;

      final startTime = DateTime.parse(currentSession['start_time'] as String);
      DateTime endTime;
      int totalDuration = _currentSessionDuration;

      if (isSessionTargetExceeded) {
        endTime = startTime.add(Duration(seconds: _currentSessionDuration));
        totalDuration = currentSessionTargetDuration!;
      } else {
        endTime = DateTime.now().toUtc();
        if (_currentSessionMode == 'PMDR') {
          await _cancelPmdrCompletion(); // 알림 취소
        }
      }

      await _dbService.endSession(
        sessionId: sessionId,
        endTime: endTime.toIso8601String(),
        duration: totalDuration,
      );

      // 2) _timerData 및 'timer_id' 체크
      if (_timerData == null || !_timerData!.containsKey('timer_id')) return;

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
      _isSessionTargetExceeded = false;

      _totalSessionDuration = await _statsProvider.getTotalDurationForCurrentWeek();
      _updateRemainingSeconds();

      notifyListeners();
    } catch (e) {
      logger.e('''
        [timerProvider]
        - 위치 : stopTimer
        - 오류 유형: ${e.runtimeType}
        - 메시지: ${e.toString()}
      ''');
    }
  }

  void resetCurrentSession() {
    _currentSessionDuration = 0;
    _currentSessionMode = 'NORMAL';
    _currentSessionTargetDuration = _remainingSeconds;
  }

  String _formatTime(int seconds) {
    final int safe = seconds.abs(); // 음수에 대해서는 절대값 , 음수라는 것에 대해서는 UI상으로 표현
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  String _formatHour(int seconds) {
    final hours = seconds ~/ 3600;
    return '$hours';
  }

  String formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else if (minutes > 0) {
      return '$minutes분 $remainingSeconds초';
    } else {
      return '$remainingSeconds초';
    }
  }

  String getWeekStart(DateTime date) {
    int weekday = date.weekday;
    // 월요일을 기준으로 주 시작일을 계산 (월요일이 1, 일요일이 7)
    DateTime weekStart = date.subtract(Duration(days: weekday - 1)).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    return weekStart.toIso8601String().split('T').first;
  }

  /* 

  error check

  */

  Future<void> _cleanupSessions() async {
    logger.d('cleanupsession 작동');
    final sessions = await _statsProvider.getSessionsForWeek(0);
    final currentSessionId = timerData!['current_session_id'];
    final currentSession = await _dbService.getSession(currentSessionId);
    logger.d('sessions : $sessions');
    logger.d('currentSession : $currentSession');

    for (var session in sessions) {
      logger.d('${session['session_id']}-${session['session_state']}');

      if (session['session_state'] == 'RUNNING' && session['session_id'] != currentSessionId) {
        logger.d('terminate > ${session['session_id']}');
        await _dbService.terminateSession(sessionId: session['session_id']);
      }
    }
  }

// 알림 서비스 helper methods
  Future<bool> _alarmEnabled() async {
    return PrefsService().alarmFlag; // 설정 스위치
  }

  Future<void> _schedulePmdrCompletion({required int scheduledSec, required int targetSec}) async {
    if (scheduledSec <= 0) return;
    if (!await _alarmEnabled()) return;
    if (!await NotificationService().requestPermissions()) return;

    await NotificationService().scheduleActivityCompletionNotification(
      scheduledTime: DateTime.now().add(Duration(seconds: scheduledSec)),
      title: '100 timer',
      body: '$_currentActivityName 활동을 ${formatDuration(targetSec)} 집중했어요!',
    );
  }

  Future<void> _cancelPmdrCompletion() async {
    if (!await _alarmEnabled()) return;
    await NotificationService().cancelCompletionNotification();
  }
}
