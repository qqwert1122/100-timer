import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/database_service.dart';
import 'package:uuid/uuid.dart';

class TimerProvider with ChangeNotifier, WidgetsBindingObserver {
  Timer? _timer;
  bool _isRunning = false;
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

  final DatabaseService _dbService;
  final String userId;
  String? _currentActivityId;
  String? _currentActivityName;
  String? _currentActivityIcon;

  // 현재 활동 정보를 가져오는 getter
  String? get currentActivityId => _currentActivityId;
  String? get currentActivityName => _currentActivityName;
  String? get currentActivityIcon => _currentActivityIcon;

  // 타이머의 활성 상태를 확인하는 getter 추가
  bool get isTimerActive => _timer?.isActive ?? false;

  TimerProvider({required this.userId, required DatabaseService databaseService}) : _dbService = databaseService {
    // WidgetsBindingObserver 등록
    WidgetsBinding.instance.addObserver(this);
    _initializeTimerData(); // 추가
  }

  Future<void> _initializeTimerData() async {
    String weekStart = getWeekStart(DateTime.now());
    _timerData = await _dbService.getTimer(userId, weekStart);

    if (_timerData != null) {
      _remainingSeconds = _timerData?['remaining_seconds'] ?? _totalSeconds;
      _isRunning = (_timerData?['is_running'] ?? 0) == 1;

      // 마지막 세션에서 활동 정보 복원
      String lastSessionId = _timerData?['last_session_id'] ?? '';
      if (lastSessionId.isNotEmpty) {
        final session = await _dbService.getSession(lastSessionId);
        if (session != null) {
          _currentActivityId = session['activity_id'];
          await _updateCurrentActivityDetails();
        }
      } else {
        // 기본 활동 복원
        final defaultActivity = await _dbService.getDefaultActivity(userId);
        if (defaultActivity != null) {
          _currentActivityId = defaultActivity['activity_id'];
          _currentActivityName = defaultActivity['activity_name'];
          _currentActivityIcon = defaultActivity['activity_icon'];
        }
      }
    } else {
      // 타이머 데이터가 없을 경우 새로운 타이머 생성
      // 사용자의 totalSeconds 값을 가져옵니다.
      Map<String, dynamic>? userData = await _dbService.getUser(userId);
      int userTotalSeconds = userData?['total_seconds'] ?? 360000; // 기본값은 100시간

      // 새로운 타이머 생성
      String timerId = const Uuid().v4();
      String now = DateTime.now().toUtc().toIso8601String();
      Map<String, dynamic> timerData = {
        'uid': userId,
        'timer_id': timerId,
        'week_start': weekStart,
        'total_seconds': userTotalSeconds,
        'remaining_seconds': userTotalSeconds,
        'last_session_id': null,
        'is_running': 0,
        'created_at': now,
        'deleted_at': null,
        'last_started_at': null,
        'last_ended_at': null,
        'last_updated_at': now,
        'is_deleted': 0,
      };

      // 데이터베이스에 새로운 타이머 저장
      await _dbService.createTimer(userId, timerData);

      // 로컬 변수 업데이트
      _timerData = timerData;
      _remainingSeconds = userTotalSeconds;
      _totalSeconds = userTotalSeconds; // 추가: 총 시간을 업데이트합니다.

      // 기본 활동 설정
      final defaultActivity = await _dbService.getDefaultActivity(userId);
      if (defaultActivity != null) {
        _currentActivityId = defaultActivity['activity_id'];
        _currentActivityName = defaultActivity['activity_name'];
        _currentActivityIcon = defaultActivity['activity_icon'];
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    // WidgetsBindingObserver 해제
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // WidgetsBindingObserver의 콜백 메서드 오버라이드
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // 앱이 백그라운드로 이동할 때
      _onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 복귀할 때
      _onAppResumed();
    }
  }

  VoidCallback? onWaveAnimationRequested;

  void _onAppPaused() async {
    print('_onAppPaused called');
    // 앱이 백그라운드로 이동할 때 현재 시간을 저장하고 Firestore에 업데이트
    String now = DateTime.now().toUtc().toIso8601String();

    await _updateTimerDataInDatabase();

    _timer?.cancel();
  }

  void _onAppResumed() async {
    print('_onAppResumed called');
    // 앱이 포그라운드로 복귀할 때 경과된 시간을 계산하고 업데이트
    DateTime now = DateTime.now();
    String weekStart = getWeekStart(now);

    Map<String, dynamic>? timer = await _dbService.getTimer(userId, weekStart);
    if (timer == null) return;
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
  }

  // 현재 활동 정보를 설정하는 메서드
  void setCurrentActivity(String activityId, String activityName, String activityIcon) {
    _currentActivityId = activityId;
    _currentActivityName = activityName;
    _currentActivityIcon = activityIcon;
    notifyListeners();
  }

  void setTimerData(Map<String, dynamic> timerData) async {
    print('setTimerData called');

    _timerData = timerData;

    // 마지막 활동기록 불러오기
    String lastSessionId = _timerData?['last_session_id'] ?? '';
    final session = await _dbService.getSession(lastSessionId); // 마지막 세션이 있다면 가져오기
    _currentActivityId = session?['activity_id']; // 마지막 세션의 활동 가져오기
    _currentSessionId = lastSessionId;

    // 잔여시간 및 활동시간 초기화 & 재생중 여부 확인
    _remainingSeconds = _timerData?['remaining_seconds'] ?? _totalSeconds;
    print('Database is_running: ${_timerData?['is_running'] ?? 0 == 1}, Current _isRunning: $_isRunning');

    _isRunning = (_timerData?['is_running'] ?? 0) == 1; // 잔여시간과 활동중여부 가져오기

    DateTime now = DateTime.now().toUtc();
    DateTime lastUpdated = DateTime.parse(_timerData!['last_updated_at'] ?? now.toIso8601String()).toUtc();

    if (lastSessionId != '') {
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
  }

  bool get isRunning => _isRunning;

  Future<void> startTimer({required String activityId}) async {
    print('startTimer called with activityId: $activityId');
    DateTime now = DateTime.now();
    DateTime utcNow = now.toUtc();
    String weekStart = getWeekStart(now); // 현재 주차 계산

    // 타이머 데이터 가져오기
    final timerData = await _dbService.getTimer(userId, weekStart);

    if (timerData == null) {
      print('타이머 데이터를 찾을 수 없습니다.');
      return;
    }

    _timerData = timerData;
    final isRunning = timerData['is_running'] == 1; // 현재 타이머 실행 상태 확인

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
            print("기존 세션 종료 시간이 null이지만 활동이 다름. 새 세션 생성 필요");
          }
        }
      } else {
        print("마지막 세션 데이터를 찾을 수 없습니다. 새 세션 생성 필요");
      }
    } else {
      print("마지막 세션 없음. 새 세션 생성 필요");
    }

    // 세션 생성 또는 기존 세션 재개
    if (shouldCreateNewSession) {
      print("새로운 활동 기록!");
      _currentSessionId = const Uuid().v4();
      await _dbService.createSession(userId, activityId, _timerData!['timer_id'], _currentSessionId!);
      _currentActivityId = activityId;
      await _updateCurrentActivityDetails();
    } else {
      print("기존 활동 재개!");
      _currentSessionId = lastSessionId;
      _currentActivityId = lastActivityId;
      await _updateCurrentActivityDetails();
      await _dbService.updateSession(userId, _currentSessionId!, resetEndTime: true);
    }

    // 타이머 데이터 업데이트
    await _dbService.updateTimer(timerData['timer_id'], timerData['uid'], {
      'last_started_at': utcNow.toIso8601String(),
      'last_updated_at': utcNow.toIso8601String(),
      'last_session_id': _currentSessionId,
      'is_running': 1,
    });

    // 타이머 시작
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _onTimerTick();
    });

    print('Timer started. _isRunning: $_isRunning');
  }

  Future<void> _updateCurrentActivityDetails() async {
    if (_currentActivityId != null) {
      final activity = await _dbService.getActivityById(_currentActivityId!);
      if (activity.isNotEmpty) {
        _currentActivityId = activity.first['activity_id'];
        _currentActivityName = activity.first['activity_name'];
        _currentActivityIcon = activity.first['activity_icon'];
        notifyListeners();
      } else {
        // 활동이 없을 경우 기본값 설정
        final defaultActivity = await _dbService.getDefaultActivity(userId);
        if (defaultActivity != null) {
          _currentActivityId = defaultActivity['activity_id'];
          _currentActivityName = defaultActivity['activity_name'];
          _currentActivityIcon = defaultActivity['activity_icon'];
        } else {
          print('기본 활동을 생성할 수 없습니다.');
        }
      }
    } else {
      // 활동 ID가 없을 경우 기본값 설정
      final defaultActivity = await _dbService.getDefaultActivity(userId);
      if (defaultActivity != null) {
        _currentActivityId = defaultActivity['activity_id'];
        _currentActivityName = defaultActivity['activity_name'];
        _currentActivityIcon = defaultActivity['activity_icon'];
      } else {
        print('기본 활동을 생성할 수 없습니다.');
      }
    }
  }

  void _onTimerTick() {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      _currentActivityDuration++; // 현재 활동 시간 증가
      notifyListeners();
    } else {
      stopTimer();
    }
  }

  Future<void> stopTimer() async {
    print('stopTimer called');

    if (_isRunning) {
      _isRunning = false;
      _timer?.cancel();
      print('Timer stopped. _isRunning: $_isRunning');

      await _updateTimerDataInDatabase();
      await _dbService.updateSession(userId, _currentSessionId, resetEndTime: false);

      // Firestore에 업데이트
      await _dbService.updateTimer(_timerData!['timer_id'], _timerData!['uid'], {
        'is_running': 0,
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      notifyListeners();
    }
  }

  Future<void> _updateTimerDataInDatabase() async {
    DateTime now = DateTime.now();
    DateTime utcNow = now.toUtc();
    String weekStart = getWeekStart(now);
    final timerData = await _dbService.getTimer(userId, weekStart);

    if (timerData != null) {
      final String timerId = timerData['timer_id'];
      final String userId = timerData['uid'];

      Map<String, dynamic> updatedData = {
        'remaining_seconds': _remainingSeconds,
        'is_running': _isRunning ? 1 : 0,
        'last_updated_at': utcNow.toIso8601String(),
        'last_session_id': _currentSessionId,
      };

      await _dbService.updateTimer(timerId, userId, updatedData);
    }
  }

  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds;

  String get formattedTime {
    final hours = (_remainingSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String get formattedActivityTime {
    final hours = (_currentActivityDuration ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_currentActivityDuration % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_currentActivityDuration % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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
    List<Map<String, dynamic>> logs = await activityLogs; // 활동 로그 데이터 가져오기
    _weeklyActivityData.updateAll((key, value) => 0.0);

    for (var log in logs) {
      String startTimeString = log['start_time'];
      int duration = log['session_duration'] ?? 0;
      int restTime = log['rest_time'] ?? 0; // rest_time 가져오기

      if (startTimeString.isNotEmpty) {
        DateTime startTime = DateTime.parse(startTimeString).toLocal();
        String dayOfWeek = DateFormat.E('ko_KR').format(startTime);

        double actualDuration = (duration - restTime) / 60.0;

        _weeklyActivityData[dayOfWeek] = (_weeklyActivityData[dayOfWeek] ?? 0) + actualDuration; // 분 단위로 더함
      }
    }
    notifyListeners();
  }

  // activityLogs 메서드 추가 - 활동 로그 가져오기
  Future<List<Map<String, dynamic>>> get activityLogs async {
    DateTime now = DateTime.now();
    DateTime weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    DateTime weekEnd = weekStart.add(Duration(days: 7));

    // 모든 활동 로그 가져오기
    List<Map<String, dynamic>> allLogs = await _dbService.getAllSessions();

    // 이번 주의 활동 로그만 필터링
    List<Map<String, dynamic>> weeklyLogs = allLogs.where((log) {
      String? startTimeString = log['start_time'];

      if (startTimeString != null && startTimeString.isNotEmpty) {
        DateTime startTime = DateTime.parse(startTimeString).toLocal();
        return !startTime.isBefore(weekStart) && startTime.isBefore(weekEnd);
      }

      return false;
    }).toList();

    return weeklyLogs;
  }

  // 활동 데이터를 저장할 맵
  Map<DateTime, int> _heatMapDataSet = {};

  // heatMapDataSet의 getter
  Map<DateTime, int> get heatMapDataSet => _heatMapDataSet;

  // 활동 로그 데이터를 기반으로 heatmap 데이터를 초기화하는 메서드
  Future<void> initializeHeatMapData() async {
    List<Map<String, dynamic>> logs = await _dbService.getAllSessions();

    // 맵 초기화
    _heatMapDataSet = {};

    for (var log in logs) {
      String? startTimeString = log['start_time'];
      int duration = log['session_duration'] ?? 0;
      int restTime = log['rest_time'] ?? 0;

      if (startTimeString != null && startTimeString.isNotEmpty) {
        DateTime date = DateTime.parse(startTimeString).toLocal();

        // 날짜 부분만 사용하기 위해 시간 정보 제거
        DateTime dateOnly = DateTime(date.year, date.month, date.day);

        // 기존 값이 있으면 누적
        if (_heatMapDataSet.containsKey(dateOnly)) {
          _heatMapDataSet[dateOnly] = _heatMapDataSet[dateOnly]! + (duration - restTime);
        } else {
          _heatMapDataSet[dateOnly] = (duration - restTime);
        }
      }
    }
    notifyListeners();
  }
}
