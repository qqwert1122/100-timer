import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/screens/timer_page.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';

class TimerRunningPage extends StatefulWidget {
  const TimerRunningPage({
    super.key,
  });

  @override
  State<TimerRunningPage> createState() => _TimerRunningPageState();
}

class _TimerRunningPageState extends State<TimerRunningPage> with TickerProviderStateMixin {
  bool _isInitialized = false;
  late AnimationController _messageAnimationController;
  late Animation<Offset> _messageAnimation;
  late Animation<double> _messageOpacityAnimation;
  late final DatabaseService _dbService; // 주입받을 DatabaseService
  late final TimerProvider timerProvider;

  List<Wave> waves = [];
  bool _showInitialMessage = true;
  bool _isNewSession = true;
  bool _isDarkMode = false;
  final GlobalKey _circleKey = GlobalKey();

  late Timer _messageTimer;
  int currentMessageIndex = 0; // 메시지 인덱스
  final List<String> messages = []; // 메시지 리스트
  bool _hasShownCompletionDialog = false; // 모달 표시 여부 플래그 추가

  @override
  void initState() {
    super.initState();

    _dbService = Provider.of<DatabaseService>(context, listen: false);
    timerProvider = Provider.of<TimerProvider>(context, listen: false);

    _initializeTimer();
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

  String getWeekStart(DateTime date) {
    int weekday = date.weekday;
    // 월요일을 기준으로 주 시작일을 계산 (월요일이 1, 일요일이 7)
    DateTime weekStart = date.subtract(Duration(days: weekday - 1));
    return weekStart.toIso8601String().split('T').first;
  }

  Future<void> _initializeTimer() async {
    try {
      // timerData 가져오기
      if (timerProvider.timerData == null) {
        final weekStart = getWeekStart(DateTime.now());
        final timer = await _dbService.getTimer(weekStart);
        if (timer != null) {
          timerProvider.setTimerData(timer);
        }
      }

      if (timerProvider.currentSessionId != null && timerProvider.currentSessionId!.isNotEmpty) {
        // 현재 세션 먼저 가져오기
        final currentSession = await _dbService.getSession(timerProvider.currentSessionId!);

        if (currentSession != null) {
          // 세션이 있을 때만 체크
          if (timerProvider.isRunning) {
            final startTime = DateTime.parse(currentSession['start_time']);
            final currentDuration = DateTime.now().difference(startTime).inSeconds;
            final targetDuration = currentSession['target_duration'];

            bool isExceeded = currentDuration >= targetDuration;

            if (isExceeded) {
              await _handleStop(isExceeded: true, targetDuration: targetDuration);
            } else {
              timerProvider.resumeTimer(
                sessionId: timerProvider.currentSessionId!,
              );
            }
          }
        }
      } else {
        timerProvider.startTimer(
          activityId: timerProvider.currentActivityId!,
          mode: timerProvider.currentSessionMode!,
          targetDuration: timerProvider.currentSessionTargetDuration!,
        );
      }
    } catch (e) {
      print('Error initializing timer: $e');
      // 에러 발생 시 TimerPage로 이동
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => TimerPage(timerData: timerProvider.timerData!),
              ),
            );
          },
        );
      }
    }
  }

  Future<void> _handleStop({bool isExceeded = false, int? targetDuration}) async {
    final timer = timerProvider.timerData!;

    try {
      // 메시지 Timer 정리
      _messageTimer.cancel();

      // 세션 종료

      await timerProvider.stopTimer(isExceeded: isExceeded, sessionId: timerProvider.currentSessionId!);

      // 애니메이션 중지
      for (var wave in waves) {
        wave.controller.stop();
      }

      // exceeded인 경우에만 completion 모달 표시
      if (isExceeded && mounted) {
        _showCompletionDialog(timerProvider, targetDuration!);
      } else {
        // 일반 종료인 경우 바로 타이머 페이지로 이동

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => TimerPage(timerData: timer),
            ),
          );
        }
      }
    } catch (e) {
      print('Error handling stop: $e');
    }
  }

  void _showCompletionDialog(TimerProvider timerProvider, int targetDuration) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          titlePadding: const EdgeInsets.all(20),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '목표 달성',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: timerProvider.currentActivityName ?? '전체',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const TextSpan(
                      text: ' 활동의',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '목표 시간 ${Duration(seconds: targetDuration).inMinutes}분을 달성했어요!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '다음에 또 도전해요 💪',
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TimerPage(timerData: timerProvider.timerData!),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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
        begin: 100.0, // 시작 크기
        end: 100.0 + (i * 20.0), // 최종 크기
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
        maxRadius: 100.0 + (i * 5.0),
        minRadius: 100.0,
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
      return "$hours시간";
    }
    return "$minutes분";
  }

  Widget _buildActivityMessage(TimerProvider timerProvider) {
    // 현재 활동 이름과 시간을 포함한 메시지 생성
    final currentActivityName = timerProvider.currentActivityName;
    final currentSessionDuration = Duration(seconds: timerProvider.currentSessionDuration);
    final minutes = currentSessionDuration.inMinutes;

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
            fontSize: 18,
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
    final activityName = timerProvider.currentActivityName;
    final activityIcon = timerProvider.currentActivityIcon;

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
              size: const Size(150, 150),
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
                getIconData(activityIcon ?? 'category_rounded'),
                color: activityColor,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                (activityName ?? '전체').length > 6 ? '${(activityName ?? '전체').substring(0, 6)}...' : (activityName ?? '전체'),
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
    final duration = Duration(seconds: timerProvider.currentSessionDuration);
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
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: SafeArea(
          child: Consumer<TimerProvider>(
            builder: (context, timerProvider, child) {
              if (timerProvider.isExceeded && !_hasShownCompletionDialog) {
                _hasShownCompletionDialog = true;
                // Frame이 완전히 빌드된 후 모달 표시
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showCompletionDialog(timerProvider, timerProvider.currentSessionTargetDuration!);
                });
              }

              return Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProgressCircle(timerProvider),
                        const SizedBox(height: 80),
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
                          // 활동 종료 전 모달창 띄우기
                          showDialog(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                title: const Text("활동 종료"),
                                content: const Text("활동을 마무리 하시겠어요?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      // 아니오: 모달창 닫기
                                      Navigator.of(ctx).pop();
                                    },
                                    child: const Text(
                                      "아니오",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(ctx).pop();
                                      await _handleStop();
                                    },
                                    child: const Text("네", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text(
                          "활동 종료",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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
