import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/timer_provider.dart';

class TextIndicator extends StatefulWidget {
  final TimerProvider timerProvider; // 타입을 명확히 지정하는 것이 좋습니다 (예: TimerProvider)

  const TextIndicator({
    super.key,
    required this.timerProvider,
  });

  @override
  State<TextIndicator> createState() => _TextIndicatorState();
}

class _TextIndicatorState extends State<TextIndicator> with TickerProviderStateMixin {
  late AnimationController _textAnimationController;
  late Animation<Offset> _textAnimation;
  late Animation<double> _opacityAnimation;
  late Timer _textSwitchTimer;

  bool _showText1 = true;

  String formatToMonthWeek(DateTime date) {
    // 날짜의 해당 월의 첫 번째 날짜를 가져옴
    DateTime firstDayOfMonth = DateTime(date.year, date.month, 1);

    // 주차 계산: 해당 월의 첫 번째 날짜와 현재 날짜의 차이
    int weekOfMonth = ((date.day + firstDayOfMonth.weekday - 1) / 7).ceil();

    // "월 주차" 형식으로 반환
    String month = DateFormat.MMMM('ko_KR').format(date); // 예: 10월
    return "$month $weekOfMonth주차";
  }

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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    DateTime now = DateTime.now(); // 현재 날짜
    String formattedDate = formatToMonthWeek(now);

    return SlideTransition(
      position: _textAnimation,
      child: Opacity(
        opacity: _opacityAnimation.value,
        child: _showText1
            ? Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '눌러서 ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    widget.timerProvider.isRunning
                        ? TextSpan(
                            text: '휴식',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueAccent.shade200,
                            ),
                          )
                        : TextSpan(
                            text: '버닝',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.redAccent.shade200,
                            ),
                          ),
                    TextSpan(
                      text: '하기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                key: const ValueKey(false), // Text.rich에도 키 추가
              )
            : Text(
                formattedDate,
                key: const ValueKey(true),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
      ),
    );
  }
}
