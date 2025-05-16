import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:project1/widgets/activity_heat_map.dart';
import 'package:project1/widgets/dahboard_section.dart';
import 'package:project1/widgets/toggle_total_view_swtich.dart';
import 'package:project1/widgets/weekly_activity_chart.dart';
import 'package:project1/widgets/weekly_heatmap.dart';
import 'package:project1/widgets/weekly_session_status.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  ScrollController _scrollController = ScrollController();
  TimerProvider? timerProvider;
  StatsProvider? statsProvider;

  // admob 광고
  BannerAd? _bannerAd1;
  BannerAd? _bannerAd2;
  bool _isAdLoaded1 = false;
  bool _isAdLoaded2 = false;

  bool showAllHours = true;
  bool refreshKey = false;

  bool _isOffsetSectionPinned = false;

  // 섹션별 데이터 로딩 상태 관리
  bool _lineChartDataLoaded = false;
  bool _heatmapDataLoaded = false;
  bool _activityChartDataLoaded = false;

  @override
  void initState() {
    super.initState();

    // admob 광고 초기화
    _bannerAd1 = BannerAd(
      adUnitId: 'ca-app-pub-9503898094962699/5342392791',
      size: AdSize.fullBanner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isAdLoaded1 = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          print('BannerAd failed to load: $error');
        },
      ),
    );
    _bannerAd1!.load();

    _bannerAd2 = BannerAd(
      adUnitId: 'ca-app-pub-9503898094962699/3819791084',
      size: AdSize.fullBanner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isAdLoaded2 = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          print('BannerAd failed to load: $error');
        },
      ),
    );
    _bannerAd2!.load();

    // 데이터 미리 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadData();
    });
  }

  @override
  void dispose() {
    _bannerAd1?.dispose();
    _bannerAd2?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    timerProvider = Provider.of<TimerProvider>(context);
    statsProvider = Provider.of<StatsProvider>(context);
  }

  // 데이터 미리 로딩 함수
  Future<void> _preloadData() async {
    if (!mounted) return;

    // 타이머 데이터 미리 로드
    statsProvider?.initializeHeatMapData();
    setState(() {
      _heatmapDataLoaded = true;
    });

    statsProvider?.initializeWeeklyActivityData();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '내 기록',
          style: AppTextStyles.getTitle(context),
        ),
        backgroundColor: AppColors.backgroundSecondary(context),
      ),
      body: Container(
        color: AppColors.backgroundSecondary(context),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // 주 선택기 섹션
            SliverPersistentHeader(
              pinned: true, // 이 부분이 핵심: 스크롤 시 상단에 고정됨
              delegate: _SliverAppBarDelegate(
                minHeight: 60.0, // 최소 높이 조정
                maxHeight: 60.0, // 최대 높이 조정
                child: _buildOffsetSection(context),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: context.hp(2)),
            ),

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
              child: SizedBox(height: context.hp(1)),
            ),

            // 첫 번째 광고 배너
            SliverToBoxAdapter(
              child: _isAdLoaded1
                  ? Container(
                      width: _bannerAd1!.size.width.toDouble(),
                      height: _bannerAd1!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd1!),
                    )
                  : const SizedBox.shrink(),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: context.hp(1)),
            ),

            // 활동 시간 섹션
            SliverToBoxAdapter(
              child: _buildActivityTimeSection(context, timerProvider!),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: context.hp(2)),
            ),

            // 히트맵 섹션
            SliverToBoxAdapter(
              child: _buildHeatmapSection(context, timerProvider!),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: context.hp(1)),
            ),

            // 두 번째 광고 배너
            SliverToBoxAdapter(
              child: _isAdLoaded2
                  ? Container(
                      width: _bannerAd2!.size.width.toDouble(),
                      height: _bannerAd2!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd2!),
                    )
                  : SizedBox.shrink(),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: context.hp(1)),
            ),

            // 활동 캘린더 섹션
            SliverToBoxAdapter(
              child: _buildActivityCalendarSection(context),
            ),
          ],
        ),
      ),
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
                color: AppColors.background(context).withValues(alpha: 0.2),
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
                        statsProvider!.initializeHeatMapData();
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
                  baseColor: Colors.grey.shade300.withValues(alpha: 0.2),
                  highlightColor: Colors.grey.shade100.withValues(alpha: 0.2),
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
      // padding: context.paddingSM,
      decoration: BoxDecoration(
        color: AppColors.background(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WeeklyActivityChart(),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight || child != oldDelegate.child;
  }
}
