import 'package:flutter/material.dart';
import 'package:project1/screens/activity_log_page.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/widgets/weekly_session_status.dart';
import 'package:project1/widgets/weekly_heatmap.dart';
import 'package:project1/widgets/weekly_activity_chart.dart';
import 'package:project1/widgets/activity_heat_map.dart';
import 'package:project1/widgets/footer.dart';
import 'package:project1/widgets/toggle_total_view_swtich.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/timer_provider.dart';

class SessionHistorySheet extends StatefulWidget {
  final DraggableScrollableController controller;
  final void Function(bool) onPopInvoked;
  final void Function(double) onExtentChanged;
  final ScrollController? sheetScrollController;
  final bool isBackButtonPressed;

  const SessionHistorySheet({
    Key? key,
    required this.controller,
    required this.onPopInvoked,
    required this.onExtentChanged,
    this.sheetScrollController,
    required this.isBackButtonPressed,
  }) : super(key: key);

  @override
  State<SessionHistorySheet> createState() => _SessionHistorySheetState();
}

class _SessionHistorySheetState extends State<SessionHistorySheet> {
  ScrollController? _scrollController;

  bool showAllHours = true;
  bool refreshKey = false;
  double currentExtent = 0.13;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController = null;
    super.dispose();
  }

  void didUpdateWidget(SessionHistorySheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isBackButtonPressed && !oldWidget.isBackButtonPressed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleBackPress();
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
    final timerProvider = Provider.of<TimerProvider>(context);
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return DraggableScrollableSheet(
      controller: widget.controller,
      initialChildSize: 0.13,
      minChildSize: 0.13,
      maxChildSize: 1,
      snap: true,
      snapAnimationDuration: const Duration(milliseconds: 300),
      builder: (BuildContext context, ScrollController scrollController) {
        if (_scrollController != scrollController) {
          _scrollController = scrollController;
        }

        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            if (!mounted) return true;
            setState(() {
              currentExtent = notification.extent;
            });

            // 크기가 최소로 줄어들었을 때 스크롤 초기화
            if (notification.extent <= 0.13) {
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
                  ? (isDarkMode ? const Color(0xff181C14) : Colors.white)
                  : (isDarkMode ? Colors.black : Colors.redAccent.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 4,
                  blurRadius: 10,
                  offset: const Offset(0, -1),
                ),
              ],
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(currentExtent >= 0.9 ? 0 : 24),
              ),
            ),
            child: CustomScrollView(
              controller: _scrollController,
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
                      SizedBox(height: context.hp(5)),
                      const WeeklySessionStatus(isSimple: false),
                      _buildActivityLogButton(context),
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: context.hp(5)),
                    _buildHeatmapSection(context, timerProvider),
                    SizedBox(height: context.hp(5)),
                    _buildActivityTimeSection(context, timerProvider),
                    SizedBox(height: context.hp(5)),
                    _buildActivityCalendarSection(context),
                    const Footer(),
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildActivityLogButton(BuildContext context) {
    return Padding(
      padding: context.paddingSM,
      child: SizedBox(
        width: context.wp(100),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ActivityLogPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // 텍스트 색상
            backgroundColor: Colors.blueAccent.shade400, // 버튼 배경색
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0), // 둥근 모서리
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // 버튼 내부 패딩
          ),
          child: Text(
            '전체 활동기록 보기',
            style: AppTextStyles.getBody(context).copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapSection(BuildContext context, TimerProvider timerProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: context.paddingHorizSM,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('이번주 히트맵 🔥', style: AppTextStyles.getTitle(context)),
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
        Padding(
          padding: context.paddingHorizSM,
          child: Text(
            '이번주 시간대별 활동을 색깔로 확인해요',
            style: AppTextStyles.getCaption(context),
          ),
        ),
        SizedBox(height: context.hp(3)),
        SizedBox(
          child: WeeklyHeatmap(
            key: ValueKey(refreshKey),
            showAllHours: showAllHours,
          ),
        ),
        SizedBox(height: context.hp(5)),
      ],
    );
  }

  Widget _buildActivityTimeSection(BuildContext context, TimerProvider timerProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: context.paddingHorizSM,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('이번주의 활동 시간 ⏱️', style: AppTextStyles.getTitle(context)),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  timerProvider.initializeWeeklyActivityData();
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: context.paddingHorizSM,
          child: Text(
            '이번주 활동 시간을 막대그래프로 한눈에 확인해요',
            style: AppTextStyles.getCaption(context),
          ),
        ),
        SizedBox(height: context.hp(3)),
        const WeeklyActivityChart(),
        SizedBox(height: context.hp(5)),
      ],
    );
  }

  Widget _buildActivityCalendarSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: context.paddingSM,
          child: Text('잔디심기 🌱', style: AppTextStyles.getTitle(context)),
        ),
        Padding(
          padding: context.paddingHorizSM,
          child: Text(
            '활동을 하면 달력에 잔디가 심어져요',
            style: AppTextStyles.getCaption(context),
          ),
        ),
        SizedBox(height: context.hp(3)),
        const SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: ActivityHeatMap(),
              ),
            ],
          ),
        ),
        SizedBox(height: context.hp(3)),
      ],
    );
  }
}
