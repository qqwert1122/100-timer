import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/models/achievement.dart';
import 'package:project1/screens/activity_log_page.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/screens/notice_page.dart';
import 'package:project1/screens/setting_page.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/widgets/activity_heat_map.dart';
import 'package:project1/widgets/menu.dart';
import 'package:project1/widgets/progress_circle.dart';
import 'package:project1/widgets/text_indicator.dart';
import 'package:project1/widgets/toggle_total_view_swtich.dart';
import 'package:project1/widgets/weekly_activity_chart.dart';
import 'package:project1/widgets/weekly_heatmap.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:project1/widgets/footer.dart';
import 'package:project1/data/sample_image_data.dart';
import 'package:project1/data/achievement_data.dart';

class TimerPage extends StatefulWidget {
  final Map<String, dynamic> timerData;

  const TimerPage({super.key, required this.timerData});

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  double _sheetSize = 0.13; // 초기 크기
  final DraggableScrollableController _controller = DraggableScrollableController();
  bool isTimeClicked = false;
  String userId = 'v3_4';
  String activityTimeText = '00:00:00'; // 초기 활동 시간 표시 값
  int _currentPageIndex = 1; // 현재 페이지 인덱스

  late AnimationController _slipAnimationController;
  late Animation<Offset> _slipAnimation;
  late AnimationController _waveAnimationController;
  late Animation<double> _waveAnimation;
  late Animation<double> _circularWaveAnimation;
  late AnimationController _breathingAnimationController;
  late Animation<double> _breathingAnimation;
  late AnimationController _timeAnimationController;
  late Animation<double> _totalTimeAnimation;
  late Animation<double> _activityTimeAnimation;
  final PageController _pageController = PageController(initialPage: 1);
  OverlayEntry? _overlayEntry;
  final GlobalKey _playButtonKey = GlobalKey();
  List<Wave> waves = [];

  final List<String> imgList = getSampleImages();
  final List<Achievement> achievements = getAchievements();

  double minSheetHeight = 0.13;
  double maxSheetHeight = 1.0;

  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    Future.delayed(Duration.zero, () {
      timerProvider.setTimerData(widget.timerData);
      timerProvider.initializeWeeklyActivityData();
      timerProvider.initializeHeatMapData(); // HeatMap 데이터 초기화
    });
    _initAnimations();
    WidgetsBinding.instance.addObserver(this);
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _isDarkMode = brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      timerProvider.onWaveAnimationRequested = _insertWaveAnimation;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _slipAnimationController.dispose();
    _waveAnimationController.dispose();
    _breathingAnimationController.dispose();
    _timeAnimationController.dispose();
    for (var wave in waves) {
      wave.controller.dispose();
    }
    _removeOverlay();
    WidgetsBinding.instance.removeObserver(this);
    TimerProvider timerProvider = Provider.of<TimerProvider>(context, listen: false);
    timerProvider.onWaveAnimationRequested = null;
    super.dispose();
  }

  void _initAnimations() {
    _slipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500), // 1초 동안 애니메이션 실행
      vsync: this,
    );

    // 슬라이드 애니메이션 설정 (위에서 아래로)
    _slipAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // 시작 위치 (위쪽)
      end: Offset.zero, // 종료 위치 (원래 자리)
    ).animate(CurvedAnimation(
      parent: _slipAnimationController,
      curve: Curves.easeInOut, // 애니메이션 곡선
    ));

    _slipAnimationController.forward();

    _waveAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true); // 애니메이션을 반복하여 파도처럼 보이게 함

    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _waveAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    for (int i = 0; i < 3; i++) {
      AnimationController controller = AnimationController(
        duration: Duration(seconds: 1 + i),
        vsync: this,
      )..repeat();

      _circularWaveAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );

      double minRadius = 40.0 + i * 20; // 웨이브마다 다른 시작 반지름 설정
      double maxRadius = 50.0 + i * 30;

      waves.add(Wave(
        color: _isDarkMode ? Colors.white.withOpacity(0.3 - i * 0.1) : Colors.redAccent.withOpacity(0.3 - i * 0.1),
        strokeWidth: 4.0 + i * 2,
        maxRadius: maxRadius,
        minRadius: minRadius,
        animation: _circularWaveAnimation,
        controller: controller, // 컨트롤러 할당
      ));
    }

    _breathingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // 애니메이션 반복

    // 1.0에서 1.2로 크기가 변하도록 설정 (조금 커졌다가 작아지는 효과)
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _breathingAnimationController,
        curve: Curves.easeInOut, // 부드러운 숨쉬기 효과
      ),
    );

    _timeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _totalTimeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _timeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _activityTimeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    if (_isDarkMode != isDarkMode) {
      setState(() {
        _isDarkMode = isDarkMode;
        _updateWaveColors();
      });
    }
  }

  void _updateWaveColors() {
    setState(() {
      for (int i = 0; i < waves.length; i++) {
        Color waveColor = _isDarkMode ? Colors.white.withOpacity(0.5 - i * 0.1) : Colors.redAccent.withOpacity(0.5 - i * 0.1);
        waves[i].color = waveColor; // 이제 오류 없이 동작합니다.
      }
    });
  }

  void _insertWaveAnimation() {
    final playButtonContext = _playButtonKey.currentContext;
    if (playButtonContext == null) {
      // 플레이 버튼이 아직 렌더링되지 않은 경우
      return;
    }
    RenderBox box = playButtonContext.findRenderObject() as RenderBox;
    Offset buttonPosition = box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
    _showOverlay(context, buttonPosition);

    for (var wave in waves) {
      wave.controller.repeat(); // 애니메이션 반복 시작
    }
  }

  void _showOverlay(BuildContext context, Offset position) {
    if (_overlayEntry != null) return; // 이미 표시된 경우

    _overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _controller, // DraggableScrollableController 사용
        builder: (context, child) {
          // 시트의 높이에 따라 opacity 계산
          double opacity = 1.0 - (_sheetSize - minSheetHeight) / (maxSheetHeight - minSheetHeight);
          opacity = opacity.clamp(0.0, 1.0);

          return Positioned(
            left: position.dx - 150,
            top: position.dy - 150,
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: MultiWavePainter(waves: waves),
                    child: SizedBox(
                      width: 300,
                      height: 300,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    for (var wave in waves) {
      wave.controller.stop(); // 애니메이션 중지
    }
  }

  void _toggleTimeView() {
    setState(() {
      isTimeClicked = !isTimeClicked;
    });

    if (isTimeClicked) {
      _timeAnimationController.forward(); // 애니메이션 실행
    } else {
      _timeAnimationController.reverse(); // 애니메이션 되돌리기
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index; // 페이지 인덱스 업데이트
    });
  }

  Widget _buildTimeDisplay(TimerProvider timerProvider, bool isDarkMode) {
    return GestureDetector(
      onTap: _toggleTimeView,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 총 활동 시간 텍스트 (애니메이션으로 사라짐)
          FadeTransition(
            opacity: _totalTimeAnimation,
            child: AnimatedOpacity(
              opacity: isTimeClicked ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                timerProvider.formattedTime,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.redAccent,
                  fontSize: 60,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'chab',
                ),
              ),
            ),
          ),

          // 활동 시간 텍스트 (애니메이션으로 나타남)
          FadeTransition(
            opacity: _activityTimeAnimation,
            child: AnimatedOpacity(
              opacity: isTimeClicked ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: isTimeClicked
                  ? Text(
                      timerProvider.formattedActivityTime,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.redAccent,
                          fontSize: 60,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'chab'),
                    )
                  : Container(), // 클릭하지 않았을 때는 비어있는 컨테이너로 유지
            ),
          ),
        ],
      ),
    );
  }

  // Activities
  void _showActivityModal(TimerProvider timerProvider) {
    if (timerProvider.isRunning) {
      // 타이머가 작동 중일 때는 토스트 메시지 띄우기
      Fluttertoast.showToast(
        msg: "타이머를 중지하고 활동을 변경해주세요",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.redAccent.shade200,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25.0),
          ),
        ),
        builder: (BuildContext context) {
          return ActivityPicker(
            onSelectActivity: (String selectedActivity, String selectedActivityIcon, String selectedActivityListId) {
              timerProvider.setCurrentActivity(selectedActivityListId, selectedActivity, selectedActivityIcon);
              Navigator.pop(context);
            },
            selectedActivity: timerProvider.currentActivityName ?? '전체',
            userId: userId,
          );
        },
      );
    }
  }

  // 전체 시간대 표시 여부
  bool showAllHours = true;

  void _toggleShowAllHours(bool value) {
    setState(() {
      showAllHours = value;
    });
  }

  bool refreshKey = false;
  void rerenderingHeatmap() {
    setState(() {
      refreshKey = !refreshKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);

    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      body: SlideTransition(
        position: _slipAnimation,
        child: Stack(
          children: [
            Positioned(
              top: 60,
              right: 10,
              child: AnimatedOpacity(
                opacity: timerProvider.isRunning ? 0.0 : 1.0,
                duration: Duration(milliseconds: 300),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (!timerProvider.isRunning) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NoticePage(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.notifications_outlined,
                        size: 28,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (!timerProvider.isRunning) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingPage(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.settings_outlined,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200, // 페이지뷰의 높이를 제한
                child: PageView(
                  controller: _pageController,
                  physics: timerProvider.isRunning ? NeverScrollableScrollPhysics() : AlwaysScrollableScrollPhysics(),
                  onPageChanged: _onPageChanged,
                  children: [
                    ProgressCircle(
                      totalSeconds: timerProvider.totalSeconds,
                      remainingSeconds: timerProvider.remainingSeconds,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(
                          height: 150,
                        ),
                        const Text(
                          '선택된 활동',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _showActivityModal(timerProvider), // 버튼을 클릭하면 모달 실행
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                getIconData(timerProvider.currentActivityIcon ?? 'category_rounded'),
                                color: Colors.redAccent.shade200,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                timerProvider.currentActivityName ?? '전체',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent.shade200,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: Colors.red),
                            ],
                          ),
                        ),
                        // timer
                        Container(
                          width: double.infinity,
                          height: 100,
                          alignment: Alignment.center,
                          child: timerProvider.isRunning
                              ? AnimatedBuilder(
                                  animation: _waveAnimationController,
                                  builder: (context, child) {
                                    // 색상이 파도치는 효과를 주기 위해 그라데이션 사용
                                    return ShaderMask(
                                        shaderCallback: (bounds) {
                                          return LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Colors.yellow,
                                              Colors.orange,
                                              isDarkMode ? Colors.redAccent.shade200 : Colors.redAccent.shade700
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            stops: [
                                              _waveAnimation.value,
                                              _waveAnimation.value + 0.2,
                                              _waveAnimation.value + 0.4,
                                              _waveAnimation.value + 0.6,
                                            ],
                                          ).createShader(bounds);
                                        },
                                        child: _buildTimeDisplay(timerProvider, isDarkMode));
                                  },
                                )
                              : Text(
                                  timerProvider.formattedTime,
                                  style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.redAccent.shade200,
                                      fontSize: 60,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'chab'),
                                ),
                        ),
                        const SizedBox(height: 20),
                        // play button
                        timerProvider.isRunning
                            ? AnimatedBuilder(
                                animation: _breathingAnimation,
                                builder: (context, child) {
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      Transform.scale(
                                        scale: _breathingAnimation.value, // 크기 애니메이션 적용
                                        child: Container(
                                          key: _playButtonKey,
                                          decoration: BoxDecoration(
                                              color: isDarkMode ? Colors.grey.shade800 : Colors.redAccent.shade400,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3), // 그림자 색상
                                                  spreadRadius: 2, // 그림자가 퍼지는 정도
                                                  blurRadius: 10, // 그림자 흐림 정도
                                                  offset: const Offset(0, 5), // 그림자 위치 (x, y)
                                                ),
                                              ]),
                                          child: IconButton(
                                            key: ValueKey<bool>(timerProvider.isRunning),
                                            icon: Icon(timerProvider.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                            iconSize: 80,
                                            color: Colors.white,
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              timerProvider.stopTimer();
                                              _removeOverlay();
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              )
                            : Container(
                                key: _playButtonKey,
                                decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey.shade800 : Colors.redAccent.shade400,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3), // 그림자 색상
                                        spreadRadius: 2, // 그림자가 퍼지는 정도
                                        blurRadius: 10, // 그림자 흐림 정도
                                        offset: const Offset(0, 5), // 그림자 위치 (x, y)
                                      ),
                                    ]),
                                child: IconButton(
                                  key: ValueKey<bool>(timerProvider.isRunning),
                                  icon: Icon(timerProvider.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                  iconSize: 80,
                                  color: Colors.white,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    timerProvider.startTimer(activityId: timerProvider.currentActivityId ?? '${userId}1');
                                    _insertWaveAnimation();
                                  },
                                ),
                              ),
                        const SizedBox(
                          height: 50,
                        ),
                        TextIndicator(
                          timerProvider: timerProvider,
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                    const Menu()
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: timerProvider.isRunning ? 0.0 : 1.0,
                duration: Duration(milliseconds: 300),
                child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(3, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPageIndex == index ? Colors.redAccent : Colors.grey, // 현재 페이지에 따라 색상 변경
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            // draggable sheet
            DraggableScrollableSheet(
              controller: _controller,
              initialChildSize: 0.13,
              minChildSize: 0.13,
              maxChildSize: 1,
              snap: true,
              snapAnimationDuration: const Duration(milliseconds: 200),
              builder: (BuildContext context, ScrollController scrollController) {
                return NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    setState(() {
                      _sheetSize = notification.extent; // 현재 크기 업데이트
                    });
                    return true;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _sheetSize >= 0.2
                          ? (isDarkMode ? const Color(0xff181C14) : Colors.white)
                          : (isDarkMode ? Colors.black : Colors.redAccent.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3), // 그림자 색상
                          spreadRadius: 4, // 그림자가 퍼지는 정도
                          blurRadius: 10, // 그림자 흐림 정도
                          offset: const Offset(0, -1), // 그림자 위치 (x, y)
                        ),
                      ],
                      borderRadius: _sheetSize >= 0.9
                          ? const BorderRadius.vertical(
                              top: Radius.circular(0),
                            )
                          : const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(top: 30),
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: _sheetSize >= 0.9 ? 30 : 0,
                          child: const SizedBox(height: 0),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 60, // 고정된 너비
                            height: 5,
                            decoration: BoxDecoration(
                              color: _sheetSize >= 0.2 ? (isDarkMode ? Colors.white : Colors.black) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: AnimatedDefaultTextStyle(
                                child: Text(
                                  '내 기록',
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: _sheetSize >= 0.2 ? 24 : 16,
                                  color: _sheetSize >= 0.2 ? (isDarkMode ? Colors.white : Colors.black) : Colors.white,
                                ),
                                duration: Duration(milliseconds: 200),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Icon(
                                Icons.history_rounded,
                                color: _sheetSize >= 0.2 ? (isDarkMode ? Colors.white : Colors.black) : Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '이번주 히트맵 🔥',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Row(
                                children: [
                                  ToggleTotalViewSwtich(value: showAllHours, onChanged: _toggleShowAllHours),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: () {
                                      timerProvider.initializeHeatMapData();
                                      rerenderingHeatmap();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        WeeklyHeatmap(key: ValueKey(refreshKey), userId: userId, showAllHours: showAllHours),
                        const SizedBox(height: 60),
                        // GridView의 스크롤 비활성화
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '이번주의 활동 시간 ⏱️',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  timerProvider.initializeWeeklyActivityData();
                                },
                              ),
                            ],
                          ),
                        ),
                        const WeeklyActivityChart(),

                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ActivityLogPage()),
                              );
                            },
                            style: ButtonStyle(
                              foregroundColor: WidgetStateProperty.all(Colors.white), // 텍스트 색상
                              backgroundColor: WidgetStateProperty.all(Colors.blueAccent.shade400), // 배경색
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0), // 둥근 모서리 반경
                                ),
                              ),
                            ),
                            child: const Text(
                              '더 보기',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 60,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '잔디심기 🌱',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SingleChildScrollView(
                          child: Column(
                            children: [
                              // ... 기존 코드 ...
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: ActivityHeatMap(),
                              ),
                              // ... 기존 코드 ...
                            ],
                          ),
                        ),
                        // const Padding(
                        //   padding: EdgeInsets.all(16),
                        //   child: Row(
                        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //     children: [
                        //       Text(
                        //         '나의 달성',
                        //         style: TextStyle(
                        //           fontSize: 16,
                        //           fontWeight: FontWeight.w900,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // CarouselSlider.builder(
                        //   itemCount: imgList.length,
                        //   itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
                        //     double angle = 0.0;

                        //     // 현재 인덱스에 따라 기울기 각도 설정
                        //     if (itemIndex == _currentIndex - 1) {
                        //       angle = -0.1; // 왼쪽으로 기울기
                        //     } else if (itemIndex == _currentIndex) {
                        //       angle = 0.0; // 똑바로
                        //     } else if (itemIndex == _currentIndex + 1) {
                        //       angle = 0.1; // 오른쪽으로 기울기
                        //     }

                        //     return Transform.rotate(
                        //       angle: angle,
                        //       child: Container(
                        //         margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        //         child: ClipRRect(
                        //           borderRadius: BorderRadius.circular(8.0),
                        //           child: AchievementCard(
                        //             achievement: achievements[itemIndex],
                        //           ),
                        //         ),
                        //       ),
                        //     );
                        //   },
                        //   options: CarouselOptions(
                        //     height: 300,
                        //     autoPlay: false,
                        //     enlargeCenterPage: true,
                        //     onPageChanged: (index, reason) {
                        //       setState(() {
                        //         _currentIndex = index; // 현재 인덱스 업데이트
                        //       });
                        //     },
                        //   ),
                        // ),
                        const SizedBox(
                          height: 30,
                        ),

                        const SizedBox(
                          height: 30,
                        ),
                        const Footer(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MultiWavePainter extends CustomPainter {
  final List<Wave> waves;

  MultiWavePainter({required this.waves}) : super(repaint: Listenable.merge(waves.map((w) => w.animation)));

  @override
  void paint(Canvas canvas, Size size) {
    for (var wave in waves) {
      final paint = Paint()
        ..color = wave.color.withOpacity(1 - wave.animation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = wave.strokeWidth;

      final radius = wave.minRadius + (wave.maxRadius - wave.minRadius) * wave.animation.value;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MultiWavePainter oldDelegate) {
    // 모든 파동의 애니메이션 값이 변경되면 다시 그리도록 설정
    for (int i = 0; i < waves.length; i++) {
      if (waves[i].animation.value != oldDelegate.waves[i].animation.value ||
          waves[i].color != oldDelegate.waves[i].color ||
          waves[i].strokeWidth != oldDelegate.waves[i].strokeWidth ||
          waves[i].maxRadius != oldDelegate.waves[i].maxRadius) {
        return true;
      }
    }
    return false;
  }
}

class Wave {
  Color color;
  final double strokeWidth;
  final double maxRadius;
  final double minRadius;
  final Animation<double> animation;
  final AnimationController controller; // AnimationController 추가

  Wave({
    required this.color,
    required this.strokeWidth,
    required this.maxRadius,
    required this.minRadius,
    required this.animation,
    required this.controller, // 컨트롤러 초기화
  });
}
