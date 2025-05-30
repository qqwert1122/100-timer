import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/screens/music_bottom_sheet.dart';
import 'package:project1/screens/timer_result_page.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/music_player.dart';
import 'package:project1/utils/notification_service.dart';
import 'package:project1/utils/prefs_service.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:shimmer/shimmer.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// 타이머 실행 화면 위젯
/// 사용자가 선택한 활동에 대한 타이머를 실행하고 시각적으로 표시함
class TimerRunningPage extends StatefulWidget {
  /// 타이머 페이지 초기화에 필요한 타이머 데이터
  final bool isNewSession;

  const TimerRunningPage({
    super.key,
    required this.isNewSession,
  });

  static final GlobalKey lightOnKey = GlobalKey(debugLabel: 'timerRunning');

  @override
  State<TimerRunningPage> createState() => _TimerRunningPageState();
}

class _TimerRunningPageState extends State<TimerRunningPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  // 서비스 객체 (의존성 주입)
  late final DatabaseService _dbService; // 데이터베이스 서비스
  late final TimerProvider timerProvider; // 타이머 상태 관리 Provider
  late final StatsProvider statsProvider; // 통계 관리 provider

  // 배경음악 플레이어 객체
  final musicPlayer = MusicPlayer();

  // 애니메이션 컨트롤러 및 애니메이션 객체
  late AnimationController _messageAnimationController;
  late Animation<Offset> _messageAnimation;
  late Animation<double> _messageOpacityAnimation;

  // 상태 플래그
  bool _isTimerInitialized = false; // 타이머 초기화 여부
  bool _isAnimationInitialized = false; // 애니메이션 초기화 여부
  bool _isListenerAdded = false; // 리스너 등록 여부
  bool _isNavigating = false; // 화면 전환 중 여부 (중복 방지용)
  bool _isDarkMode = false; // 다크 모드 여부
  bool _isPendingStateChange = false; // 즉시 버튼 상태 업데이트

  // 설정 관련 변수
  bool _isMusicOn = false; // 음악 설정
  bool _isAlarmOn = false; // 알림 설정
  bool _isLightOn = false; // wakelock 설정

  // 원형 프로그레스 및 파동 애니메이션션 관련
  List<Wave> waves = []; // 파동 애니메이션 객체 목록
  final GlobalKey _circleKey = GlobalKey(); // 원형 프로그레스 참조용 키

  // 메시지 관련 변수
  late Timer _messageTimer; //  메시지 전환 타이머
  int currentMessageIndex = 0; // 현재 표시 중인 메시지 인덱스
  final List<String> messages = []; // 표시할 메시지 목록
  bool _hasShownCompletionDialog = false; // 완료 다이얼로그 표시 여부

  // Onboarding flag
  bool _needShowOnboarding = false;

  // Onboarding GlobalKey
  final GlobalKey _timeKey = GlobalKey();
  final GlobalKey _musicKey = GlobalKey();
  final GlobalKey _alarmkey = GlobalKey();
  final _lightOnKey = TimerRunningPage.lightOnKey;

  @override
  void initState() {
    super.initState();
    logger.d('@@@ timer_running_page : init');
    // 서비스 객체 초기화
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    timerProvider = Provider.of<TimerProvider>(context, listen: false);
    statsProvider = Provider.of<StatsProvider>(context, listen: false);

    timerProvider.clearEventFlags();

    // 타이머 상태 변경 리스너 등록
    if (!_isListenerAdded) {
      logger.d('@@@ timer_running_page : _isListenerAdded: $_isListenerAdded');
      timerProvider.addListener(_handleTimerStateChange);
      _isListenerAdded = true;
    }

    timerProvider.ready.then((_) {
      if (mounted) setState(() {}); // 애니메이션·메시지 초기화 등
    });

    // 앱 라이프사이클 옵저버 등록 (백그라운드 처리용)
    WidgetsBinding.instance.addObserver(this);

    // 타이머, 애니메이션, 메시지, 알림 초기화
    // _initTimer();
    _initMessageAnimation();
    _startMessageTimer();
    _isAlarmOn = PrefsService().alarmFlag;
    _isLightOn = PrefsService().keepScreenOn;

    _needShowOnboarding = !PrefsService().getOnboarding('timerRunning');
    if (_needShowOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          ShowCaseWidget.of(context).startShowCase([
            _timeKey,
            _musicKey,
            _alarmkey,
            _lightOnKey,
          ]);
        },
      );
    }
  }

  @override
  void dispose() {
    if (_isListenerAdded) {
      timerProvider.removeListener(_handleTimerStateChange);
      _isListenerAdded = false;
    }
    WidgetsBinding.instance.removeObserver(this);

    _messageTimer.cancel();
    _messageAnimationController.dispose();
    _disposeAnimations();

    super.dispose();
  }

  void _handleTimerStateChange() {
    logger.d('@@@ timer_running_page @@@ : _handleTimerStateChange()');
    if (!mounted || _isNavigating) return;

    final isRunning = timerProvider.isRunning;
    final isSessionTargetExceeded = timerProvider.justFinishedByExceeding;
    final currentState = timerProvider.currentState;

    // 애니메이션 상태 업데이트
    _updateAnimationState(currentState);

    // 타이머 초과 케이스 처리
    if (isSessionTargetExceeded && !_hasShownCompletionDialog) {
      logger.d('@@@ timer_running_page @@@ : _handleTimerStateChange() >> isSessionTargetExceeded');
      logger.d(
          'timerProvider.justFinishedByExceeding : ${timerProvider.justFinishedByExceeding}, _hasShownCompletionDialog : $_hasShownCompletionDialog');
      timerProvider.clearEventFlags();
      _navigateToResultPage(isSessionTargetExceeded: true);
      return;
    }

    // 타이머 중지 케이스 처리
    if (!isRunning && !isSessionTargetExceeded && currentState == 'STOP') {
      logger.d('@@@ timer_running_page @@@ : _handleTimerStateChange() >> isSessionTarget Not Exceeded');
      _navigateToResultPage(isSessionTargetExceeded: false);
    }
  }

  // 애니메이션 상태 관리를 위한 helper 메소드
  void _updateAnimationState(String state) {
    if (state == 'RUNNING') {
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
  }

  // 결과 페이지로 이동하는 helper 메소드
  void _navigateToResultPage({required bool isSessionTargetExceeded}) {
    logger.d('@@@ timer_running_page : _navigateToResultPage($isSessionTargetExceeded)');
    if (_isNavigating) return;
    _isNavigating = true;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TimerResultPage(
            timerData: timerProvider.timerData!,
            sessionDuration: isSessionTargetExceeded ? timerProvider.currentSessionTargetDuration! : timerProvider.currentSessionDuration,
            isSessionTargetExceeded: isSessionTargetExceeded,
          ),
        ),
      ).then((_) {
        _isNavigating = false;
      });
    }

    if (isSessionTargetExceeded) {
      _hasShownCompletionDialog = true;
    }
  }

  void _startWaveAnimation() {
    if (!mounted) return;

    for (var wave in waves) {
      if (!wave.controller.isAnimating) {
        // 애니메이션 상태를 초기화한 후 반복 실행
        wave.controller.reset();
        wave.controller.repeat();
      }
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
    // isRunning 값에 따라 애니메이션 컨트롤
    super.didChangeDependencies();
    print('timer_running_page : didChangeDependencies');

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

  Future<void> _handleStop({bool isSessionTargetExceeded = false, int? targetDuration}) async {
    logger.d('@@@ timer_running_page @@@ : handleStop({$isSessionTargetExceeded, $targetDuration})');

    final timer = timerProvider.timerData!;
    try {
      // 메시지 Timer 정리
      _messageTimer.cancel();

      // 음악 종료
      musicPlayer.stopMusic();

      // 푸쉬알림 종료
      await NotificationService().cancelCompletionNotification();

      // 세션 종료
      await timerProvider.stopTimer(isSessionTargetExceeded: isSessionTargetExceeded, sessionId: timer['current_session_id']);

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
              sessionDuration: isSessionTargetExceeded ? targetDuration! : timerProvider.currentSessionDuration,
              isSessionTargetExceeded: isSessionTargetExceeded,
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
        color: _isDarkMode ? Colors.white.withValues(alpha: 0.25 - i * 0.1) : Colors.redAccent.withValues(alpha: 0.25 - i * 0.1),
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

  void _showMusicBottomSheet() {
    showMusicBottomSheet(
      context: context,
      currentMusic: musicPlayer.currentMusic,
      onMusicSelected: (music) {
        musicPlayer.playMusic(music);
        setState(() {
          _isMusicOn = true;
        }); // UI 업데이트
      },
      onStopMusic: () {
        musicPlayer.stopMusic();
        setState(() {
          _isMusicOn = false;
        }); // UI 업데이트
      },
    );
  }

  void _toggleAlarm() async {
    final bool turnOn = !_isAlarmOn;

    if (turnOn) {
      final granted = await NotificationService().requestPermissions();
      if (!granted) {
        setState(() => _isAlarmOn = false);
        Fluttertoast.showToast(
          msg: "알림 권한이 필요합니다",
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.grey.shade700,
          textColor: Colors.white,
          fontSize: context.md,
        );
        return;
      }
    }

    // 권한 확인 완료 또는 알림 끄기
    setState(() => _isAlarmOn = turnOn);
    PrefsService().alarmFlag = turnOn;
    if (timerProvider.currentState == 'RUNNING' &&
        timerProvider.currentSessionMode == 'PMDR' &&
        timerProvider.currentSessionTargetDuration != null) {
      if (turnOn) {
        // ✔ 알림 켜짐 → 잔여 시간으로 재예약
        final remaining = timerProvider.currentSessionTargetDuration! - timerProvider.currentSessionDuration;
        if (remaining > 0) {
          await NotificationService().scheduleActivityCompletionNotification(
            scheduledTime: DateTime.now().add(Duration(seconds: remaining)),
            title: '100 timer',
            body: '${timerProvider.currentActivityName} 활동을 '
                '${timerProvider.formatDuration(timerProvider.currentSessionTargetDuration!)} 집중했어요!',
          );
        }
      } else {
        // ✘ 알림 꺼짐 → 현재 예약된 알림 취소
        await NotificationService().cancelCompletionNotification();
      }
    }
    Fluttertoast.showToast(
      msg: _isAlarmOn ? "알림이 설정되었습니다" : "알림이 해제되었습니다",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.redAccent.shade200,
      textColor: Colors.white,
      fontSize: context.md,
    );
    HapticFeedback.lightImpact();
  }

  void _toggleLightOn() async {
    final bool turnOn = !_isLightOn;

    setState(() => _isLightOn = turnOn);
    PrefsService().keepScreenOn = turnOn;
    WakelockPlus.toggle(enable: turnOn);

    Fluttertoast.showToast(
      msg: _isLightOn ? "화면이 항상 켜집니다" : "시간이 지나면 화면이 꺼집니다",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.redAccent.shade200,
      textColor: Colors.white,
      fontSize: context.md,
    );
    HapticFeedback.lightImpact();
  }

  Widget _buildActivityMessage(TimerProvider timerProvider) {
    // 현재 활동 이름
    final currentActivityName = timerProvider.currentActivityName;

    // FutureBuilder를 사용하여 비동기 데이터를 로드
    return FutureBuilder<int>(
      // 활동 ID가 null이 아닌 경우에만 통계 데이터를 가져옴
      future: timerProvider.currentActivityId != null
          ? statsProvider.getWeeklyDurationByActivity(timerProvider.currentActivityId!)
          : Future.value(0),
      builder: (context, snapshot) {
        // 데이터 로딩 중이거나 오류가 발생한 경우 로딩 표시
        if (!snapshot.hasData) {
          messages
            ..clear()
            ..add(widget.isNewSession ? "새로운 활동을 시작했어요" : "이어서 활동해요")
            ..add("이번주 통계를 불러오는 중...");
        } else {
          // 데이터가 로드된 경우 메시지 업데이트
          final seconds = snapshot.data ?? 0;
          // 초를 분으로 변환
          final minutes = seconds ~/ 60;
          messages
            ..clear()
            ..add(widget.isNewSession ? "새로운 활동을 시작했어요" : "이어서 활동해요")
            ..add(
                "이번주에 ${(currentActivityName ?? '전체').length > 6 ? '${(currentActivityName ?? '전체').substring(0, 6)}...' : currentActivityName ?? '전체'} 활동을 ${_formatDurationMessage(minutes)} 했어요");
        }

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
              style: AppTextStyles.getBody(context).copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressCircle(TimerProvider timerProvider) {
    double progress = 0.0;

    if (timerProvider.currentSessionMode == 'PMDR' || !timerProvider.isWeeklyTargetExceeded) {
      progress = 1 - (timerProvider.currentSessionDuration / timerProvider.currentSessionTargetDuration!);
    } else {
      // 주간 목표시간 초과달성 시 (1시간 기준 진행률 표시)
      progress = 1 - (timerProvider.currentSessionDuration / 3600);
    }

    final activityColor = ColorService.hexToColor(timerProvider.currentActivityColor);
    final activityName = timerProvider.currentActivityName;
    final activityIcon = timerProvider.currentActivityIcon;
    final isStateRunning = timerProvider.currentState == 'RUNNING';

    return SizedBox(
      width: context.wp(50),
      height: context.hp(20),
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
                size: Size(context.wp(50), context.hp(20)),
              ),
            ),
          Transform.scale(
            scale: 5,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              builder: (context, animatedProgress, child) {
                return CircularProgressIndicator(
                  key: _circleKey,
                  value: animatedProgress,
                  backgroundColor: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(activityColor),
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                );
              },
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                getIconImage(activityIcon),
                width: context.xxxl,
                height: context.xxxl,
                errorBuilder: (context, error, stackTrace) {
                  // 이미지를 로드하는 데 실패한 경우의 대체 표시
                  return Container(
                    width: 24,
                    height: 24,
                    color: Colors.grey.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.broken_image,
                      size: 16,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
              SizedBox(width: context.hp(1)),
              Text(
                (activityName).length > 6 ? '${(activityName).substring(0, 6)}...' : (activityName),
                style: AppTextStyles.getBody(context).copyWith(
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

    if (timerProvider.currentSessionMode == "PMDR") {
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
      style: AppTextStyles.getTimeDisplay(context).copyWith(
        color: ColorService.hexToColor(timerProvider.currentActivityColor),
        fontFamily: 'chab',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        body: SafeArea(
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
                    Showcase(
                        key: _timeKey,
                        description: '활동 중인 시간이나 잔여 시간 표시',
                        targetBorderRadius: BorderRadius.circular(16),
                        targetPadding: context.paddingXS,
                        overlayOpacity: 0.5,
                        child: _buildTimeDisplayWithConsumer()),
                    const SizedBox(height: 10),
                    _buildActivityMessageWithConsumer(),
                  ],
                ),
              ),
              _buildPauseButton(),
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
                provider.currentSessionMode == "PMDR" ? "집중 모드" : "일반 모드",
                style: AppTextStyles.getHeadline(context),
              ),
              Row(
                children: [
                  Showcase(
                    key: _musicKey,
                    description: '배경음악을 틀어보세요',
                    targetBorderRadius: BorderRadius.circular(16),
                    overlayOpacity: 0.5,
                    child: Shimmer.fromColors(
                      baseColor: _isMusicOn ? Colors.redAccent : AppColors.textPrimary(context),
                      highlightColor: _isMusicOn ? Colors.yellowAccent : AppColors.textPrimary(context),
                      child: IconButton(
                        onPressed: () {
                          _showMusicBottomSheet();
                          HapticFeedback.lightImpact();
                        },
                        icon: Image.asset(
                          getIconImage('music'),
                          width: context.xl,
                          height: context.xl,
                          errorBuilder: (context, error, stackTrace) {
                            // 이미지를 로드하는 데 실패한 경우의 대체 표시
                            return Container(
                              width: context.xl,
                              height: context.xl,
                              color: Colors.grey.withValues(alpha: 0.2),
                              child: Icon(
                                Icons.broken_image,
                                size: context.xl,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.wp(2)),
                  Showcase(
                    key: _alarmkey,
                    description: '집중모드가 끝난 뒤 푸시알림 켜고 끄세요',
                    targetBorderRadius: BorderRadius.circular(16),
                    overlayOpacity: 0.5,
                    child: IconButton(
                      onPressed: () {
                        _toggleAlarm();
                      },
                      icon: Image.asset(
                        getIconImage(_isAlarmOn ? 'bell' : 'bell_muted'),
                        width: context.xl,
                        height: context.xl,
                        errorBuilder: (context, error, stackTrace) {
                          // 이미지를 로드하는 데 실패한 경우의 대체 표시
                          return Container(
                            width: context.xl,
                            height: context.xl,
                            color: Colors.grey.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.broken_image,
                              size: context.xl,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: context.wp(2)),
                  Showcase(
                    key: _lightOnKey,
                    description: '화면을 항상 켜보세요',
                    targetBorderRadius: BorderRadius.circular(16),
                    overlayOpacity: 0.5,
                    child: IconButton(
                      onPressed: () {
                        _toggleLightOn();
                      },
                      icon: Image.asset(
                        getIconImage('bulb'),
                        width: context.xl,
                        height: context.xl,
                        color: _isLightOn ? null : AppColors.textPrimary(context),
                        errorBuilder: (context, error, stackTrace) {
                          // 이미지를 로드하는 데 실패한 경우의 대체 표시
                          return Container(
                            width: context.xl,
                            height: context.xl,
                            color: Colors.grey.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.broken_image,
                              size: context.xl,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
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
                  backgroundColor: AppColors.background(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  title: Text(
                    "활동 종료",
                    style: AppTextStyles.getTitle(context),
                  ),
                  content: Text(
                    "활동을 마무리 하시겠어요?",
                    style: AppTextStyles.getBody(context),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // 아니오: 모달창 닫기
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        "아니오",
                        style: AppTextStyles.getBody(context).copyWith(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _handleStop();
                      },
                      child:
                          Text("네", style: AppTextStyles.getBody(context).copyWith(fontWeight: FontWeight.w900, color: Colors.redAccent)),
                    ),
                  ],
                );
              },
            );
          },
          child: Text(
            "활동 종료",
            style: AppTextStyles.getBody(context).copyWith(
              fontWeight: FontWeight.w900,
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
    final backgroundColor = currentState == 'RUNNING' ? AppColors.backgroundTertiary(context) : Colors.blueAccent;

    final fontColor = currentState == 'RUNNING' ? Colors.grey : Colors.white;

    // 상태에 따른 버튼 동작
    void onPressed() {
      HapticFeedback.lightImpact();
      final bool isCurrentlyRunning = currentState == 'RUNNING';

      // 1. 즉시 UI 상태 변경 (버튼 색상 및 텍스트)
      setState(() {
        // 즉시 버튼 상태 업데이트
        _isPendingStateChange = true;
      });

      // 2. 백그라운드에서 상태 변경 작업 처리
      if (isCurrentlyRunning) {
        // 일시 정지 로직
        timerProvider.pauseTimer(updateUIImmediately: true).then((_) {
          if (mounted) {
            setState(() {
              _isPendingStateChange = false;
            });
          }
        });
      } else {
        // 재개 로직
        final sessionId = timerProvider.timerData?['current_session_id'];
        if (sessionId != null) {
          timerProvider.resumeTimer(sessionId: sessionId, updateUIImmediately: true).then((_) {
            if (mounted) {
              setState(() {
                _isPendingStateChange = false;
              });
            }
          });
        }
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
            style: AppTextStyles.getBody(context).copyWith(
              fontWeight: FontWeight.w900,
              color: fontColor,
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
        ..color = baseColor.withValues(alpha: wave.opacityAnimation.value)
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
    super.key,
    required this.number,
    this.style,
  });

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
    super.key,
    required this.hours,
    required this.minutes,
    required this.seconds,
    this.style,
  });

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
        baseColor.withValues(alpha: opacity * 0.3),
        baseColor.withValues(alpha: opacity * 0.1),
        baseColor.withValues(alpha: 0),
      ],
    );

    // Secondary gradient layers for artistic effect
    final secondaryGradient = RadialGradient(
      center: const Alignment(0.3, -0.3),
      radius: 1.2,
      colors: [
        baseColor.withValues(alpha: opacity * 0.2),
        baseColor.withValues(alpha: 0),
      ],
    );

    final tertiaryGradient = RadialGradient(
      center: const Alignment(-0.3, 0.3),
      radius: 1.2,
      colors: [
        baseColor.withValues(alpha: opacity * 0.15),
        baseColor.withValues(alpha: 0),
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
