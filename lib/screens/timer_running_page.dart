import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/screens/timer_page.dart';
import 'package:project1/screens/timer_result_page.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/responsive_size.dart';

class TimerRunningPage extends StatefulWidget {
  final Map<String, dynamic> timerData;

  const TimerRunningPage({super.key, required this.timerData});

  @override
  State<TimerRunningPage> createState() => _TimerRunningPageState();
}

class _TimerRunningPageState extends State<TimerRunningPage> with TickerProviderStateMixin {
  late AnimationController _messageAnimationController;
  late Animation<Offset> _messageAnimation;
  late Animation<double> _messageOpacityAnimation;
  late final DatabaseService _dbService; // 주입받을 DatabaseService
  late final TimerProvider timerProvider;

  bool _isProviderInitialized = false;
  bool _isTimerInitialized = false;
  bool _isAnimationInitialized = false;
  bool _isListenerAdded = false;
  bool _isNavigating = false; // 네비게이션 상태 추적

  List<Wave> waves = [];
  bool _showInitialMessage = true;
  bool _isNewSession = true;
  bool _isDarkMode = false;
  final GlobalKey _circleKey = GlobalKey();

  late Timer _messageTimer;
  int currentMessageIndex = 0;
  final List<String> messages = [];
  bool _hasShownCompletionDialog = false;

  bool _isMusicOn = false;
  bool _isLightOn = false;
  bool _isAlarmOn = false;

  @override
  void initState() {
    super.initState();

    _dbService = Provider.of<DatabaseService>(context, listen: false);
    timerProvider = Provider.of<TimerProvider>(context, listen: false);

    if (!_isListenerAdded) {
      timerProvider.addListener(_handleTimerStateChange);
      _isListenerAdded = true;
    }

    _initTimer();
    _initMessageAnimation();
    _startMessageTimer();
  }

  /// 초기 타이머 실행 흐름
  Future<void> _initTimer() async {
    if (_isTimerInitialized) return;
    try {
      if (timerProvider.currentState == 'STOP') {
        await _startNewSession();
      } else {
        await _handleExistingSession();
      }
      _isTimerInitialized = true;
    } catch (_) {
      _isTimerInitialized = false;
    }
  }

  Future<void> _startNewSession() async {
    print('Starting new session');
    await timerProvider.startTimer(
      activityId: timerProvider.currentActivityId!,
      mode: timerProvider.currentSessionMode!,
      targetDuration: timerProvider.currentSessionTargetDuration!,
    );
  }

  Future<void> _handleExistingSession() async {
    print('Handling existing session');
    final sessionId = widget.timerData['session_id'];
    final currentSession = await _dbService.getSession(sessionId);

    if (currentSession != null) {
      final startTime = DateTime.parse(currentSession['start_time']);
      final currentDuration = DateTime.now().difference(startTime).inSeconds;
      final targetDuration = currentSession['target_duration'];

      print('Session details:');
      print('Start Time: $startTime');
      print('Current Duration: $currentDuration');
      print('Target Duration: $targetDuration');

      if (currentDuration >= targetDuration) {
        print('Session exceeded target duration');
        await _handleStop(isExceeded: true, targetDuration: targetDuration);
      } else {
        if (timerProvider.currentState == "RUNNING") {
          await timerProvider.restartTimer(sessionId: sessionId);
        }
      }
    }
  }

  void _handleTimerStateChange() {
    if (!mounted || _isNavigating) return;

    final isRunning = timerProvider.isRunning;
    final isExceeded = timerProvider.isExceeded;
    final currentState = timerProvider.currentState;

    print('===== Timer State Changed =====');
    print('Is Running: $isRunning');
    print('Is Exceeded: $isExceeded');

    // Handle exceeding case first
    if (isExceeded && !_hasShownCompletionDialog) {
      _isNavigating = true;
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TimerResultPage(
              timerData: timerProvider.timerData!,
              sessionDuration: timerProvider.currentSessionDuration,
              isExceeded: true,
            ),
          ),
        ).then((_) {
          _isNavigating = false;
        });
      }
      _hasShownCompletionDialog = true;
      return;
    }

    if (currentState == 'RUNNING') {
      setState(() {
        _isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
        if (waves.isEmpty) {
          _initAnimations();
        } else {
          _startWaveAnimation();
        }
        _isAnimationInitialized = true;
      });
    } else {
      _stopWaveAnimation();
    }

    // Handle normal stop case
    if (!isRunning && !isExceeded) {
      _isNavigating = true;
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TimerResultPage(
              timerData: timerProvider.timerData!,
              sessionDuration: timerProvider.currentSessionDuration,
              isExceeded: false,
            ),
          ),
        ).then((_) {
          _isNavigating = false;
        });
      }
    }
  }

  void _startWaveAnimation() {
    if (!mounted) return;

    for (var wave in waves) {
      if (wave.controller.isAnimating) continue;
      if (!wave.controller.isDismissed) continue;
      wave.controller.repeat();
    }
  }

  void _stopWaveAnimation() {
    if (!mounted) return;

    for (var wave in waves) {
      if (wave.controller.isAnimating) {
        wave.controller.stop();
      }
    }
  }

  void _startMessageTimer() {
    _messageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          currentMessageIndex = (currentMessageIndex + 1) % messages.length;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('===== didChangeDependencies =====');

    final isRunning = Provider.of<TimerProvider>(context, listen: false).isRunning;

    // Initialize animations only if timer is running and not already initialized
    if (isRunning && !_isAnimationInitialized) {
      print('Initializing animations - Timer is running');
      _isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
      _initAnimations();
      _isAnimationInitialized = true;

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _startWaveAnimation();
        }
      });
    } else if (!isRunning && _isAnimationInitialized) {
      print('Disposing animations - Timer is not running');
      _disposeAnimations();
      _isAnimationInitialized = false;
    }
  }

  void _disposeAnimations() {
    for (var wave in waves) {
      wave.controller.stop();
      wave.controller.dispose();
    }
    waves.clear();
  }

  String getWeekStart(DateTime date) {
    int weekday = date.weekday;
    // 월요일을 기준으로 주 시작일을 계산 (월요일이 1, 일요일이 7)
    DateTime weekStart = date.subtract(Duration(days: weekday - 1));
    return weekStart.toIso8601String().split('T').first;
  }

  Future<void> _handleStop({bool isExceeded = false, int? targetDuration}) async {
    final timer = timerProvider.timerData!;

    try {
      // 메시지 Timer 정리
      _messageTimer.cancel();

      // 세션 종료
      await timerProvider.stopTimer(isExceeded: isExceeded, sessionId: timer['session_id']);

      // 애니메이션 중지
      for (var wave in waves) {
        wave.controller.stop();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TimerResultPage(
              timerData: timer,
              sessionDuration: timerProvider.currentSessionDuration,
              isExceeded: isExceeded,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error handling stop: $e');
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
    // Clear existing waves if any
    _disposeAnimations();
    waves.clear();

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
      if (mounted && timerProvider.currentState == 'RUNNING') {
        Future.delayed(Duration(milliseconds: i * 666), () {
          if (mounted && timerProvider.currentState == 'RUNNING') {
            controller.repeat();
          }
        });
      }
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
    final isStateRunning = timerProvider.currentState == 'RUNNING';

    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isStateRunning && waves.isNotEmpty) // Check waves existence
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
                getIconData(activityIcon),
                color: activityColor,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                (activityName).length > 6 ? '${(activityName).substring(0, 6)}...' : (activityName),
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
    final Duration duration;

    if (timerProvider.currentSessionMode == "SESSIONPMDR") {
      // 뽀모도로 모드: 남은 시간 표시
      final remainingSeconds = timerProvider.currentSessionTargetDuration! - timerProvider.currentSessionDuration;
      duration = Duration(seconds: remainingSeconds.clamp(0, timerProvider.currentSessionTargetDuration!));
    } else {
      // 일반 모드: 경과 시간 표시
      duration = Duration(seconds: timerProvider.currentSessionDuration);
    }
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
    if (_isListenerAdded) {
      timerProvider.removeListener(_handleTimerStateChange);
      _isListenerAdded = false;
    }
    _messageTimer.cancel();
    _messageAnimationController.dispose();

    // Safely dispose animations
    _disposeAnimations();

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
          // Consumer를 제거하고 각 위젯별로 필요한 부분만 Consumer로 감싸기
          child: Column(
            children: [
              SizedBox(height: context.hp(3)),
              _buildHeader(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressCircleWithConsumer(),
                    const SizedBox(height: 80),
                    _buildTimeDisplayWithConsumer(),
                    const SizedBox(height: 10),
                    _buildActivityMessageWithConsumer(),
                  ],
                ),
              ),
              Text('state: ${widget.timerData['state']}'),
              Text('state: ${timerProvider.currentState}'),
              Text('session_duration: ${timerProvider.currentSessionDuration}'),
              _buildCountIndicator(3, 2),
              const SizedBox(height: 16),
              _buildPauseButton(), // 휴식 버튼
              _buildStopButton(),
            ],
          ),
        ),
      ),
    );
  }

  // 각 위젯을 Consumer로 감싸는 새로운 메서드들
  Widget _buildProgressCircleWithConsumer() {
    return Consumer<TimerProvider>(
      builder: (context, provider, child) {
        return _buildProgressCircle(provider);
      },
    );
  }

  Widget _buildTimeDisplayWithConsumer() {
    return Consumer<TimerProvider>(
      builder: (context, provider, child) {
        if (provider.isExceeded && !_hasShownCompletionDialog && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TimerResultPage(
                  timerData: provider.timerData!,
                  sessionDuration: provider.currentSessionDuration,
                  isExceeded: true,
                ),
              ),
            );
          });
          _hasShownCompletionDialog = true;
        }
        return _buildTimeDisplay(provider);
      },
    );
  }

  Widget _buildActivityMessageWithConsumer() {
    return Consumer<TimerProvider>(
      builder: (context, provider, child) {
        return _buildActivityMessage(provider);
      },
    );
  }

  Widget _buildHeader() {
    return Consumer<TimerProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: context.paddingSM,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.currentSessionMode == "SESSIONPMDR" ? "집중 모드" : "일반 모드",
                style: AppTextStyles.getHeadline(context),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.music_note_rounded,
                      size: context.xl,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Fluttertoast.showToast(
                        msg: "알림이 설정되었습니다",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.TOP,
                        backgroundColor: Colors.redAccent.shade200,
                        textColor: Colors.white,
                        fontSize: context.md,
                      );
                    },
                    icon: Icon(
                      Icons.notifications_active_rounded,
                      size: context.xl,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountIndicator(int maxCount, int currentCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        maxCount,
        (index) => Padding(
          padding: EdgeInsets.only(right: context.wp(1)),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index < currentCount ? Colors.red : Colors.red.withOpacity(0.3),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    return Padding(
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
    );
  }

  Widget _buildPauseButton() {
    final currentState = timerProvider.currentState;

    // 상태에 따른 버튼 텍스트
    final buttonText = currentState == 'RUNNING' ? '잠깐 휴식' : '다시 시작';

    // 상태에 따른 버튼 색상
    final backgroundColor = currentState == 'RUNNING' ? Colors.grey : Colors.blueAccent;

    // 상태에 따른 버튼 동작
    void onPressed() {
      if (currentState == 'RUNNING') {
        timerProvider.pauseTimer();
      } else if (currentState == 'PAUSED') {
        timerProvider.resumeTimer(sessionId: widget.timerData['session_id']);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            buttonText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
