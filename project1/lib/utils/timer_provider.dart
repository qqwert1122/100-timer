import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/database_service.dart';

class TimerProvider with ChangeNotifier {
  Timer? _timer;
  bool _isRunning = false;
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

  final DatabaseService _dbService = DatabaseService();
  final String userId;
  String? _currentActivityId;
  String? _currentActivityName;
  String? _currentActivityIcon;

  // 현재 활동 정보를 가져오는 getter
  String? get currentActivityId => _currentActivityId;
  String? get currentActivityName => _currentActivityName;
  String? get currentActivityIcon => _currentActivityIcon;

  TimerProvider({required this.userId});

  // 현재 활동 정보를 설정하는 메서드
  void setCurrentActivity(
      String activityId, String activityName, String activityIcon) {
    _currentActivityId = activityId;
    _currentActivityName = activityName;
    _currentActivityIcon = activityIcon;
    notifyListeners();
  }

  void setTimerData(Map<String, dynamic> timerData) async {
    _timerData = timerData;
    _remainingSeconds = _timerData?['remaining_seconds'] ?? 0;
    _currentActivityDuration = 0; // **활동 시간 초기화**
    _isRunning = _timerData?['is_running'] == 1;

    String lastActivityLogId = _timerData?['last_activity_log_id'] ?? '';
    final activityLog = await _dbService.getActivityLog(lastActivityLogId);
    _currentActivityId = activityLog?['activity_id'];
    _currentActivityLogId = lastActivityLogId;

    await _updateCurrentActivityDetails();

    bool isResume = false;

    if (_isRunning) {
      DateTime lastStarted =
          DateTime.parse(_timerData!['last_started_at']).toUtc();
      DateTime now = DateTime.now().toUtc();
      int elapsedSeconds = now.difference(lastStarted).inSeconds;

      isResume = now.difference(lastStarted).inSeconds <= 660;

      _remainingSeconds -= elapsedSeconds;
      if (isResume) {
        _currentActivityDuration += elapsedSeconds; // **현재 활동 시간 업데이트**
      }

      if (_remainingSeconds < 0) _remainingSeconds = 0;

      if (_currentActivityId != null) {
        await startTimer(activityId: _currentActivityId!);
      } else {
        print('현재 활동 ID를 찾을 수 없습니다.');
      }
    }
    notifyListeners();
  }

  String get formattedTime {
    final hours = (_remainingSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes =
        ((_remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String get formattedActivityTime {
    final hours = (_currentActivityDuration ~/ 3600).toString().padLeft(2, '0');
    final minutes =
        ((_currentActivityDuration % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_currentActivityDuration % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  bool get isRunning => _isRunning;

  String getWeekStart(DateTime date) {
    int weekday = date.weekday;
    DateTime weekStart = date.subtract(Duration(days: weekday - 1));
    return weekStart.toUtc().toIso8601String().split('T').first;
  }

  Future<void> startTimer({required String activityId}) async {
    DateTime now = DateTime.now().toUtc();
    String weekStart = getWeekStart(now);

    final timerData = await _dbService.getTimer(userId, weekStart);

    if (timerData == null) {
      print('타이머 데이터를 찾을 수 없습니다.');
      return;
    }

    _timerData = timerData;

    final isRunning = timerData['is_running'] == 1;
    final lastActivityLogId = timerData['last_activity_log_id'];
    final lastActivityLog = await _dbService.getActivityLog(lastActivityLogId);
    final lastActivityListId = lastActivityLog?['activity_id'];
    final lastActivity = await _dbService.getActivityById(lastActivityListId);

    bool isResume = false;
    bool shouldCreateNewLog = false;
    bool isContinue = false;

    if (lastActivityLogId != null && lastActivityLogId != '') {
      if (isRunning == false) {
        _isRunning = true;
        final lastStartedAt =
            DateTime.parse(timerData['last_started_at']).toUtc();
        isResume = now.difference(lastStartedAt).inSeconds <= 660;
        isContinue = lastActivityListId == activityId;

        if (isResume == false || isContinue == false) {
          print("11분이 지났거나 활동이 달라져서 새로운 활동을 기록합니다");
          shouldCreateNewLog = true;
          _currentActivityDuration = 0;
        }
      }
    } else {
      print("마지막 활동 로그가 없어 새로운 활동을 기록합니다");
      shouldCreateNewLog = true;
    }

    if (shouldCreateNewLog) {
      print("새로운 활동 기록!");
      // 새로운 활동 로그 생성
      await _dbService.createActivityLog(activityId, _timerData!['timer_id']);

      // 새로 생성된 활동 로그의 ID 가져오기
      final newActivityLog =
          await _dbService.getLastActivityLog(_timerData!['timer_id']);

      _currentActivityLogId = newActivityLog?['activity_log_id'];
      _currentActivityId = activityId;

      await _updateCurrentActivityDetails();

      await _dbService
          .updateTimer(_timerData!['timer_id'], _timerData!['user_id'], {
        'last_started_at': now.toIso8601String(),
        'last_activity_log_id': _currentActivityLogId,
        'is_running': 1
      });
    } else {
      print("기존 활동 기록 업데이트!");
      _currentActivityLogId = lastActivityLogId;
      _currentActivityId = lastActivity.first['activity_list_id'] as String;
      await _updateCurrentActivityDetails();

      await _dbService.updateActivityLog(_currentActivityLogId,
          resetEndTime: true);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _onTimerTick();
    });
    print("타이머가 시작되었습니다.");
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

      if (_remainingSeconds % 60 == 0) {
        await _updateTimerInDatabase();
      }
    } else {
      await stopTimer();
    }
  }

  Future<void> _updateTimerInDatabase() async {
    try {
      await _dbService
          .updateTimer(_timerData!['timer_id'], _timerData!['user_id'], {
        'remaining_seconds': _remainingSeconds,
        'last_updated_at': DateTime.now().toUtc().toIso8601String()
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
      await _dbService.updateActivityLog(_currentActivityLogId,
          resetEndTime: false);
      notifyListeners();
    }
  }

  Future<void> _updateTimerData() async {
    DateTime now = DateTime.now().toUtc();
    String weekStart = getWeekStart(now);
    final timerData = await _dbService.getTimer(userId, weekStart);

    if (timerData != null) {
      final String timerId = timerData['timer_id'];
      final String userId = timerData['user_id'];

      Map<String, dynamic> updatedData = {
        'remaining_seconds': _remainingSeconds,
        'is_running': 0,
        'last_updated_at': now.toIso8601String(),
        'last_activity_log_id': _currentActivityLogId,
      };

      await _dbService.updateTimer(timerId, userId, updatedData);
    }
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
      if (startTimeString.isNotEmpty) {
        DateTime startTime = DateTime.parse(startTimeString).toLocal();
        String dayOfWeek = DateFormat.E('ko_KR').format(startTime);
        _weeklyActivityData[dayOfWeek] =
            (_weeklyActivityData[dayOfWeek] ?? 0) + (duration / 60); // 분 단위로 더함
      }
    }
    notifyListeners();
  }

  // activityLogs 메서드 추가 - 활동 로그 가져오기
  Future<List<Map<String, dynamic>>> get activityLogs async {
    return await _dbService.getAllActivityLogs(); // DB의 모든 활동 로그 가져오기
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
      if (startTimeString != null && startTimeString.isNotEmpty) {
        DateTime date = DateTime.parse(startTimeString).toLocal();

        // 날짜 부분만 사용하기 위해 시간 정보 제거
        DateTime dateOnly = DateTime(date.year, date.month, date.day);

        // 기존 값이 있으면 누적
        if (_heatMapDataSet.containsKey(dateOnly)) {
          _heatMapDataSet[dateOnly] = _heatMapDataSet[dateOnly]! + duration;
        } else {
          _heatMapDataSet[dateOnly] = duration;
        }
      }
    }
    notifyListeners();
  }
}
