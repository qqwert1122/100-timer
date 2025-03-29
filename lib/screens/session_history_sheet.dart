import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:project1/screens/activity_log_page.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/widgets/dahboard_section.dart';
import 'package:project1/widgets/weekly_session_status.dart';
import 'package:project1/widgets/weekly_heatmap.dart';
import 'package:project1/widgets/weekly_activity_chart.dart';
import 'package:project1/widgets/activity_heat_map.dart';
import 'package:project1/widgets/footer.dart';
import 'package:project1/widgets/toggle_total_view_swtich.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:shimmer/shimmer.dart';

class SessionHistorySheet extends StatefulWidget {
  final DraggableScrollableController controller;
  final void Function(bool) onPopInvoked;
  final void Function(double) onExtentChanged;
  final ScrollController? sheetScrollController;
  final bool isBackButtonPressed;

  const SessionHistorySheet({
    super.key,
    required this.controller,
    required this.onPopInvoked,
    required this.onExtentChanged,
    this.sheetScrollController,
    required this.isBackButtonPressed,
  });

  @override
  State<SessionHistorySheet> createState() => _SessionHistorySheetState();
}

class _SessionHistorySheetState extends State<SessionHistorySheet> with AutomaticKeepAliveClientMixin {
  ScrollController? _scrollController;
  TimerProvider? timerProvider;
  StatsProvider? statsProvider;

  bool showAllHours = true;
  bool refreshKey = false;
  double currentExtent = 0.1;

  bool _isOffsetSectionPinned = false;

  // 섹션별 데이터 로딩 상태 관리
  bool _lineChartDataLoaded = false;
  bool _heatmapDataLoaded = false;
  bool _activityChartDataLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // 데이터 미리 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadData();
    });
  }

  @override
  void dispose() {
    _scrollController = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    timerProvider = Provider.of<TimerProvider>(context);
    statsProvider = Provider.of<StatsProvider>(context);
  }

  @override
  void didUpdateWidget(SessionHistorySheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isBackButtonPressed && !oldWidget.isBackButtonPressed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleBackPress();
      });
    }
  }

  // 데이터 미리 로딩 함수
  Future<void> _preloadData() async {
    if (!mounted) return;

    // 타이머 데이터 미리 로드
    timerProvider?.initializeHeatMapData();
    setState(() {
      _heatmapDataLoaded = true;
    });

    timerProvider?.initializeWeeklyActivityData();
    setState(() {
      _activityChartDataLoaded = true;
    });

    // 스탯 데이터 미리 로드
    await statsProvider?.getWeeklyActivityChart();
    if (mounted) {
      setState(() {
        _lineChartDataLoaded = true;
      });
    }
  }

  void _handleBackPress() {
    if (_scrollController == null) {
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 강제 초기화
        _scrollController!.jumpTo(0.0);
      });
    }
  }

  void rerenderingHeatmap() {
    if (!mounted) return; // mounted 체크 추가
    setState(() {
      refreshKey = !refreshKey;
    });
  }

  void _toggleShowAllHours(bool value) {
    if (!mounted) return; // mounted 체크 추가
    setState(() {
      showAllHours = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 요구사항
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Stack(
      children: [
        // 메인 DraggableScrollableSheet
        DraggableScrollableSheet(
          controller: widget.controller,
          initialChildSize: 0.1,
          minChildSize: 0.1,
          maxChildSize: 1,
          snap: true,
          snapAnimationDuration: const Duration(milliseconds: 300),
          builder: (BuildContext context, ScrollController scrollController) {
            if (_scrollController != scrollController) {
              _scrollController = scrollController;
              _scrollController?.addListener(_onScroll);
            }

            return NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                if (!mounted) return true;
                setState(() {
                  currentExtent = notification.extent;
                });

                // 크기가 최소로 줄어들었을 때 스크롤 초기화
                if (notification.extent <= 0.1) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController?.hasClients == true) {
                      _scrollController!.jumpTo(0.0);
                    }
                  });
                }

                widget.onPopInvoked(notification.extent >= 0.9);
                widget.onExtentChanged(notification.extent);
                return true;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: currentExtent >= 0.2
                      ? AppColors.backgroundSecondary(context)
                      : (isDarkMode ? AppColors.backgroundSecondary(context) : Colors.redAccent.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textSecondary(context).withOpacity(0.3),
                      spreadRadius: 4,
                      blurRadius: 10,
                      offset: const Offset(0, -1),
                    ),
                  ],
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(currentExtent >= 0.9 ? 0 : 24),
                  ),
                ),
                child: Stack(
                  children: [
                    CustomScrollView(
                      controller: _scrollController,
                      // 부드러운 스크롤을 위한 Physics 설정
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.easeInOut,
                                height: currentExtent >= 0.2 ? context.hp(8) : context.hp(2),
                              ),
                              _buildDragHandle(context),
                              _buildHeader(context),
                              SizedBox(height: context.hp(1)),
                              // offset section 고정될 때는 안 보이게 처리
                              Visibility(
                                visible: !_isOffsetSectionPinned,
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                child: _buildOffsetSection(context),
                              ),
                              // offset section의 높이만큼 공간 추가
                              SizedBox(height: _isOffsetSectionPinned ? 0 : context.hp(1)),
                            ],
                          ),
                        ),

                        // SliverList 대신 SliverToBoxAdapter의 리스트 사용
                        // 각 섹션을 개별 SliverToBoxAdapter로 분리하여 높이 제한 없이 콘텐츠 표시

                        // 대시보드 섹션
                        const SliverToBoxAdapter(
                          child: DashboardSection(),
                        ),

                        SliverToBoxAdapter(
                          child: SizedBox(height: context.hp(2)),
                        ),

                        // 주간 세션 상태 섹션
                        const SliverToBoxAdapter(
                          child: WeeklySessionStatus(),
                        ),

                        SliverToBoxAdapter(
                          child: SizedBox(height: context.hp(2)),
                        ),

                        // 히트맵 섹션
                        SliverToBoxAdapter(
                          child: _buildHeatmapSection(context, timerProvider!),
                        ),

                        SliverToBoxAdapter(
                          child: SizedBox(height: context.hp(2)),
                        ),

                        // 활동 시간 섹션
                        SliverToBoxAdapter(
                          child: _buildActivityTimeSection(context, timerProvider!),
                        ),

                        SliverToBoxAdapter(
                          child: SizedBox(height: context.hp(2)),
                        ),

                        // 활동 캘린더 섹션
                        SliverToBoxAdapter(
                          child: _buildActivityCalendarSection(context),
                        ),

                        // 플로팅 버튼을 위한 하단 여백
                        SliverToBoxAdapter(
                          child: SizedBox(height: context.hp(10)),
                        ),

                        const SliverToBoxAdapter(
                          child: Footer(),
                        ),
                      ],
                    ),

                    // 상단에 고정될 오프셋 섹션
                    Positioned(
                      top: _buildOffsetSectionPosition(),
                      left: 0,
                      right: 0,
                      child: Visibility(
                        visible: _isOffsetSectionPinned,
                        child: Container(
                          // 배경색을 완전히 투명하게 설정하여 BlurEffect만 보이게 함
                          color: Colors.transparent,
                          child: _buildOffsetSection(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // 플로팅 버튼 - 현재 extent 변수를 사용하여 표시 여부 결정
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          child: AnimatedOpacity(
            opacity: currentExtent >= 0.2 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: currentExtent < 0.2,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ActivityLogPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueAccent.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    elevation: 0, // 그림자는 Container에서 처리
                  ),
                  child: Text(
                    '전체 활동기록 보기',
                    style: AppTextStyles.getBody(context).copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: context.md,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _buildOffsetSectionPosition() {
    // 현재 extent에 따라 위치 조정
    if (currentExtent >= 0.9) {
      return MediaQuery.of(context).padding.top; // 상단 안전 영역 고려
    } else {
      return context.hp(8) + 5 + context.xl; // 드래그 핸들 + 헤더 높이
    }
  }

  void _onScroll() {
    if (!mounted || _scrollController == null) return;

    // 오프셋 섹션이 상단에 도달했는지 확인 (임계값 설정)
    double offsetSectionThreshold = context.hp(8) + 5 + context.xl + context.hp(2);
    bool shouldPin = _scrollController!.offset > offsetSectionThreshold;

    if (shouldPin != _isOffsetSectionPinned) {
      setState(() {
        _isOffsetSectionPinned = shouldPin;
      });
    }
  }

  Widget _buildDragHandle(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: context.wp(20),
        height: 5,
        decoration: BoxDecoration(
          color: currentExtent >= 0.2 ? AppColors.textPrimary(context) : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: context.paddingSM,
          child: AnimatedDefaultTextStyle(
            style: TextStyle(
              fontFamily: 'Neo',
              fontWeight: FontWeight.w900,
              fontSize: currentExtent >= 0.2 ? context.xl : context.md,
              color: currentExtent >= 0.2 ? AppColors.textPrimary(context) : Colors.white,
            ),
            duration: const Duration(milliseconds: 200),
            child: const Text('내 기록'),
          ),
        ),
        Padding(
          padding: context.paddingSM,
          child: Icon(
            Icons.history_rounded,
            size: context.xl,
            color: currentExtent >= 0.2 ? AppColors.textPrimary(context) : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildOffsetSection(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, stats, child) {
        final bool isCurrentWeek = stats.weekOffset == 0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: context.hp(2)),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: AppColors.background(context).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      HapticFeedback.lightImpact();

                      // 현재 스크롤 위치 저장
                      double currentScrollPosition = 0;
                      if (_scrollController?.hasClients == true) {
                        currentScrollPosition = _scrollController!.offset;
                      }

                      // 데이터 다시 로드 전에 로딩 상태 변경
                      setState(() {
                        _lineChartDataLoaded = false;
                      });

                      // 주 변경
                      stats.moveToPreviousWeek();

                      // 데이터 로드 및 스크롤 위치 복원
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _preloadDataAndRestoreScroll(currentScrollPosition);
                      });
                    },
                  ),
                  Text(
                    stats.getSelectedWeekLabel(),
                    style: AppTextStyles.getBody(context).copyWith(fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: isCurrentWeek ? Colors.grey[300] : null,
                    ),
                    onPressed: isCurrentWeek
                        ? null
                        : () {
                            HapticFeedback.lightImpact();

                            // 현재 스크롤 위치 저장
                            double currentScrollPosition = 0;
                            if (_scrollController?.hasClients == true) {
                              currentScrollPosition = _scrollController!.offset;
                            }

                            // 데이터 다시 로드 전에 로딩 상태 변경
                            setState(() {
                              _lineChartDataLoaded = false;
                            });

                            // 주 변경
                            stats.moveToNextWeek();

                            // 데이터 로드 및 스크롤 위치 복원
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _preloadDataAndRestoreScroll(currentScrollPosition);
                            });
                          },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardSection(BuildContext context) {
    String formatHour(int seconds) {
      final hours = seconds ~/ 3600;
      return '$hours';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background(context),
            ),
            child: Padding(
              padding: context.paddingSM,
              child: FutureBuilder<List<int>>(
                future: Future.wait([
                  statsProvider!.getTotalDurationForWeek(),
                  statsProvider!.getTotalSecondsForWeek(),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("활동 완료 시간", style: AppTextStyles.getTitle(context)),
                            SizedBox(height: context.hp(1)),
                            Shimmer.fromColors(
                              baseColor: Colors.grey.shade300.withOpacity(0.2),
                              highlightColor: Colors.grey.shade100.withOpacity(0.2),
                              child: Container(
                                width: context.wp(50),
                                height: context.hp(7),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: AppColors.background(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade300.withOpacity(0.2),
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: context.wp(24), // diameter = 2 * radius
                            height: context.wp(24),
                            decoration: BoxDecoration(
                              color: AppColors.background(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    );
                    // 로딩 하나만
                  }

                  if (snapshot.hasError) {
                    return const Text('에러 발생');
                  }

                  final totalDuration = snapshot.data![0]; // 첫 번째 Future 결과
                  final totalSeconds = snapshot.data![1]; // 두 번째 Future 결과

                  final formattedDuration = formatHour(totalDuration);
                  final tagetDuration = formatHour(totalSeconds);

                  double percent = (totalDuration / totalSeconds);
                  String percentText = (percent * 100).toStringAsFixed(0);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("활동 완료 시간", style: AppTextStyles.getTitle(context)),
                          SizedBox(height: context.hp(1)),
                          Row(
                            children: [
                              Text(
                                formattedDuration,
                                style: AppTextStyles.getTimeDisplay(context).copyWith(
                                  fontFamily: 'chab',
                                  color: Colors.redAccent,
                                ),
                              ),
                              SizedBox(width: context.wp(1)),
                              Container(
                                width: 1,
                                height: context.hp(2),
                                color: Colors.grey.shade400,
                                margin: EdgeInsets.symmetric(horizontal: context.wp(1)),
                              ),
                              SizedBox(width: context.wp(1)),
                              Text(
                                '${tagetDuration}h',
                                style: AppTextStyles.getTimeDisplay(context).copyWith(
                                  fontFamily: 'chab',
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      CircularPercentIndicator(
                        radius: context.wp(12),
                        lineWidth: context.wp(5),
                        animation: true,
                        percent: percent.clamp(0.0, 1.0),
                        center: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              percentText,
                              style: AppTextStyles.getBody(context).copyWith(
                                fontSize: context.xl,
                                color: Colors.redAccent,
                                fontFamily: 'chab',
                              ),
                            ),
                            SizedBox(width: context.wp(0.5)),
                            Text(
                              '%',
                              style: AppTextStyles.getCaption(context),
                            ),
                          ],
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: Colors.redAccent,
                        backgroundColor: AppColors.backgroundSecondary(context),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

// 데이터 프리로딩 후 스크롤 위치 복원하는 함수 추가
  Future<void> _preloadDataAndRestoreScroll(double scrollPosition) async {
    if (!mounted) return;

    // 스크롤 위치 변경 방지를 위해 스크롤 컨트롤러 리스너 일시 제거
    _scrollController?.removeListener(_onScroll);

    // 데이터 로드
    await _preloadData();

    // 데이터 로드 완료 후 스크롤 위치 복원
    if (mounted && _scrollController?.hasClients == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController!.jumpTo(scrollPosition.clamp(0.0, _scrollController!.position.maxScrollExtent));

        // 리스너 재연결
        _scrollController?.addListener(_onScroll);
      });
    }
  }

  Widget _buildHeatmapSection(BuildContext context, TimerProvider timerProvider) {
    return Container(
      padding: context.paddingSM,
      decoration: BoxDecoration(
        color: AppColors.background(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('히트맵', style: AppTextStyles.getTitle(context)),
                    ],
                  ),
                  Text(
                    '시간대별 활동을 색깔로 확인해요',
                    style: AppTextStyles.getCaption(context),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ToggleTotalViewSwtich(value: showAllHours, onChanged: _toggleShowAllHours),
                  SizedBox(width: context.wp(4)),
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.backgroundSecondary(context),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        timerProvider.initializeHeatMapData();
                        rerenderingHeatmap();
                      },
                      child: Icon(Icons.refresh, color: AppColors.textPrimary(context), size: 18),
                    ),
                  )
                ],
              ),
            ],
          ),

          SizedBox(height: context.hp(3)),
          // 높이 제한 없이 콘텐츠 전체 표시
          _heatmapDataLoaded
              ? WeeklyHeatmap(
                  key: ValueKey(refreshKey),
                  showAllHours: showAllHours,
                )
              : Shimmer.fromColors(
                  baseColor: Colors.grey.shade300.withOpacity(0.2),
                  highlightColor: Colors.grey.shade100.withOpacity(0.2),
                  child: Container(
                    width: context.wp(90),
                    height: context.hp(68),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.background(context),
                    ),
                  ),
                ),
          SizedBox(height: context.hp(3)), // 하단 여백 추가
        ],
      ),
    );
  }

  Widget _buildActivityTimeSection(BuildContext context, TimerProvider timerProvider) {
    return Container(
      padding: context.paddingSM,
      decoration: BoxDecoration(
        color: AppColors.background(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _activityChartDataLoaded
              ? const WeeklyActivityChart()
              : Shimmer.fromColors(
                  baseColor: Colors.grey.shade300.withOpacity(0.2),
                  highlightColor: Colors.grey.shade100.withOpacity(0.2),
                  child: Container(
                    width: context.wp(90),
                    height: context.hp(30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.background(context),
                    ),
                  ),
                ),
          SizedBox(height: context.hp(3)), // 하단 여백 추가
        ],
      ),
    );
  }

  Widget _buildActivityCalendarSection(BuildContext context) {
    return Container(
      padding: context.paddingSM,
      decoration: BoxDecoration(color: AppColors.background(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('잔디심기', style: AppTextStyles.getTitle(context)),
                  Text(
                    '활동을 하면 달력에 잔디가 심어져요',
                    style: AppTextStyles.getCaption(context),
                  ),
                ],
              ),
              Image.asset(
                getIconImage('seedling'),
                width: context.xxxl,
                height: context.xxxl,
              ),
            ],
          ),
          SizedBox(height: context.hp(1)),
          // 높이 제한 없이 콘텐츠 표시
          const ActivityHeatMap(),
          SizedBox(height: context.hp(1)), // 하단 여백 추가
        ],
      ),
    );
  }
}
