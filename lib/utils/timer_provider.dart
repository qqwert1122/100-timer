import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/database_service.dart';

class TimerProvider with ChangeNotifier, WidgetsBindingObserver {
  Timer? _timer;
  bool _isRunning = false;
  int _totalSeconds = 360000;
  int _remainingSeconds = 360000; // 기본값 100시간 (초 단위)
  int _currentActivityDuration = 0; // **현재 활동 시간 추가**
  Map<String, dynamic>? _timerData;
  String? _currentActivityLogId;
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

  TimerProvider({required this.userId, required DatabaseService databaseService}) : _dbService = databaseService {
    // WidgetsBindingObserver 등록
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // WidgetsBindingObserver 해제
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @visibleForTesting
  Map<String, dynamic>? get timerData => _timerData;

  @visibleForTesting
  set timerData(Map<String, dynamic>? data) {
    _timerData = data;
  }

  @visibleForTesting
  set isRunning(bool isRunning) {
    isRunning = _isRunning;
  }

  @visibleForTesting
  void setCurrentActivityLogIdForTest(String? activityLogId) {
    _currentActivityLogId = activityLogId;
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
    // 앱이 백그라운드로 이동할 때 현재 시간을 저장
    DateTime now = DateTime.now().toUtc();

    await _dbService.updateTimer(_timerData!['timer_id'], _timerData!['user_id'], {
      'last_updated_at': now.toIso8601String(),
    });

    _timer?.cancel();
  }

  void _onAppResumed() async {
    // 앱이 포그라운드로 복귀할 때 경과된 시간을 계산하고 업데이트
    DateTime now = DateTime.now();
    String weekStart = getWeekStart(now);

    Map<String, dynamic>? timer = await _dbService.getTimer('v3_4', weekStart);
    DateTime appPausedTime = DateTime.parse(timer!['last_updated_at']);
    _isRunning = timer!['is_running'] == 1;

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
          msg: "활동 시작",
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
    _timerData = timerData;

    // 마지막 활동기록 불러오기
    String lastActivityLogId = _timerData?['last_activity_log_id'] ?? '';
    final activityLog = await _dbService.getActivityLog(lastActivityLogId);
    _currentActivityId = activityLog?['activity_id'];
    _currentActivityLogId = lastActivityLogId;

    // 잔여시간 및 활동시간 초기화 & 재생중 여부 확인
    _remainingSeconds = _timerData?['remaining_seconds'] ?? 0;
    _isRunning = _timerData?['is_running'] == 1;

    DateTime now = DateTime.now().toUtc();
    DateTime lastUpdated = DateTime.parse(_timerData!['last_updated_at']).toUtc();

    if (lastActivityLogId != '') {
      DateTime activityStarted = activityLog!['start_time'] != null ? DateTime.parse(activityLog['start_time']).toUtc() : now;
      int activtyDuration = now.difference(activityStarted).inSeconds;
      activtyDuration = activtyDuration >= 0 ? activtyDuration : 0;
      int activityRestTime = activityLog['rest_time'];
      _currentActivityDuration = activtyDuration - activityRestTime;
    }

    await _updateCurrentActivityDetails();

    if (_isRunning) {
      print("재생중이므로 기존 활동을 이어서 재생합니다.");

      int elapsedSeconds = now.difference(lastUpdated).inSeconds;
      elapsedSeconds = elapsedSeconds >= 0 ? elapsedSeconds : 0;

      // 남은 시간을 감소하고 음수 방지
      _remainingSeconds = (_remainingSeconds - elapsedSeconds).clamp(0, _remainingSeconds);

      // 현재 활동 시간을 증가
      _currentActivityDuration += elapsedSeconds;

      if (_currentActivityId != null) {
        await startTimer(activityId: _currentActivityId!);
        onWaveAnimationRequested?.call();
      } else {
        print('현재 활동 ID를 찾을 수 없습니다.');
      }
    } else {}
    notifyListeners();
  }

  bool get isRunning => _isRunning;

  Future<void> startTimer({required String activityId}) async {
    DateTime now = DateTime.now();
    DateTime utcNow = now.toUtc();
    String weekStart = getWeekStart(now); // 현재 주차를 계산

    final timerData = await _dbService.getTimer(userId, weekStart);

    if (timerData == null) {
      // 타이머를 생성해주는 로직 추가
      print('타이머 데이터를 찾을 수 없습니다.');
      return;
    }

    _timerData = timerData;

    final isRunning = timerData['is_running'] == 1; // 재생중인지 ?

    _timer?.cancel();

    if (isRunning == false) {
      _isRunning = true;

      final lastActivityLogId = timerData['last_activity_log_id'];

      bool isResume = false; // 11분 이내 재시작 했는지
      bool isContinue = false; // 기존과 활동ID가 같은지
      bool shouldCreateNewLog = false;

      String lastActivityListId = "";
      List lastActivity = List.empty();

      if (lastActivityLogId == null || lastActivityLogId == "") {
        print("마지막 활동 로그가 없어서 새로운 활동을 기록합니다");
        shouldCreateNewLog = true;
      } else {
        final lastActivityLog = await _dbService.getActivityLog(lastActivityLogId);

        lastActivityListId = lastActivityLog?['activity_id'];
        lastActivity = await _dbService.getActivityById(lastActivityListId);

        final lastUpdatedAt = DateTime.parse(timerData['last_updated_at']).toUtc();
        isResume = utcNow.difference(lastUpdatedAt).inSeconds <= 660;
        isContinue = lastActivityListId == activityId;

        if (isResume == false || isContinue == false) {
          print("11분이 지났거나 활동이 달라져서 새로운 활동을 기록합니다");
          shouldCreateNewLog = true;
          _currentActivityDuration = 0;
        }
      }

      if (shouldCreateNewLog) {
        print("새로운 활동 기록!");
        // 새로운 활동 로그 생성
        await _dbService.createActivityLog(activityId, _timerData!['timer_id']);

        // 새로 생성된 활동 로그의 ID 가져오기
        final newActivityLog = await _dbService.getLastActivityLog(_timerData!['timer_id']);

        _currentActivityLogId = newActivityLog?['activity_log_id'];
        _currentActivityId = activityId;

        await _updateCurrentActivityDetails();
      } else {
        print("기존 활동 기록 업데이트!");
        _currentActivityLogId = lastActivityLogId;
        _currentActivityId = lastActivity.first['activity_list_id'] as String;
        await _updateCurrentActivityDetails();
        await _dbService.updateActivityLog(_currentActivityLogId, resetEndTime: true);
      }

      await _dbService.updateTimer(_timerData!['timer_id'], _timerData!['user_id'], {
        'last_started_at': utcNow.toIso8601String(),
        'last_updated_at': utcNow.toIso8601String(),
        'last_activity_log_id': _currentActivityLogId,
        'is_running': 1,
      });
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _onTimerTick();
    });
  }

  Future<void> _updateCurrentActivityDetails() async {
    if (_currentActivityId != null) {
      final activity = await _dbService.getActivityById(_currentActivityId!);
      if (activity.isNotEmpty) {
        _currentActivityName = activity.first['activity_name'];
        _currentActivityIcon = activity.first['activity_icon'];
        notifyListeners();
      } else {
        // 활동이 없을 경우 기본값 설정
        _currentActivityName = '전체';
        _currentActivityIcon = 'category_rounded';
      }
    } else {
      // 활동 ID가 없을 경우 기본값 설정
      _currentActivityName = '전체';
      _currentActivityIcon = 'category_rounded';
    }
  }

  Future<void> _onTimerTick() async {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      _currentActivityDuration++; // **현재 활동 시간 증가**
      notifyListeners();
      await _updateTimerInDatabase();
    } else {
      await stopTimer();
    }
  }

  Future<void> _updateTimerInDatabase() async {
    try {
      await _dbService.updateTimer(_timerData!['timer_id'], _timerData!['user_id'], {
        'remaining_seconds': _remainingSeconds,
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      print('타이머 업데이트 중 오류 발생: $e');
    }
  }

  Future<void> stopTimer() async {
    if (_isRunning) {
      _isRunning = false;
      _timer?.cancel();
      await _updateTimerData();
      await _dbService.updateActivityLog(_currentActivityLogId, resetEndTime: false);
      notifyListeners();
    }
  }

  Future<void> _updateTimerData() async {
    DateTime now = DateTime.now();
    DateTime utcNow = now.toUtc();
    String weekStart = getWeekStart(now);
    final timerData = await _dbService.getTimer(userId, weekStart);

    if (timerData != null) {
      final String timerId = timerData['timer_id'];
      final String userId = timerData['user_id'];

      Map<String, dynamic> updatedData = {
        'remaining_seconds': _remainingSeconds,
        'is_running': 0,
        'last_updated_at': utcNow.toIso8601String(),
        'last_activity_log_id': _currentActivityLogId,
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
  } // 주간 활동 데이터 초기화 메서드

  void initializeWeeklyActivityData() async {
    List<Map<String, dynamic>> logs = await activityLogs; // 활동 로그 데이터 가져오기
    _weeklyActivityData.updateAll((key, value) => 0.0);

    for (var log in logs) {
      String startTimeString = log['start_time'];
      int duration = log['activity_duration'] ?? 0;
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
    List<Map<String, dynamic>> allLogs = await _dbService.getAllActivityLogs();

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
    List<Map<String, dynamic>> logs = await _dbService.getAllActivityLogs();

    // 맵 초기화
    _heatMapDataSet = {};

    for (var log in logs) {
      String? startTimeString = log['start_time'];
      int duration = log['activity_duration'] ?? 0;
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
