import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project1/utils/timer_provider.dart';

class TextIndicator extends StatefulWidget {
  final TimerProvider timerProvider; // 타입을 명확히 지정하는 것이 좋습니다 (예: TimerProvider)

  const TextIndicator({
    Key? key,
    required this.timerProvider,
  }) : super(key: key);

  @override
  State<TextIndicator> createState() => _TextIndicatorState();
}

class _TextIndicatorState extends State<TextIndicator>
    with TickerProviderStateMixin {
  late AnimationController _textAnimationController;
  late Animation<Offset> _textAnimation;
  late Animation<double> _opacityAnimation;
  late Timer _textSwitchTimer;

  bool _showText1 = true;

  @override
  void initState() {
    super.initState();

    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _textAnimation = Tween<Offset>(
      begin: const Offset(0, 0), // 현재 위치
      end: const Offset(0, -1), // 위로 이동
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0, // 처음에는 투명
      end: 1.0, // 최종적으로 불투명
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeInOut,
    ));

    _textAnimationController.addListener(() {
      setState(() {}); // 애니메이션 값이 변경될 때마다 UI를 업데이트
    });

    // 3초마다 텍스트 전환
    _textSwitchTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _showText1 = !_showText1; // 텍스트 상태 전환
      });

      _textAnimationController.forward(from: 0); // 애니메이션 시작
    });
  }

  @override
  void dispose() {
    _textSwitchTimer.cancel();
    _textAnimationController.dispose(); // 애니메이션 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _textAnimation,
      child: Opacity(
        opacity: _opacityAnimation.value,
        child: _showText1
            ? Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '눌러서 ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        fontFamily: 'NanumSquare',
                      ),
                    ),
                    widget.timerProvider.isRunning
                        ? TextSpan(
                            text: '휴식',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueAccent.shade200,
                              fontFamily: 'NanumSquare',
                            ),
                          )
                        : TextSpan(
                            text: '버닝',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.redAccent.shade200,
                              fontFamily: 'NanumSquare',
                            ),
                          ),
                    const TextSpan(
                      text: '하기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        fontFamily: 'NanumSquare',
                      ),
                    ),
                  ],
                ),
                key: const ValueKey(false), // Text.rich에도 키 추가
              )
            : const Text(
                "9월 2주차",
                key: ValueKey(true),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  fontFamily: 'NanumSquare',
                ),
              ),
      ),
    );
  }
}
