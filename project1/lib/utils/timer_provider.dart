import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project1/utils/database_service.dart';

class TimerProvider with ChangeNotifier {
  Timer? _timer;
  bool _isRunning = false;
  int _remainingSeconds = 360000; // 기본값 100시간 (초 단위)
  Map<String, dynamic>? _timerData; // 타이머 데이터 저장용
  String? _currentActivityId; // 현재 액티비티 ID를 저장

  final DatabaseService _dbService = DatabaseService(); // 데이터베이스 서비스

  // 타이머 데이터를 받아서 초기화
  void setTimerData(Map<String, dynamic> timerData) {
    _timerData = timerData;
    _remainingSeconds =
        _timerData?['remaining_seconds'] ?? 0; // 타이머 데이터를 받아 남은 시간 설정
    _isRunning = _timerData?['is_running'] == 1 ? true : false;

    String lastActivityId = _timerData?['last_activity_id'] ?? '';

    if (_isRunning) {
      // 타이머가 실행 중이라면, 마지막 시작 시간과 현재 시간의 차이를 계산
      DateTime lastStarted = DateTime.parse(_timerData!['last_started_at']);
      DateTime now = DateTime.now();
      int elapsedSeconds = now.difference(lastStarted).inSeconds;

      // 지난 시간을 remaining_seconds에서 차감
      _remainingSeconds -= elapsedSeconds;
      if (_remainingSeconds < 0) _remainingSeconds = 0;

      startTimer(activityId: lastActivityId);
    }
    notifyListeners(); // UI 업데이트
  }

  // 남은 시간을 '시:분:초' 형식으로 변환하는 getter
  String get formattedTime {
    final hours = (_remainingSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes =
        ((_remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // 타이머가 실행 중인지 확인하는 getter
  bool get isRunning => _isRunning;
  String userId = 'v3_4';

  String getWeekStart(DateTime date) {
    int weekday = date.weekday;
    // 월요일을 기준으로 주 시작일을 계산 (월요일이 1, 일요일이 7)
    DateTime weekStart = date.subtract(Duration(days: weekday - 1));
    return weekStart.toIso8601String().split('T').first;
  }

  // 타이머 시작
  void startTimer({required String activityId}) async {
    _currentActivityId = activityId;
    // 타이머 데이터를 DB에서 가져옴

    DateTime now = DateTime.now();
    String weekStart = getWeekStart(now);
    final timerData = await _dbService.getTimer(userId, weekStart);

    if (timerData == null) {
      print('타이머 데이터를 찾을 수 없습니다.');
      return;
    }
    print('타이머 데이터를 가져왔습니다.');

    // 타이머가 실행 중인 경우를 확인
    final isRunning = timerData['is_running'] == 1;
    // last_activity_log_id가 null이 아닌지 확인
    final lastActivityId =
        timerData['last_activity_id']; // null 또는 activity_log_id

    bool isResume = false;

    bool shouldCreateNewLog = false;

    // last_activity_log_id가 null이 아닌 경우만 처리
    if (lastActivityId != null) {
      // 마지막 시작 시간과 지금 시간을 비교해서 11분이 넘는지 확인
      final lastStartedAt = DateTime.parse(timerData['last_started_at']);
      isResume =
          now.difference(lastStartedAt).inSeconds <= 660; // 11분 이내면 resume

      // 마지막 액티비티 로그에서 활동 ID를 가져옴
      final activityLog =
          await _dbService.getLastActivityLog(timerData['timer_id']);

      final activityListId =
          activityLog?['activity_id']; // 기존 로그의 activity_list_id

      if (activityListId != activityId) {
        // print('activityListId != activityId:  $shouldCreateNewLog');
        // print('activityListId: $activityListId');
        // print('activityId: $activityId');
        // 다른 활동을 선택했으므로 새로운 로그 생성 필요
        shouldCreateNewLog = true;
      } else if (!isResume) {
        // 동일한 활동이지만 11분 이상 경과했으면 새로운 로그 생성

        shouldCreateNewLog = true;
      }
    } else {
      // 로그가 없는 경우 신규 로그를 생성해야 함
      shouldCreateNewLog = true;
    }
    print('shouldCreateNewLog: $shouldCreateNewLog');
    String activityLogId;

    if (!isRunning || !isResume) {
      _isRunning = true;

      String activityLogId;

      if (shouldCreateNewLog) {
        // 새로운 로그 생성
        await _dbService.createActivityLog(activityId, _timerData!['timer_id']);

        // 새로 생성된 activity_log_id를 받아서 타이머 업데이트
        final logData =
            await _dbService.getLastActivityLog(_timerData!['timer_id']);
        activityLogId = logData?['activity_log_id'] ?? ''; // 로그가 있으면 ID 사용

        // 타이머에 새 로그 ID와 시작 시간을 업데이트
        await _dbService
            .updateTimer(_timerData!['timer_id'], _timerData!['user_id'], {
          'last_started_at': now.toIso8601String(),
          'last_activity_id': activityLogId, // 새 로그 ID 저장
          'is_running': 1
        });
      }
    } else {
      // 기존 타이머 유지, 로그 업데이트
      activityLogId = lastActivityId;

      // 11분 이내라면 기존 로그를 업데이트 (예: 활동 시간을 업데이트)
      await _dbService.updateActivityLog(activityLogId);
    }

    // 타이머 실행
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();

        if (_remainingSeconds % 60 == 0) {
          await _dbService
              .updateTimer(_timerData!['timer_id'], _timerData!['user_id'], {
            'remaining_seconds': _remainingSeconds,
            'last_updated_at': DateTime.now().toIso8601String()
          });
        }
      } else {
        stopTimer();
      }
    });
  }

  // 타이머 정지
  void stopTimer() {
    if (_isRunning) {
      _isRunning = false;
      _timer?.cancel();
      notifyListeners(); // UI 업데이트를 위해 알림
      _updateTimerData();
    }
  }

// 데이터베이스에 남은 시간과 last_updated_at 업데이트
  Future<void> _updateTimerData() async {
    DateTime now = DateTime.now();
    String weekStart = getWeekStart(now);
    final timerData = await _dbService.getTimer(userId, weekStart);

    if (_timerData != null) {
      final String timerId = _timerData!['timer_id'];
      final String userId = _timerData!['user_id'];
      DateTime now = DateTime.now();

      // 남은 시간을 업데이트한 새로운 데이터
      Map<String, dynamic> updatedData = {
        'remaining_seconds': _remainingSeconds,
        'is_running': 0,
        'last_updated_at': now.toIso8601String(),
        'last_activity_id': _currentActivityId,
      };

      // 데이터베이스 업데이트
      await _dbService.updateTimer(timerId, userId, updatedData);
      print(_currentActivityId);
    }
  }

  // activity_log로 update
}
