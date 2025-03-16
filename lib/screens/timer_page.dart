import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/screens/notice_page.dart';
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
import 'package:project1/widgets/todo.dart';
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

  late AnimationController _slipAnimationController;
  late Animation<Offset> _slipAnimation;
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
  double _circleWidth = 40;
  double _circleHeight = 40;
  bool _isDarkMode = false;

  // 상단 바 숨기기 애니메이션
  bool _isHeaderHidden = false;
  late AnimationController _headerAnimation;

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
      _timerProvider!.refreshRemainingSeconds();
    });

    // animation init
    _initAnimations();
    WidgetsBinding.instance.addObserver(this);
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _isDarkMode = brightness == Brightness.dark;

    // 헤더 숨김/표시 상태 변수 추가
    _isHeaderHidden = false;

    // 헤더 애니메이션 컨트롤러 초기화
    _headerAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _slipAnimationController.dispose();
    _shimmerAnimationcontroller.dispose();
    _backPressTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _headerAnimation.dispose();

    super.dispose();
  }

  void _initAnimations() {
    _slipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
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

    HapticFeedback.lightImpact();
    setState(() {
      _currentPageIndex = index;

      // Todo 모드(인덱스 2)로 이동시 헤더 초기화 - 항상 표시 상태로
      if (index != 2 && _isHeaderHidden) {
        _isHeaderHidden = false;
        _headerAnimation.reverse();
      }
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

    final double containerWidth = context.wp(60); // 네비게이션 바 가로 길이
    final double itemWidth = containerWidth / 3; // 버튼 하나의 너비

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
        appBar: AppBar(
          title: Text(
            _statsProvider!.getCurrentWeekLabel().toString(),
            style: AppTextStyles.getHeadline(context),
          ), // 실제로는 timerProvider에서 주차 정보를 받아와 사용
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.background(context),
          foregroundColor: AppColors.textPrimary(context),
        ),
        body: Stack(
          children: [
            if (_isHeaderHidden && _currentPageIndex == 2)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isHeaderHidden = false;
                      _headerAnimation.reverse();
                    });
                  },
                  child: Container(
                    height: context.hp(2),
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Container(
                      width: context.wp(15),
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),

            /// 1) 상단 영역 + PageView(모드 화면) 배치
            Column(
              children: [
                // ---------------------------
                // 상단 헤더(이번주 남은시간, 선택된 Activity)
                // ---------------------------
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isHeaderHidden ? 0 : null, // 높이를 0으로 만들어 숨김
                  child: SlideTransition(
                    position: _headerAnimation.drive(
                      Tween<Offset>(
                        begin: Offset.zero,
                        end: const Offset(0, -1), // 위로 슬라이드
                      ),
                    ),
                    child: Container(
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
                            '이번 주, 아직 얼마나 남았을까요?',
                            style: AppTextStyles.getTitle(context).copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            timerProvider.formattedTime,
                            style: AppTextStyles.getTimeDisplay(context).copyWith(
                              color: AppColors.primary(context),
                              fontFamily: 'chab',
                            ),
                          ),
                          SizedBox(height: context.hp(1)),
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
                                  // 왼쪽: 아이콘 + 현재 활동명
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
                                            '내가 고른 활동,',
                                            style: AppTextStyles.getBody(context)
                                                .copyWith(fontWeight: FontWeight.w600)
                                                .copyWith(color: AppColors.textSecondary(context)),
                                          ),
                                          Text(
                                            timerProvider.currentActivityName,
                                            style: AppTextStyles.getTitle(context).copyWith(fontWeight: FontWeight.w900),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // 오른쪽: 화살표 아이콘
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
                    ),
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
                              SizedBox(height: context.hp(20)),
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

                      Todo(
                        onHeaderVisibilityChanged: (bool isHidden) {
                          setState(() {
                            _isHeaderHidden = isHidden;
                          });
                          if (isHidden) {
                            _headerAnimation.forward();
                          } else {
                            _headerAnimation.reverse();
                          }
                        },
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
              bottom: context.hp(14), // 필요하다면 0으로 조절 가능
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: context.wp(60),
                  height: 50,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.black : Colors.white,
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
                        children: List.generate(3, (index) {
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
