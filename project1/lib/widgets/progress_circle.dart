import 'dart:async';

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class ProgressCircle extends StatefulWidget {
  final int remainingSeconds;
  final int totalSeconds;

  const ProgressCircle({
    Key? key,
    required this.remainingSeconds,
    this.totalSeconds = 360000, // 기본값: 100시간 (360,000초)
  }) : super(key: key);
  @override
  State<ProgressCircle> createState() => _ProgressCircleState();
}

class _ProgressCircleState extends State<ProgressCircle> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.remainingSeconds;

    // 타이머 시작
    _start();
  }

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      setState(() {
        if (_remainingSeconds >= 30) {
          _remainingSeconds -= 30; // 1분(60초) 감소
        } else {
          _remainingSeconds = 0;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 응원 메시지 반환 함수
  String getEncouragementMessage(double percent) {
    if (percent >= 1.0) {
      return "축하합니다! 목표를 달성하셨습니다! 🎉";
    } else if (percent >= 0.8) {
      return "거의 다 왔어요! 조금만 더 힘내세요! 💪";
    } else if (percent >= 0.5) {
      return "절반을 넘었어요! 잘하고 있어요! 👍";
    } else if (percent >= 0.2) {
      return "좋아요! 꾸준히 진행하고 있어요! 😊";
    } else {
      return "시작이 반입니다! 파이팅! 🚀";
    }
  }

  @override
  Widget build(BuildContext context) {
    double percent = (1 - _remainingSeconds / widget.totalSeconds);

    String percentText = '${(percent * 100).toStringAsFixed(0)}%';

    String encouragementMessage = getEncouragementMessage(percent);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(
                "이번주 달성도",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                encouragementMessage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 30,
        ),
        CircularPercentIndicator(
          radius: 100.0,
          lineWidth: 20.0,
          animation: true,
          percent: percent.clamp(0.0, 1.0), // 0.0과 1.0 사이로 제한
          center: Text(
            percentText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Colors.redAccent,
          backgroundColor: Colors.grey.shade200,
        ),
      ],
    );
  }
}
