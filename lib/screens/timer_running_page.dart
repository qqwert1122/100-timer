import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';

class TimerRunningPage extends StatefulWidget {
  final String? activityName;
  final String? activityIcon;

  const TimerRunningPage({
    super.key,
    this.activityName,
    this.activityIcon,
  });

  @override
  State<TimerRunningPage> createState() => _TimerRunningPageState();
}

class _TimerRunningPageState extends State<TimerRunningPage> with TickerProviderStateMixin {
  bool _isInitialized = false;
  late AnimationController _messageAnimationController;
  late Animation<Offset> _messageAnimation;
  late Animation<double> _messageOpacityAnimation;

  List<Wave> waves = [];
  bool _showInitialMessage = true;
  bool _isNewSession = true;
  bool _isDarkMode = false;
  final GlobalKey _circleKey = GlobalKey();

  late Timer _messageTimer;
  int currentMessageIndex = 0; // 메시지 인덱스
  final List<String> messages = []; // 메시지 리스트

  @override
  void initState() {
    super.initState();
    _initMessageAnimation();

    // 메시지 교체 Timer 시작
    _messageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          currentMessageIndex = (currentMessageIndex + 1) % messages.length;
        });
      }
    });

    // 1초 후 웨이브 애니메이션 시작
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _startWaveAnimation();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
      _initAnimations();

      // 1초 후 웨이브 애니메이션 시작
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _startWaveAnimation();
        }
      });

      _isInitialized = true;
    }
  }

  void _initMessageAnimation() {
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _messageAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.easeInOut,
    ));

    _messageOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initAnimations() {
    // 각 웨이브의 애니메이션 설정
    for (int i = 0; i < 3; i++) {
      AnimationController controller = AnimationController(
        duration: const Duration(milliseconds: 4000), // 2초
        vsync: this,
      );

      // 반지름 애니메이션
      Animation<double> radiusAnimation = Tween<double>(
        begin: 70.0, // 시작 크기
        end: 70.0 + (i * 20.0), // 최종 크기
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutQuart, // 더 부드러운 곡선
        ),
      );

      // 불투명도 애니메이션
      Animation<double> opacityAnimation = Tween<double>(
        begin: 0.15,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );

      waves.add(Wave(
        color: _isDarkMode ? Colors.white.withOpacity(0.25 - i * 0.1) : Colors.redAccent.withOpacity(0.25 - i * 0.1),
        strokeWidth: 2.0 + (i * 2.0),
        maxRadius: 40.0 + (i * 5.0),
        minRadius: 40.0,
        radiusAnimation: radiusAnimation,
        opacityAnimation: opacityAnimation,
        controller: controller,
      ));

      // 각 웨이브의 시작을 약간씩 지연
      Future.delayed(Duration(milliseconds: i * 666), () {
        if (mounted) {
          controller.repeat();
        }
      });
    }
  }

  void _startWaveAnimation() {
    for (var wave in waves) {
      wave.controller.repeat();
    }
  }

  String _formatDurationMessage(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      return "${hours}시간";
    }
    return "${minutes}분";
  }

  Widget _buildActivityMessage(TimerProvider timerProvider) {
    // 현재 활동 이름과 시간을 포함한 메시지 생성
    final currentActivityName = timerProvider.currentActivityName;
    final currentActivityDuration = Duration(seconds: timerProvider.currentActivityDuration);
    final minutes = currentActivityDuration.inMinutes;

    messages
      ..clear()
      ..add(_isNewSession ? "새로운 활동을 시작했어요" : "이어서 활동해요")
      ..add(
          "이번주에 ${(currentActivityName ?? '전체').length > 6 ? '${(currentActivityName ?? '전체').substring(0, 6)}...' : currentActivityName ?? '전체'} 활동을 ${_formatDurationMessage(minutes)} 했어요");
    // 현재 메시지
    final message = messages[currentMessageIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          // 슬라이드 애니메이션
          final slideIn = Tween<Offset>(
            begin: const Offset(0, -1), // 위에서 내려오는 애니메이션
            end: Offset.zero,
          ).animate(animation);

          final slideOut = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero, // 아래로 사라지는 애니메이션
          ).animate(animation);

          // 투명도 애니메이션
          final fade = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(animation);

          if (child.key == ValueKey<int>(currentMessageIndex)) {
            // 신규 메시지 애니메이션: 위에서 내려오면서 투명도 증가
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slideIn, child: child),
            );
          } else {
            // 기존 메시지 애니메이션: 아래로 사라지면서 투명도 감소
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slideOut, child: child),
            );
          }
        },
        child: Text(
          message,
          key: ValueKey<int>(currentMessageIndex), // 고유 키를 사용하여 메시지 변경 감지
          style: TextStyle(
            fontSize: 16,
            color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildProgressCircle(TimerProvider timerProvider) {
    final progress = timerProvider.remainingSeconds / timerProvider.totalSeconds;
    final activityColor = ColorService.hexToColor(timerProvider.currentActivityColor);

    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...waves.map(
            (wave) => CustomPaint(
              painter: WavePainter(
                waves: waves,
                baseColor: activityColor,
              ),
              size: const Size(130, 130),
            ),
          ),
          Transform.scale(
            scale: 5,
            child: CircularProgressIndicator(
              key: _circleKey,
              value: progress,
              backgroundColor: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(activityColor),
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                getIconData(widget.activityIcon ?? 'category_rounded'),
                color: activityColor,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                (widget.activityName ?? '전체').length > 6
                    ? '${(widget.activityName ?? '전체').substring(0, 6)}...'
                    : (widget.activityName ?? '전체'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: activityColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(TimerProvider timerProvider) {
    final duration = Duration(seconds: timerProvider.currentActivityDuration);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return SlidingTimer(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      style: TextStyle(
        color: ColorService.hexToColor(timerProvider.currentActivityColor),
        fontSize: 48,
        fontWeight: FontWeight.w500,
        fontFamily: 'chab',
      ),
    );
  }

  @override
  void dispose() {
    _messageTimer.cancel(); // Timer 종료

    _messageAnimationController.dispose();

    for (var wave in waves) {
      wave.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressCircle(timerProvider),
                    const SizedBox(height: 40),
                    _buildTimeDisplay(timerProvider),
                    const SizedBox(
                      height: 10,
                    ),
                    _buildActivityMessage(timerProvider),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      timerProvider.stopTimer();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "휴식하기",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Wave {
  Color color;
  final double strokeWidth;
  final double maxRadius;
  final double minRadius;
  final Animation<double> radiusAnimation;
  final Animation<double> opacityAnimation;
  final AnimationController controller;

  Wave({
    required this.color,
    required this.strokeWidth,
    required this.maxRadius,
    required this.minRadius,
    required this.radiusAnimation,
    required this.opacityAnimation,
    required this.controller,
  });
}

class WavePainter extends CustomPainter {
  final List<Wave> waves;
  final Color baseColor;

  WavePainter({
    required this.waves,
    required this.baseColor,
  }) : super(repaint: Listenable.merge([...waves.map((w) => w.controller)]));

  @override
  void paint(Canvas canvas, Size size) {
    for (var wave in waves) {
      final paint = Paint()
        ..color = baseColor.withOpacity(wave.opacityAnimation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = wave.strokeWidth;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        wave.radiusAnimation.value,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}

class AnimatedNumber extends StatelessWidget {
  final int number;
  final TextStyle? style;

  const AnimatedNumber({
    Key? key,
    required this.number,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 35,
      height: 60,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: const Interval(0.5, 1.0, curve: Curves.easeInOut), // 새 숫자는 후반부에
        switchOutCurve: const Interval(0.0, 0.5, curve: Curves.easeInOut), // 이전 숫자는 전반부에
        transitionBuilder: (Widget child, Animation<double> animation) {
          // 나가는 숫자의 애니메이션
          if (child.key != ValueKey<int>(number)) {
            return FadeTransition(
              opacity: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
              )),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
                )),
                child: child,
              ),
            );
          }

          // 들어오는 숫자의 애니메이션
          return FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
            )),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
              )),
              child: child,
            ),
          );
        },
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          List<Widget> children = previousChildren;
          if (currentChild != null) {
            children = children.toList()..add(currentChild);
          }
          return Stack(
            alignment: Alignment.center,
            children: children,
          );
        },
        child: Text(
          number.toString().padLeft(1, '0'),
          key: ValueKey<int>(number),
          style: style,
        ),
      ),
    );
  }
}

class SlidingTimer extends StatelessWidget {
  final int hours;
  final int minutes;
  final int seconds;
  final TextStyle? style;

  const SlidingTimer({
    Key? key,
    required this.hours,
    required this.minutes,
    required this.seconds,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hours
        AnimatedNumber(number: hours ~/ 10, style: style),
        AnimatedNumber(number: hours % 10, style: style),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(':', style: style),
        ),
        // Minutes
        AnimatedNumber(number: minutes ~/ 10, style: style),
        AnimatedNumber(number: minutes % 10, style: style),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(':', style: style),
        ),
        // Seconds
        AnimatedNumber(number: seconds ~/ 10, style: style),
        AnimatedNumber(number: seconds % 10, style: style),
      ],
    );
  }
}

class AnimatedBackground extends StatelessWidget {
  final Duration duration;
  final Color baseColor;
  final double intensity;

  const AnimatedBackground({
    super.key,
    required this.duration,
    required this.baseColor,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BackgroundPainter(
        duration: duration,
        baseColor: baseColor,
        intensity: intensity,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final Duration duration;
  final Color baseColor;
  final double intensity;

  BackgroundPainter({
    required this.duration,
    required this.baseColor,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hours = duration.inHours.toDouble();
    // Intensity increases with time but caps at 0.4 for subtle effect
    final opacity = (hours * 0.05).clamp(0.0, 0.4) * intensity;

    // Create multiple gradient layers
    final paint = Paint();

    // Base gradient layer
    final baseGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.5,
      colors: [
        baseColor.withOpacity(opacity * 0.3),
        baseColor.withOpacity(opacity * 0.1),
        baseColor.withOpacity(0),
      ],
    );

    // Secondary gradient layers for artistic effect
    final secondaryGradient = RadialGradient(
      center: const Alignment(0.3, -0.3),
      radius: 1.2,
      colors: [
        baseColor.withOpacity(opacity * 0.2),
        baseColor.withOpacity(0),
      ],
    );

    final tertiaryGradient = RadialGradient(
      center: const Alignment(-0.3, 0.3),
      radius: 1.2,
      colors: [
        baseColor.withOpacity(opacity * 0.15),
        baseColor.withOpacity(0),
      ],
    );

    // Draw base layer
    paint.shader = baseGradient.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    // Draw secondary layers
    paint.shader = secondaryGradient.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    paint.shader = tertiaryGradient.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) {
    return duration != oldDelegate.duration || baseColor != oldDelegate.baseColor || intensity != oldDelegate.intensity;
  }
}
