import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/screens/session_history_sheet.dart';
import 'package:project1/screens/setting_page.dart';
import 'package:project1/screens/subscription_bottom_sheet.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/widgets/fluid_gradient_background.dart';
import 'package:project1/widgets/focus_mode.dart';
import 'package:project1/widgets/focus_mode_card.dart';
import 'package:project1/widgets/text_indicator.dart';
import 'package:project1/widgets/timer_info_card.dart';
import 'package:project1/widgets/timer_page_header.dart';
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
        isScrollControlled: true,
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
        backgroundColor: AppColors.backgroundSecondary(context),
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: context.hp(6)),
                const TimerPageHeader(),
                SizedBox(height: context.hp(0.5)),
                TimerInfoCard(
                  timerProvider: timerProvider,
                  showActivityModal: () => _showActivityModal(timerProvider),
                ),
                SizedBox(
                  height: context.hp(5),
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // 타이머 모드의 상단 제목
                      AnimatedAlign(
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
                                    Icon(LucideIcons.hourglass, size: context.lg),
                                    SizedBox(width: context.wp(2)),
                                    Text(
                                      "집중 모드",
                                      style: AppTextStyles.getBody(context).copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
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
                                    Icon(LucideIcons.timer, size: context.lg),
                                    SizedBox(width: context.wp(2)),
                                    Text(
                                      "일반 모드",
                                      style: AppTextStyles.getBody(context).copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
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

                // 타이머 모드 및 실행버튼
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    children: [
                      // 집중모드
                      FocusMode(timerData: widget.timerData),
                      // 일반 모드
                      SingleChildScrollView(
                        child: Padding(
                          padding: context.paddingSM,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: context.hp(10)),
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
                    ],
                  ),
                ),
              ],
            ),

            /// 2) 하단 커스텀 네비게이션 바
            Positioned(
              left: 0,
              right: 0,
              bottom: context.hp(3), // 필요하다면 0으로 조절 가능
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
                                  size: context.lg,
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
          ],
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return LucideIcons.hourglass;
      case 1:
        return LucideIcons.timer;

      default:
        return Icons.error;
    }
  }
}
