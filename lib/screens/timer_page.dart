import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/screens/session_history_sheet.dart';
import 'package:project1/screens/setting_page.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/widgets/focus_mode.dart';
import 'package:project1/widgets/text_indicator.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:project1/utils/responsive_size.dart';

class TimerPage extends StatefulWidget {
  final Map<String, dynamic> timerData;

  const TimerPage({super.key, required this.timerData});

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  TimerProvider? _timerProvider; // TimerProvider 변수 추가
  StatsProvider? _statsProvider;

  final DraggableScrollableController _controller = DraggableScrollableController();
  final ScrollController _sheetScrollController = ScrollController();

  late AnimationController _shimmerAnimationcontroller;
  late Animation<Alignment> _shimmerAnimation;

  final PageController _pageController = PageController(initialPage: 1);
  final GlobalKey _playButtonKey = GlobalKey();

  int _currentPageIndex = 1;
  int? selectedIndex = 1;
  bool _isBackButtonPressed = false;
  double _sheetSize = 0.1; // 초기 크기
  double minSheetHeight = 0.1;
  double maxSheetHeight = 1.0;
  double _circleWidth = 30;
  double _circleHeight = 30;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();

    // provider init
    _timerProvider = Provider.of<TimerProvider>(context, listen: false);
    _statsProvider = Provider.of<StatsProvider>(context, listen: false);

    // 통계 데이터 init
    Future.delayed(Duration.zero, () async {
      _timerProvider!.initializeWeeklyActivityData();
      _timerProvider!.initializeHeatMapData();
      _statsProvider!.updateCurrentSessions();
      _timerProvider!.refreshRemainingSeconds();
    });

    // animation init
    _initAnimations();
    WidgetsBinding.instance.addObserver(this);
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _isDarkMode = brightness == Brightness.dark;
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerAnimationcontroller.dispose();
    _backPressTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // 앱이 다시 포그라운드로 돌아왔을 때
      _timerProvider?.refreshRemainingSeconds();
    }
  }

  void _initAnimations() {
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

  @override
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
      _circleWidth = 30;
      _circleHeight = 5;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      setState(() {
        _circleWidth = 30;
        _circleHeight = 30;
        _currentPageIndex = index;
      });
    });
  }

  void _onPageChanged(int index) {
    _animateCircle(index);

    HapticFeedback.lightImpact();
    setState(() {
      _currentPageIndex = index;
    });
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
    // 타이머가 작동 중일 때는 토스트 메시지 띄우기
    if (timerProvider.isRunning) {
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

    final double containerWidth = context.wp(30); // 네비게이션 바 가로 길이
    final double itemWidth = containerWidth / 2; // 버튼 하나의 너비

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
          if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
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
        body: Stack(
          children: [
            /// 1) 상단 영역 + PageView(모드 화면) 배치
            Column(
              children: [
                // ---------------------------
                // 상단 헤더(이번주 남은시간, 선택된 Activity)
                // ---------------------------
                SizedBox(
                  height: context.hp(8),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _statsProvider!.getCurrentWeekLabel().toString(),
                          style: AppTextStyles.getHeadline(context).copyWith(
                            fontFamily: 'Neo',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingPage()),
                          );
                        },
                        child: Image.asset(
                          getIconImage('gear'),
                          width: context.wp(8),
                          height: context.wp(8),
                          color: Colors.grey.withOpacity(0.5),
                          errorBuilder: (context, error, stackTrace) {
                            // 이미지를 로드하는 데 실패한 경우의 대체 표시
                            return Container(
                              width: context.xl,
                              height: context.xl,
                              color: Colors.grey.withOpacity(0.2),
                              child: Icon(
                                Icons.settings,
                                size: context.xl,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: context.hp(2),
                    left: context.wp(4),
                    right: context.wp(4),
                    bottom: context.hp(2),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이번 주 얼마나 남았을까요?',
                        style: AppTextStyles.getTitle(context).copyWith(fontWeight: FontWeight.w900),
                      ),
                      Consumer<TimerProvider>(
                        builder: (context, provider, child) {
                          return Text(
                            provider.formattedTime,
                            style: AppTextStyles.getTimeDisplay(context).copyWith(
                              color: AppColors.primary(context),
                              fontFamily: 'chab',
                            ),
                          );
                        },
                      ),
                      SizedBox(height: context.hp(1)),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showActivityModal(timerProvider);
                        },
                        child: Container(
                            padding: EdgeInsets.symmetric(horizontal: context.xs, vertical: context.sm),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary(context),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textSecondary(context).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // 왼쪽: "무엇을 하실 건가요?" 텍스트 (flex: 2)
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: context.sm),
                                    child: Text(
                                      '활동 선택',
                                      style: AppTextStyles.getBody(context).copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                ),

                                // 가운데: 아이콘 + 현재 활동명 (flex: 3)
                                Expanded(
                                  flex: 6,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Image.asset(
                                        getIconImage(timerProvider.currentActivityIcon),
                                        width: context.xl,
                                        height: context.xl,
                                        errorBuilder: (context, error, stackTrace) {
                                          // 이미지를 로드하는 데 실패한 경우의 대체 표시
                                          return Container(
                                            width: context.xl,
                                            height: context.xl,
                                            color: Colors.grey.withOpacity(0.2),
                                            child: Icon(
                                              Icons.broken_image,
                                              size: context.xl,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(width: context.wp(2)),
                                      Flexible(
                                        child: Builder(
                                          builder: (context) {
                                            final activityName = timerProvider.currentActivityName;
                                            final displayText =
                                                activityName.length > 10 ? '${activityName.substring(0, 10)}...' : activityName;

                                            return Text(
                                              displayText,
                                              style: AppTextStyles.getTitle(context).copyWith(fontWeight: FontWeight.w900),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 오른쪽: 화살표 아이콘 (flex: 1)
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Transform(
                                      // 중심을 기준으로 좌우 대칭(수평 반전)하기
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()..scale(-1.0, 1.0),
                                      child: Icon(Icons.arrow_back_ios_new_rounded, size: context.lg),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.hp(2)),
                SizedBox(
                  height: context.hp(5),
                  width: double.infinity,
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        // 왼쪽 페이지가 활성화되면(center)에 위치하여 텍스트 포함,
                        // 오른쪽 페이지가 활성화되면(left) 구석에 아이콘만 표시
                        alignment: _currentPageIndex == 1 ? Alignment.centerLeft : Alignment.center,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        // 아래 AnimatedSwitcher는 “아이콘만” ↔ “아이콘+텍스트” 전환용
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          // child가 바뀔 때마다(아이콘만 → 아이콘+텍스트) 애니메이션
                          child: _currentPageIndex == 1
                              ? GestureDetector(
                                  onTap: () => _onIconTap(0),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: context.lg),
                                    child: Icon(Icons.arrow_back_ios_rounded, size: context.lg),
                                  ),
                                )
                              : Row(
                                  key: const ValueKey<String>("LeftWithText"),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timelapse_sharp, size: context.lg),
                                    SizedBox(width: context.wp(2)),
                                    Text(
                                      "집중 모드",
                                      style: AppTextStyles.getTitle(context),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      AnimatedAlign(
                        // 오른쪽 페이지가 활성화되면(center)에 위치하여 텍스트 포함,
                        // 왼쪽 페이지가 활성화되면(right) 구석에 아이콘만 표시
                        alignment: _currentPageIndex == 1 ? Alignment.center : Alignment.centerRight,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          child: _currentPageIndex == 1
                              ? Row(
                                  key: const ValueKey<String>("RightWithText"),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_rounded, size: context.lg),
                                    SizedBox(width: context.wp(2)),
                                    Text(
                                      "일반 모드",
                                      style: AppTextStyles.getTitle(context),
                                    ),
                                  ],
                                )
                              : Transform(
                                  // 중심을 기준으로 좌우 대칭(수평 반전)하기
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..scale(-1.0, 1.0),
                                  child: GestureDetector(
                                    onTap: () => _onIconTap(1),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: context.lg),
                                      child: Icon(Icons.arrow_back_ios_rounded, size: context.lg),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ---------------------------
                // PageView (뽀모도로, 일반모드, 투두)
                // ---------------------------
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: timerProvider.isRunning ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    children: [
                      // 0) 뽀모도로(=FocusMode)
                      FocusMode(timerData: widget.timerData),

                      // 1) 일반 모드
                      SingleChildScrollView(
                        child: Padding(
                          padding: context.paddingSM,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: context.hp(15)),
                              // 시간 표시 인디케이터
                              Center(
                                child: TextIndicator(timerProvider: timerProvider),
                              ),
                              SizedBox(height: context.hp(3)),
                              // 플레이 버튼
                              Center(
                                child: AnimatedBuilder(
                                  animation: _shimmerAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      key: _playButtonKey,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.orange,
                                            Colors.pinkAccent,
                                            Colors.red,
                                            ColorService.hexToColor(
                                              timerProvider.currentActivityColor,
                                            ),
                                          ],
                                          begin: _shimmerAnimation.value,
                                          end: Alignment(
                                            -_shimmerAnimation.value.x,
                                            -_shimmerAnimation.value.y,
                                          ),
                                          tileMode: TileMode.mirror,
                                        ),
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.pinkAccent.withOpacity(0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.play_arrow_rounded),
                                        iconSize: context.wp(20),
                                        color: Colors.white,
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          if (timerProvider.currentActivityId != null) {
                                            timerProvider.setSessionModeAndTargetDuration(
                                              mode: 'NORMAL',
                                              targetDuration: timerProvider.remainingSeconds,
                                            );
                                            Navigator.of(context).push(
                                              PageRouteBuilder(
                                                pageBuilder: (context, animation, _) => TimerRunningPage(
                                                  timerData: widget.timerData,
                                                  isNewSession: true,
                                                ),
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
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Todo(
                      //   onHeaderVisibilityChanged: (bool isHidden) {
                      //     setState(() {
                      //       _isHeaderHidden = isHidden;
                      //     });
                      //     if (isHidden) {
                      //       _headerAnimation.forward();
                      //     } else {
                      //       _headerAnimation.reverse();
                      //     }
                      //   },
                      // ),
                    ],
                  ),
                ),
              ],
            ),

            /// 2) 하단 커스텀 네비게이션 바
            Positioned(
              left: 0,
              right: 0,
              bottom: context.hp(14), // 필요하다면 0으로 조절 가능
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: context.wp(30),
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.background(context),
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary(context).withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 애니메이션 원
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
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                      // 아이콘 3개
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(2, (index) {
                          return GestureDetector(
                            onTap: () {
                              _onIconTap(index);
                            },
                            child: TweenAnimationBuilder<Color?>(
                              tween: ColorTween(
                                begin: _currentPageIndex == index ? Colors.grey[300] : Colors.white,
                                end: _currentPageIndex == index ? Colors.white : Colors.grey[300],
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
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// 3) 드래그 시트 (SessionHistorySheet)
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
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.timelapse_sharp;
      case 1:
        return Icons.timer_rounded;
      case 2:
        return Icons.check_circle_rounded;
      default:
        return Icons.error;
    }
  }
}
