import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/auth_provider.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/error_service.dart';
import 'package:uuid/uuid.dart';

class TimerProvider with ChangeNotifier, WidgetsBindingObserver {
  final DatabaseService _dbService;
  final AuthProvider _authProvider;
  final ErrorService _errorService; // ErrorService 주입

  TimerProvider({
    required AuthProvider authProvider,
    required DatabaseService databaseService,
    required ErrorService errorService,
  })  : _authProvider = authProvider,
        _dbService = databaseService,
        _errorService = errorService {
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

  Timer? _timer;
  bool _isRunning = false;
  bool _disposed = false; // dispose 여부를 추적

  int _totalSeconds = 360000;
  int _remainingSeconds = 360000; // 기본값 100시간 (초 단위)
  int _currentActivityDuration = 0; // 현재 활동 시간

  Map<String, dynamic>? _timerData;
  String? _currentSessionId;
  final Map<String, double> _weeklyActivityData = {
    '월': 0.0,
    '화': 0.0,
    '수': 0.0,
    '목': 0.0,
    '금': 0.0,
    '토': 0.0,
    '일': 0.0,
  };

  String? _currentActivityId;
  String? _currentActivityName = '전체';
  String? _currentActivityIcon = 'category_rounded';
  String? _currentActivityColor = '#B7B7B7';

  // 현재 활동 정보를 가져오는 getter
  String? get currentActivityId => _currentActivityId;
  String? get currentActivityName => _currentActivityName;
  String? get currentActivityIcon => _currentActivityIcon;
  String? get currentActivityColor => _currentActivityColor;

  // 타이머의 활성 상태를 확인하는 getter 추가
  bool get isTimerActive => _timer?.isActive ?? false;

  /*

      @Init

  */

  Future<void> _initializeTimerData() async {
    try {
      final uid = _authProvider.user?.uid; // AuthProvider에서 UID 가져오기
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

      String weekStart = getWeekStart(DateTime.now());
      _timerData = await _dbService.getTimer(weekStart);

      int totalSeconds = 0;

      if (_timerData != null) {
        totalSeconds = _timerData?['total_seconds'] ?? 360000; // 기본값 100시간
        _isRunning = (_timerData?['is_running'] ?? 0) == 1;

        // 마지막 세션 복원
        _currentSessionId = _timerData?['last_session_id'] ?? '';
      } else {
        // 타이머 데이터가 없으면 새로 생성
        _timerData = await _createNewTimer(uid, weekStart);
        totalSeconds = _timerData?['total_seconds'] ?? 360000;
      }

      // 세션의 duration 합 계산
      int totalSessionDuration = await _dbService.getTotalSessionDurationForWeek(weekStart);

      // 남은 시간 계산
      _remainingSeconds = (totalSeconds - totalSessionDuration).clamp(0, totalSeconds);

      // 10분 이상 세션 수 갱신
      int sessionsOver10min = await _dbService.getSessionsOver10MinCount(weekStart);
      _timerData?['sessions_over_10min'] = sessionsOver10min;

      // 마지막 세션에서 활동 정보 복원
      if (_currentSessionId != null && _currentSessionId!.isNotEmpty) {
        final session = await _dbService.getSession(_currentSessionId!);
        if (session != null) {
          _currentActivityId = session['activity_id'];
          await _updateCurrentActivityDetails();
        }
      } else {
        // 기본 활동 복원
        final defaultActivity = await _dbService.getDefaultActivity();
        if (defaultActivity != null) {
          _currentActivityId = defaultActivity['activity_id'];
          _currentActivityName = defaultActivity['activity_name'];
          _currentActivityIcon = defaultActivity['activity_icon'];
        }
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
        'sessions_over_10min': 0,
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
    print('setTimerData called');

    try {
      _timerData = timerData;

      // 주차에 해당하는 총 세션 시간 계산
      String weekStart = _timerData?['week_start'] ?? getWeekStart(DateTime.now());
      int totalSessionDuration = await _dbService.getTotalSessionDurationForWeek(weekStart);

      // remaining_seconds 계산
      int totalSeconds = _timerData?['total_seconds'] ?? 360000; // 기본값 100시간
      _remainingSeconds = (totalSeconds - totalSessionDuration).clamp(0, totalSeconds);

      print('Calculated remaining_seconds: $_remainingSeconds');

      // 마지막 활동기록 불러오기
      String lastSessionId = _timerData?['last_session_id'] ?? '';
      final session = await _dbService.getSession(lastSessionId); // 마지막 세션이 있다면 가져오기
      _currentActivityId = session?['activity_id']; // 마지막 세션의 활동 가져오기
      _currentSessionId = lastSessionId;

      // 재생 중 여부 확인
      _isRunning = (_timerData?['is_running'] ?? 0) == 1; // 타이머 실행 여부 가져오기

      DateTime now = DateTime.now().toUtc();
      DateTime lastUpdated = DateTime.parse(_timerData!['last_updated_at'] ?? now.toIso8601String()).toUtc();

      if (lastSessionId.isNotEmpty) {
        // 마지막 세션이 있을 경우
        DateTime startTime = DateTime.parse(session!['start_time']).toUtc();
        DateTime? endTime = session['end_time'] != null ? DateTime.parse(session['end_time']).toUtc() : null;

        int activityDuration;

        if (endTime != null) {
          // 세션이 종료된 경우
          activityDuration = endTime.difference(startTime).inSeconds;
        } else if (_isRunning) {
          // 세션이 종료되지 않았고 타이머가 작동 중인 경우
          activityDuration = now.difference(startTime).inSeconds;
        } else {
          // 세션이 종료되지 않았지만 타이머가 작동 중이지 않은 경우
          activityDuration = 0;
        }

        activityDuration = activityDuration >= 0 ? activityDuration : 0;
        int activityRestTime = session['rest_time'] ?? 0;
        _currentActivityDuration = activityDuration - activityRestTime;
      } else {
        _currentActivityDuration = 0;
      }

      await _updateCurrentActivityDetails();

      if (_isRunning) {
        int elapsedSeconds = now.difference(lastUpdated).inSeconds;
        elapsedSeconds = elapsedSeconds >= 0 ? elapsedSeconds : 0;

        // 남은 시간을 감소하고 음수 방지
        _remainingSeconds = (_remainingSeconds - elapsedSeconds).clamp(0, _remainingSeconds);

        // 현재 활동 시간을 증가
        _currentActivityDuration += elapsedSeconds;
        Fluttertoast.showToast(
          msg: "활동 재개",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.redAccent.shade200,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        if (_currentActivityId != null) {
          await startTimer(activityId: _currentActivityId!);
          onWaveAnimationRequested?.call();
        } else {
          print('현재 활동 ID를 찾을 수 없습니다.');
          Fluttertoast.showToast(
            msg: "활동 ID를 찾을 수 없습니다",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.redAccent.shade200,
            textColor: Colors.white,
            fontSize: 14.0,
          );
        }
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

  Future<void> _updateCurrentActivityDetails() async {
    try {
      if (_currentActivityId != null) {
        final activity = await _dbService.getActivityById(_currentActivityId!);
        if (activity.isNotEmpty) {
          _currentActivityId = activity.first['activity_id'];
          _currentActivityName = activity.first['activity_name'];
          _currentActivityIcon = activity.first['activity_icon'];
          notifyListeners();
        } else {
          // 활동이 없을 경우 기본값 설정
          await _setDefaultActivity();
        }
      } else {
        // 활동 ID가 없을 경우 기본값 설정
        await _setDefaultActivity();
      }
    } catch (e) {
      await _errorService.createError(
        errorCode: 'UPDATE_ACTIVITY_DETAILS_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Updating Current Activity Details',
        severityLevel: 'high',
      );
      print('Error updating current activity details: $e');
    }
  }

  Future<void> _setDefaultActivity() async {
    try {
      final defaultActivity = await _dbService.getDefaultActivity();
      if (defaultActivity != null) {
        _currentActivityId = defaultActivity['activity_id'];
        _currentActivityName = defaultActivity['activity_name'];
        _currentActivityIcon = defaultActivity['activity_icon'];
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

// WidgetsBindingObserver의 콜백 메서드 오버라이드
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    try {
      if (state == AppLifecycleState.paused) {
        // 앱이 백그라운드로 이동할 때
        _onAppPaused();
      } else if (state == AppLifecycleState.resumed) {
        // 앱이 포그라운드로 복귀할 때
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

  VoidCallback? onWaveAnimationRequested;

  void _onAppPaused() async {
    print('_onAppPaused called');
    try {
      // 앱이 백그라운드로 이동할 때 현재 시간을 저장하고 Firestore에 업데이트
      String now = DateTime.now().toUtc().toIso8601String();

      await _updateTimerDataInDatabase();

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
      // 앱이 포그라운드로 복귀할 때 경과된 시간을 계산하고 업데이트
      DateTime now = DateTime.now();
      String weekStart = getWeekStart(now);

      Map<String, dynamic>? timer = await _dbService.getTimer(weekStart);
      if (timer == null) {
        print('Timer not found for weekStart=$weekStart');
        return;
      }

      DateTime appPausedTime = DateTime.parse(timer['last_updated_at']);
      _isRunning = timer['is_running'] == 1;

      if (_isRunning) {
        int elapsedSeconds = now.difference(appPausedTime).inSeconds;
        elapsedSeconds = elapsedSeconds >= 0 ? elapsedSeconds : 0;

        // 남은 시간을 감소하고 음수 방지
        _remainingSeconds = (_remainingSeconds - elapsedSeconds).clamp(0, _remainingSeconds);

        // 현재 활동 시간이 증가
        _currentActivityDuration += elapsedSeconds;
        notifyListeners();

        if (_currentActivityId != null) {
          await startTimer(activityId: _currentActivityId!);
          Fluttertoast.showToast(
            msg: "활동 재개",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.redAccent.shade200,
            textColor: Colors.white,
            fontSize: 14.0,
          );
          onWaveAnimationRequested?.call();
        } else {
          print('현재 활동 ID를 찾을 수 없습니다.');
          Fluttertoast.showToast(
            msg: "활동 ID를 찾을 수 없습니다",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.redAccent.shade200,
            textColor: Colors.white,
            fontSize: 14.0,
          );
        }
      } else {
        // 타이머가 작동 중이지 않은 경우 활동 시간을 증가시키지 않음
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

  bool get isRunning => _isRunning;

  Future<void> startTimer({required String activityId}) async {
    print('startTimer called with activityId: $activityId');

    try {
      DateTime now = DateTime.now();
      DateTime utcNow = now.toUtc();
      String weekStart = getWeekStart(now); // 현재 주차 계산

      // 타이머 데이터 가져오기
      final timerData = await _dbService.getTimer(weekStart);

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

      _timerData = timerData;

      // 기존 타이머 실행 상태 확인
      final isRunning = timerData['is_running'] == 1;

      // 기존 타이머 취소
      _timer?.cancel();

      // 마지막 세션 정보 가져오기
      final lastSessionId = timerData['last_session_id'];
      String? lastActivityId;
      bool shouldCreateNewSession = true;

      if (lastSessionId != null) {
        final lastSession = await _dbService.getSession(lastSessionId);

        if (lastSession != null) {
          lastActivityId = lastSession['activity_id'];
          DateTime? lastEndTime = lastSession['end_time'] != null ? DateTime.parse(lastSession['end_time']).toUtc() : null;

          if (lastEndTime != null) {
            int elapsedSeconds = utcNow.difference(lastEndTime).inSeconds;

            // 마지막 활동이 동일하고 11분 이내라면 기존 세션 재개
            if (lastActivityId == activityId && elapsedSeconds <= 660) {
              shouldCreateNewSession = false;
              print("기존 세션 재개 가능. 경과 시간: $elapsedSeconds초");
            } else {
              print("새 세션 필요. 경과 시간: $elapsedSeconds초, 활동 변경 여부: ${lastActivityId != activityId}");
            }
          } else {
            // 종료 시간이 없으면 세션 재개 가능
            if (lastActivityId == activityId) {
              shouldCreateNewSession = false;
              print("기존 세션 종료 시간이 null이며 활동이 동일. 기존 세션 재개");
            } else {
              // 기존 세션 종료 후 새 세션 생성 필요
              print("기존 세션 종료 시간이 null이지만 활동이 다름. 기존 세션 종료 후 새 세션 생성 필요");

              try {
                int currentDuration = utcNow.difference(DateTime.parse(lastSession['last_updated_at']).toUtc()).inSeconds;
                currentDuration = currentDuration >= 0 ? currentDuration : 0;

                await _dbService.endSession(lastSessionId, currentDuration);
                print("기존 세션 종료 완료. sessionId: $lastSessionId, duration: $currentDuration초");
              } catch (e) {
                print("기존 세션 종료 중 오류 발생: $e");
                await _errorService.createError(
                  errorCode: 'SESSION_END_FAILED',
                  errorMessage: e.toString(),
                  errorAction: 'Ending existing session before starting new session',
                  severityLevel: 'high',
                );
                return;
              }
            }
          }
        } else {
          print("마지막 세션 데이터를 찾을 수 없습니다. 새 세션 생성 필요");
          await _errorService.createError(
            errorCode: 'LAST_SESSION_NOT_FOUND',
            errorMessage: 'Last session not found for sessionId: $lastSessionId.',
            errorAction: 'Starting new session',
            severityLevel: 'medium',
          );
        }
      } else {
        print("마지막 세션 없음. 새 세션 생성 필요");
      }

      // 세션 생성 또는 기존 세션 재개
      if (shouldCreateNewSession) {
        try {
          final sessionId = const Uuid().v4();
          _currentSessionId = sessionId;
          print("새로운 활동 기록!");
          await _dbService.createSession(
            sessionId,
            activityId,
            _timerData!['timer_id'],
          );
          _currentActivityId = activityId;
          await _updateCurrentActivityDetails();
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
      } else {
        try {
          print("기존 활동 재개!");
          _currentSessionId = lastSessionId;
          _currentActivityId = lastActivityId;
          await _updateCurrentActivityDetails();
          await _dbService.restartSession(_currentSessionId!);
        } catch (e) {
          print("Error resuming session: $e");
          await _errorService.createError(
            errorCode: 'SESSION_RESUMPTION_FAILED',
            errorMessage: e.toString(),
            errorAction: 'Resuming session',
            severityLevel: 'high',
          );
          return;
        }
      }

      // 타이머 데이터 업데이트
      try {
        print('_currentSessionId::: $_currentSessionId');
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

  void _onTimerTick() {
    try {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _currentActivityDuration++; // 현재 활동 시간 증가
        notifyListeners();
      } else {
        stopTimer();
      }
    } catch (e) {
      print('Error during timer tick: $e');
      _errorService.createError(
        errorCode: 'TIMER_TICK_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Decrementing remaining seconds during timer tick',
        severityLevel: 'high',
      );
    }
  }

  Future<void> stopTimer() async {
    print('stopTimer called');

    try {
      if (_isRunning) {
        _isRunning = false;
        _timer?.cancel();
        print('Timer stopped. _isRunning: $_isRunning');

        await _updateTimerDataInDatabase();

        try {
          await _dbService.endSession(_currentSessionId, _currentActivityDuration);
          print(_currentActivityId);
        } catch (e) {
          print('Error updating session in database: $e');
          await _errorService.createError(
            errorCode: 'SESSION_UPDATE_FAILED',
            errorMessage: e.toString(),
            errorAction: 'Updating session during timer stop',
            severityLevel: 'high',
          );
        }

        // 현재 활동 시간 초기화
        _currentActivityDuration = 0;

        notifyListeners();
      }
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

  Future<void> _updateTimerDataInDatabase() async {
    try {
      DateTime now = DateTime.now();
      DateTime utcNow = now.toUtc();
      String weekStart = getWeekStart(now);
      final timerData = await _dbService.getTimer(weekStart);

      if (timerData != null) {
        final String timerId = timerData['timer_id'];
        final String userId = timerData['uid'];

        Map<String, dynamic> updatedData = {
          'is_running': _isRunning ? 1 : 0,
          'last_updated_at': utcNow.toIso8601String(),
          'last_session_id': _currentSessionId,
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

  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds.clamp(0, _totalSeconds);

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  String get formattedTime => _formatTime(remainingSeconds);

  String get formattedActivityTime => _formatTime(_currentActivityDuration.clamp(0, _totalSeconds));
  int get currentActivityDuration => _currentActivityDuration;

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
