import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/models/achievement.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/screens/notice_page.dart';
import 'package:project1/screens/session_history_sheet.dart';
import 'package:project1/screens/setting_page.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/widgets/focus_mode.dart';
import 'package:project1/widgets/dashboard.dart';
import 'package:project1/widgets/text_indicator.dart';
import 'package:project1/widgets/todo.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:project1/data/sample_image_data.dart';
import 'package:project1/data/achievement_data.dart';
import 'package:project1/utils/responsive_size.dart';

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
  final ScrollController _sheetScrollController = ScrollController();

  int _currentPageIndex = 1; // 현재 페이지 인덱스
  int? selectedIndex = 0;

  late AnimationController _slipAnimationController;
  late Animation<Offset> _slipAnimation;
  late AnimationController _shimmerAnimationcontroller;
  late Animation<Alignment> _shimmerAnimation;

  final PageController _pageController = PageController(initialPage: 1);
  final GlobalKey _playButtonKey = GlobalKey();

  final List<String> imgList = getSampleImages();
  final List<Achievement> achievements = getAchievements();

  bool _isBackButtonPressed = false;

  double minSheetHeight = 0.13;
  double maxSheetHeight = 1.0;
  double _circleWidth = 40;
  double _circleHeight = 40;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _timerProvider = Provider.of<TimerProvider>(context, listen: false); // TimerProvider 저장

    Future.delayed(Duration.zero, () async {
      _timerProvider!.initializeWeeklyActivityData();
      _timerProvider!.initializeHeatMapData();
      _timerProvider!.refreshRemainingSeconds();
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
        ).chain(CurveTween(curve: Curves.linear)), // 곡선 변경
        weight: 25,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(1.0, -1.0),
          end: const Alignment(1.0, 1.0),
        ).chain(CurveTween(curve: Curves.linear)), // 곡선 변경
        weight: 25,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(1.0, 1.0),
          end: const Alignment(-1.0, 1.0),
        ).chain(CurveTween(curve: Curves.linear)), // 곡선 변경
        weight: 25,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(-1.0, 1.0),
          end: const Alignment(-1.0, -1.0),
        ).chain(CurveTween(curve: Curves.linear)), // 곡선 변경
        weight: 25,
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

  void _animateCircle(int index) {
    setState(() {
      // 애니메이션 상태 변경
      _circleWidth = 60;
      _circleHeight = 10;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      setState(() {
        _circleWidth = 40;
        _circleHeight = 40;
        _currentPageIndex = index;
      });
    });
  }

  void _onPageChanged(int index) {
    _animateCircle(index);
  }

  void _onIconTap(int index) {
    if (_currentPageIndex == index) return; // 같은 인덱스를 클릭하면 무시

    // 페이지 이동
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _animateCircle(index);
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
        fontSize: context.md,
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
            selectedActivity: timerProvider.currentActivityName,
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

    final double containerWidth = context.wp(60); // 네비게이션 바 가로 길이
    final double itemWidth = containerWidth / 4; // 버튼 하나의 너비

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        setState(() {
          _isBackButtonPressed = true;
        });

        Future.microtask(() {
          setState(() {
            _isBackButtonPressed = false;
          });
        });

        // sheet가 최소 크기일 때만 앱 종료 로직 처리
        if ((_sheetSize - minSheetHeight).abs() < 0.01) {
          DateTime now = DateTime.now();
          if (_lastBackPressed == null || now.difference(_lastBackPressed!) > Duration(seconds: 2)) {
            _lastBackPressed = now;
            Fluttertoast.showToast(
              msg: "한 번 더 뒤로가기를 누르면 종료됩니다.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              backgroundColor: AppColors.backgroundSecondary(context),
              textColor: AppColors.textSecondary(context),
              fontSize: context.md,
            );
            setState(() {
              _canPop = true;
            });
            _backPressTimer?.cancel();
            _backPressTimer = Timer(const Duration(seconds: 2), () {
              setState(() {
                _canPop = false;
              });
            });
          } else {
            _backPressTimer?.cancel();
          }
        } else {
          // sheet가 최소 크기가 아닐 때는 sheet를 최소화
          _controller.animateTo(
            minSheetHeight,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
          setState(() {
            _sheetSize = minSheetHeight;
            _canPop = false;
          });
        }
      },
      child: Scaffold(
        body: SlideTransition(
          position: _slipAnimation,
          child: Stack(
            children: [
              Positioned(
                top: context.hp(8),
                right: context.wp(4),
                child: SizedBox(
                  height: context.hp(4),
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
                          icon: Icon(
                            Icons.notifications_outlined,
                            size: context.xl,
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
                          icon: Icon(
                            Icons.settings_outlined,
                            size: context.xl,
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
                    physics: timerProvider.isRunning ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    children: [
                      Dashboard(
                        totalSeconds: timerProvider.totalSeconds,
                        remainingSeconds: timerProvider.remainingSeconds,
                      ),
                      SingleChildScrollView(
                        child: Padding(
                          padding: context.paddingSM,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: context.hp(3)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '일반 모드',
                                    style: AppTextStyles.getHeadline(context),
                                  ),
                                  SizedBox(height: context.hp(1)),
                                  Text(
                                    '활동을 선택해서 시간을 기록하세요',
                                    style: AppTextStyles.getCaption(context),
                                  ),
                                  SizedBox(height: context.hp(3)),
                                  Container(
                                    width: double.infinity,
                                    padding: context.paddingSM,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: AppColors.backgroundSecondary(context),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '남은 시간',
                                          style: AppTextStyles.getBody(context).copyWith(fontWeight: FontWeight.w900),
                                        ),
                                        Text(
                                          timerProvider.formattedTime,
                                          style: AppTextStyles.getTimeDisplay(context).copyWith(
                                            color: AppColors.primary(context),
                                            fontFamily: 'chab',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: context.hp(2)),
                                  GestureDetector(
                                    onTap: () => _showActivityModal(timerProvider),
                                    child: Container(
                                      padding: context.paddingXS,
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundSecondary(context),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              SizedBox(width: context.wp(2)),
                                              Icon(
                                                getIconData(timerProvider.currentActivityIcon),
                                              ),
                                              SizedBox(width: context.wp(5)),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '선택된 활동',
                                                    style: AppTextStyles.getCaption(
                                                      context,
                                                    ).copyWith(fontWeight: FontWeight.w600),
                                                  ),
                                                  Text(
                                                    timerProvider.currentActivityName,
                                                    style: AppTextStyles.getBody(context).copyWith(fontWeight: FontWeight.w900),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                          SizedBox(width: context.wp(10)),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: context.xl,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: context.hp(8),
                              ),
                              TextIndicator(
                                timerProvider: timerProvider,
                              ),
                              SizedBox(
                                height: context.hp(2),
                              ),
                              AnimatedBuilder(
                                  animation: _shimmerAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      key: _playButtonKey,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orange,
                                                Colors.pinkAccent,
                                                Colors.red,
                                                ColorService.hexToColor(timerProvider.currentActivityColor),
                                              ],
                                              begin: _shimmerAnimation.value, // 애니메이션 시작점
                                              end: Alignment(-_shimmerAnimation.value.x, -_shimmerAnimation.value.y), // 애니메이션 끝점
                                              tileMode: TileMode.mirror, // 경계에서 반복
                                            ),
                                            borderRadius: BorderRadius.circular(50),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.pinkAccent.withOpacity(0.5),
                                                blurRadius: 8, // 그림자 흐림 정도
                                                offset: const Offset(0, 4), // 그림자 위치
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            key: ValueKey<bool>(timerProvider.isRunning),
                                            icon: const Icon(Icons.play_arrow_rounded),
                                            iconSize: context.wp(20),
                                            color: Colors.white,
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              if (timerProvider.currentActivityId != null) {
                                                timerProvider.setSessionModeAndTargetDuration(
                                                    mode: 'SESSIONNORMAL', targetDuration: timerProvider.remainingSeconds);
                                                Navigator.of(context).push(
                                                  PageRouteBuilder(
                                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                                        TimerRunningPage(timerData: widget.timerData),
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
                                                  fontSize: context.md,
                                                );
                                                _showActivityModal(timerProvider);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                            ],
                          ),
                        ),
                      ),
                      FocusMode(timerData: widget.timerData),
                      Todo(),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: context.hp(16),
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: context.wp(60),
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated Circle
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          left: _currentPageIndex * itemWidth + (itemWidth - _circleWidth) / 2,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: _circleWidth,
                            height: _circleHeight,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(50), // 항상 원으로 유지
                            ),
                          ),
                        ),
                        // Navigation Icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(
                            4,
                            (index) {
                              return GestureDetector(
                                onTap: () => _onIconTap(index),
                                child: TweenAnimationBuilder<Color?>(
                                  tween: ColorTween(
                                    begin: _currentPageIndex == index ? Colors.grey : Colors.white,
                                    end: _currentPageIndex == index ? Colors.white : Colors.grey,
                                  ),
                                  duration: const Duration(milliseconds: 300),
                                  builder: (context, color, child) {
                                    return Icon(
                                      _getIconForIndex(index),
                                      color: color,
                                      size: context.xl,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SessionHistorySheet(
                controller: _controller,
                onPopInvoked: (isFullScreen) {
                  setState(() {
                    _canPop = false;
                  });
                },
                onExtentChanged: (extent) {
                  setState(() {
                    _sheetSize = extent;
                  });
                },
                isBackButtonPressed: _isBackButtonPressed,
                sheetScrollController: _sheetScrollController,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.bar_chart_rounded;
      case 1:
        return Icons.timer_rounded;
      case 2:
        return Icons.hourglass_top_rounded;
      case 3:
        return Icons.check_circle_rounded;
      default:
        return Icons.error;
    }
  }
}
