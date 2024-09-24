import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project1/utils/database_service.dart';

class TimerProvider with ChangeNotifier {
  Timer? _timer;
  bool _isRunning = false;
  int _remainingSeconds = 360000; // 기본값 100시간 (초 단위)
  Map<String, dynamic>? _timerData; // 타이머 데이터 저장용

  final DatabaseService _dbService = DatabaseService(); // 데이터베이스 서비스

  // 타이머 데이터를 받아서 초기화
  void setTimerData(Map<String, dynamic> timerData) {
    _timerData = timerData;
    _remainingSeconds =
        _timerData?['remaining_seconds'] ?? 0; // 타이머 데이터를 받아 남은 시간 설정
    _isRunning = _timerData?['is_running'] == 1 ? true : false;

    if (_isRunning) {
      // 타이머가 실행 중이라면, 마지막 시작 시간과 현재 시간의 차이를 계산
      DateTime lastStarted = DateTime.parse(_timerData!['last_started_at']);
      DateTime now = DateTime.now();
      int elapsedSeconds = now.difference(lastStarted).inSeconds;

      // 지난 시간을 remaining_seconds에서 차감
      _remainingSeconds -= elapsedSeconds;
      if (_remainingSeconds < 0) _remainingSeconds = 0;

      startTimer(resume: true); // 타이머를 이어서 시작
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

  // 타이머 시작
  void startTimer({bool resume = false}) async {
    if (!_isRunning || resume) {
      _isRunning = true;

      // 타이머가 처음 시작될 때만 last_started_at 기록
      if (!resume) {
        await _dbService.updateTimer(
            _timerData!['timer_id'], _timerData!['user_id'], {
          'last_started_at': DateTime.now().toIso8601String(),
          'is_running': 1
        });
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          notifyListeners();
        } else {
          stopTimer();
        }
      });
    }
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
    if (_timerData != null) {
      final String timerId = _timerData!['timer_id'];
      final String userId = _timerData!['user_id'];
      DateTime now = DateTime.now();

      // 남은 시간을 업데이트한 새로운 데이터
      Map<String, dynamic> updatedData = {
        'remaining_seconds': _remainingSeconds,
        'is_running': 0,
        'last_updated_at': now.toIso8601String(),
      };

      // 데이터베이스 업데이트
      await _dbService.updateTimer(timerId, userId, updatedData);

      print('타이머가 데이터베이스에 저장되었습니다: $updatedData');
    }
  }
}
