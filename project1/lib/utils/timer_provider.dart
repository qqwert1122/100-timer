import 'dart:async';

import 'package:flutter/material.dart';

class TimerProvider with ChangeNotifier {
  Timer? _timer;
  int _elapsedTime = 360000; // 100시간을 초로 변환 (100 * 60 * 60)
  bool _isRunning = false;

  int get elapsedTime => _elapsedTime;
  bool get isRunning => _isRunning;

  String get formattedTime {
    final hours = (_elapsedTime ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_elapsedTime % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedTime % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void startTimer() {
    if (!_isRunning) {
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_elapsedTime > 0) {
          _elapsedTime--;
          notifyListeners();
        } else {
          stopTimer(); // 타이머가 끝나면 자동으로 정지
        }
      });
    }
  }

  void stopTimer() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }
}
