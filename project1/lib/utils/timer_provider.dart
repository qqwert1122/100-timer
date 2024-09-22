import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'timer_service.dart'; // TimerService import

class TimerProvider with ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 360000; // 초기값: 100시간 (360,000초)
  bool _isRunning = false;
  final TimerService _timerService = TimerService(); // TimerService 인스턴스 생성

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;

  String get formattedTime {
    final hours = (_remainingSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes =
        ((_remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // 주차별 타이머 생성 또는 로드
  Future<void> createOrLoadTimer(int userId) async {
    await _timerService.createOrLoadCurrentWeekTimer(userId);
    final timerData = await _timerService.loadTimerData();
    if (timerData != null) {
      _remainingSeconds = timerData['remaining_hours'];
      _isRunning = false;
      notifyListeners();
    }
  }

  // 타이머 시작
  void startTimer() {
    if (!_isRunning) {
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          notifyListeners();
          _timerService.saveTimerData(
            timerId: DateTime.now().millisecondsSinceEpoch,
            userId: 1,
            weekStart: DateTime.now(),
            totalHours: 360000,
            remainingHours: _remainingSeconds,
            lastUpdatedAt: DateTime.now(),
            isReset: false,
          );
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
      notifyListeners();
      _timerService.saveTimerData(
        timerId: DateTime.now().millisecondsSinceEpoch,
        userId: 1,
        weekStart: DateTime.now(),
        totalHours: 360000,
        remainingHours: _remainingSeconds,
        lastUpdatedAt: DateTime.now(),
        isReset: false,
      );
    }
  }
}
