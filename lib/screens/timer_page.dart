import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/models/achievement.dart';
import 'package:project1/screens/activity_log_page.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/screens/notice_page.dart';
import 'package:project1/screens/setting_page.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/widgets/activity_heat_map.dart';
import 'package:project1/widgets/menu.dart';
import 'package:project1/widgets/progress_circle.dart';
import 'package:project1/widgets/text_indicator.dart';
import 'package:project1/widgets/toggle_total_view_swtich.dart';
import 'package:project1/widgets/weekly_activity_chart.dart';
import 'package:project1/widgets/weekly_heatmap.dart';
import 'package:project1/widgets/weekly_session_status.dart';
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
  TimerProvider? _timerProvider; // TimerProvider 변수 추가

  double _sheetSize = 0.13; // 초기 크기
  final DraggableScrollableController _controller = DraggableScrollableController();
  int _currentPageIndex = 1; // 현재 페이지 인덱스

  late AnimationController _slipAnimationController;
  late Animation<Offset> _slipAnimation;
  late AnimationController _shimmerAnimationcontroller;
  late Animation<Alignment> _shimmerAnimation;
  ScrollController? _sheetScrollController;

  final PageController _pageController = PageController(initialPage: 1);
  final GlobalKey _playButtonKey = GlobalKey();

  final List<String> imgList = getSampleImages();
  final List<Achievement> achievements = getAchievements();

  double minSheetHeight = 0.13;
  double maxSheetHeight = 1.0;

  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _timerProvider = Provider.of<TimerProvider>(context, listen: false); // TimerProvider 저장

    Future.delayed(Duration.zero, () async {
      final timerProvider = _timerProvider!;

      if (timerProvider.isRunning) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const TimerRunningPage(),
            ),
          );
        }
      }

      timerProvider.initializeWeeklyActivityData();
      timerProvider.initializeHeatMapData();
    });

    _initAnimations();
    WidgetsBinding.instance.addObserver(this);
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _isDarkMode = brightness == Brightness.dark;
  }

  @override
  void dispose() {
    _controller.dispose();
    _slipAnimationController.dispose();
    _shimmerAnimationcontroller.dispose();
    _backPressTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

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

    _shimmerAnimationcontroller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // 애니메이션 주기
    )..repeat();

    _shimmerAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(-1.0, -1.0),
          end: const Alignment(1.0, -1.0),
        ).chain(CurveTween(curve: Curves.easeInOut)), // 곡선 변경
        weight: 45,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(1.0, -1.0),
          end: const Alignment(1.0, 1.0),
        ).chain(CurveTween(curve: Curves.linear)), // 곡선 변경
        weight: 5,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(1.0, 1.0),
          end: const Alignment(-1.0, 1.0),
        ).chain(CurveTween(curve: Curves.easeOut)), // 곡선 변경
        weight: 45,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(-1.0, 1.0),
          end: const Alignment(-1.0, -1.0),
        ).chain(CurveTween(curve: Curves.slowMiddle)), // 곡선 변경
        weight: 5,
      ),
    ]).animate(_shimmerAnimationcontroller);
  }

  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    if (_isDarkMode != isDarkMode) {
      setState(() {
        _isDarkMode = isDarkMode;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index; // 페이지 인덱스 업데이트
    });
  }

  Widget _buildTimeDisplay(TimerProvider timerProvider, bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: Text(
        timerProvider.formattedTime,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.redAccent.shade200,
          fontSize: 60,
          fontWeight: FontWeight.w500,
          fontFamily: 'chab',
        ),
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
            onSelectActivity:
                (String selectedActivityListId, String selectedActivity, String selectedActivityIcon, String selectedActivityColor) {
              timerProvider.setCurrentActivity(selectedActivityListId, selectedActivity, selectedActivityIcon, selectedActivityColor);
              Navigator.pop(context);
            },
            selectedActivity: timerProvider.currentActivityName ?? '전체',
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

  bool _canPop = false;
  DateTime? _lastBackPressed;
  Timer? _backPressTimer;

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final List<String> avatarUrls = [
      '양조현',
      '조서은',
      'Alice',
      'Bob',
      'Diana',
      'Ian',
      '모아',
      '보니',
      '리치',
    ];

    int totalCount = avatarUrls.length;
    int displayCount = totalCount > 4 ? 4 : totalCount;
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        double epsilon = 0.01; // 부동소수점 비교를 위한 작은 값

        if (_sheetScrollController != null) {
          _sheetScrollController!.jumpTo(0.0);
        }

        if ((_sheetSize - maxSheetHeight).abs() < epsilon) {
          _controller.jumpTo(0);
          _controller.animateTo(
            minSheetHeight,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
          _sheetSize = minSheetHeight;
          setState(() {
            _canPop = false; // 앱 종료 방지
          });
        } else if ((_sheetSize - minSheetHeight).abs() < epsilon) {
          // DraggableScrollableSheet가 최소 크기일 때
          DateTime now = DateTime.now();
          if (_lastBackPressed == null || now.difference(_lastBackPressed!) > Duration(seconds: 2)) {
            // 2초 이내에 뒤로 가기 버튼을 두 번 누르지 않으면 토스트 메시지 표시
            _lastBackPressed = now;
            Fluttertoast.showToast(
              msg: "한 번 더 뒤로가기를 누르면 종료됩니다.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              backgroundColor: isDarkMode ? Colors.white : Colors.black54,
              textColor: isDarkMode ? Colors.black54 : Colors.white,
              fontSize: 14.0,
            );
            setState(() {
              _canPop = true; // 앱 종료 허용
            });
            _backPressTimer?.cancel(); // 기존 Timer 취소
            _backPressTimer = Timer(Duration(seconds: 2), () {
              setState(() {
                _canPop = false; // 앱 종료 방지
              });
            });
          } else {
            // 2초 이내에 뒤로 가기 버튼을 두 번 눌렀으면 앱 종료
            _backPressTimer?.cancel(); // Timer 취소
          }
        } else {
          // 그 외의 경우 DraggableScrollableSheet를 최소 크기로 축소
          _controller.jumpTo(0);
          _controller.animateTo(
            minSheetHeight,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
          setState(() {
            _sheetSize = minSheetHeight;
            _canPop = false; // 앱 종료 방지
          });
        }
      },
      child: Scaffold(
        body: SlideTransition(
          position: _slipAnimation,
          child: Stack(
            children: [
              Positioned(
                top: 60,
                left: 10,
                child: SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 60,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: const [
                                  Colors.orange,
                                  Colors.pinkAccent,
                                  Colors.red,
                                  Colors.purple,
                                ],

                                begin: _shimmerAnimation.value, // 애니메이션 시작점
                                end: Alignment(-_shimmerAnimation.value.x, -_shimmerAnimation.value.y), // 애니메이션 끝점
                                tileMode: TileMode.mirror, // 경계에서 반복
                              ),
                              borderRadius: BorderRadius.circular(16.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pinkAccent.withOpacity(0.5),
                                  blurRadius: 8, // 그림자 흐림 정도
                                  offset: const Offset(0, 4), // 그림자 위치
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'PRO +',
                                style: TextStyle(
                                  color: Colors.white, // 글자 색상
                                  fontWeight: FontWeight.w900, // 글자 굵기
                                  fontSize: 12, // 글자 크기
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 60,
                right: 10,
                child: SizedBox(
                  height: 40,
                  child: AnimatedOpacity(
                    opacity: timerProvider.isRunning ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                                  Material(
                                    color: Colors.transparent,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          getIconData(timerProvider.currentActivityIcon ?? 'category_rounded'),
                                          color: Colors.redAccent.shade200,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          timerProvider.currentActivityName ?? '전체',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.redAccent.shade200,
                                          ),
                                        ),
                                      ],
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
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  timerProvider.formattedTime,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.redAccent.shade200,
                                    fontSize: 60,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'chab',
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                            // play button
                            Container(
                              key: _playButtonKey,
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey.shade800 : Colors.redAccent.shade400,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    key: ValueKey<bool>(timerProvider.isRunning),
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    iconSize: 80,
                                    color: Colors.white,
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      if (timerProvider.currentActivityId != null) {
                                        timerProvider.setSessionModeAndTargetDuration(
                                            mode: 'SESINORM', targetDuration: timerProvider.remainingSeconds);
                                        Navigator.of(context).push(
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => const TimerRunningPage(),
                                            transitionDuration: const Duration(milliseconds: 500),
                                            reverseTransitionDuration: const Duration(milliseconds: 500),
                                          ),
                                        );
                                      } else {
                                        Fluttertoast.showToast(
                                          msg: "활동을 선택해주세요",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.TOP,
                                          backgroundColor: Colors.redAccent.shade200,
                                          textColor: Colors.white,
                                          fontSize: 14.0,
                                        );
                                        _showActivityModal(timerProvider);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 50,
                            ),
                            TextIndicator(
                              timerProvider: timerProvider,
                            ),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: SizedBox(
                                width: 60 + (displayCount - 1) * 30,
                                height: 35,
                                child: Stack(
                                  children: List.generate(displayCount, (index) {
                                    if (index < 3 || totalCount <= 4) {
                                      return Positioned(
                                        left: index * 20.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2), // 그림자 색상
                                                blurRadius: 6, // 그림자의 흐림 정도
                                                offset: Offset(0, 2), // 그림자 위치 (x, y)
                                              ),
                                            ],
                                          ),
                                          child: SvgPicture.network(
                                            'https://api.dicebear.com/9.x/thumbs/svg?seed=${avatarUrls[index]}&radius=50',
                                            width: 30,
                                            height: 30,
                                          ),
                                        ),
                                      );
                                    } else {
                                      return Positioned(
                                        left: index * 20.0,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.3),
                                                    blurRadius: 6,
                                                    offset: Offset(2, 2),
                                                  ),
                                                ],
                                                borderRadius: BorderRadius.circular(50),
                                                color: Colors.grey[300],
                                              ),
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '+${totalCount - 3}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            const Text(
                                              '활동중',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                  duration: const Duration(milliseconds: 300),
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
                  _sheetScrollController = scrollController;

                  return NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      setState(() {
                        _sheetSize = notification.extent; // 현재 크기 업데이트

                        double epsilon = 0.01;
                        if ((_sheetSize - maxSheetHeight).abs() < epsilon) {
                          // 시트가 최대 크기일 때
                          _canPop = false; // 앱 종료 방지
                        }
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: _sheetSize >= 0.2 ? 24 : 16,
                                    color: _sheetSize >= 0.2 ? (isDarkMode ? Colors.white : Colors.black) : Colors.white,
                                  ),
                                  duration: const Duration(milliseconds: 200),
                                  child: const Text(
                                    '내 기록',
                                  ),
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
                          const WeeklySessionStatus(),
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
                                '전체 활동기록 보기',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
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
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '이번주 시간대별 활동을 색깔로 확인해요',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            child: WeeklyHeatmap(
                              key: ValueKey(refreshKey),
                              showAllHours: showAllHours,
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
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
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '이번주 활동 시간을 막대그래프로 한눈에 확인해요',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const WeeklyActivityChart(),
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
                          const SizedBox(height: 10),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '활동을 하면 달력에 잔디가 심어져요',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 30),
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
      ),
    );
  }
}
