import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/prefs_service.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:shimmer/shimmer.dart';

class WeeklySessionStatus extends StatefulWidget {
  const WeeklySessionStatus({super.key});

  @override
  State<WeeklySessionStatus> createState() => _WeeklySessionStatusState();
}

class _WeeklySessionStatusState extends State<WeeklySessionStatus> {
  final DateTime now = DateTime.now();

  late DateTime installDate;

  @override
  void initState() {
    super.initState();
    final installDateStr = PrefsService().installDate;
    final localInstallDate = DateTime.parse(installDateStr).toLocal();
    installDate = DateTime(localInstallDate.year, localInstallDate.month, localInstallDate.day);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Consumer<StatsProvider>(
      builder: (context, statsProvider, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          key: ValueKey("weekly-sessions-${statsProvider.weekOffset}"),
          future: statsProvider.getWeeklySessionFlags(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: context.paddingSM,
                decoration: BoxDecoration(
                  color: AppColors.background(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        '집중 달성한 날',
                        style: AppTextStyles.getTitle(context),
                      ),
                    ),
                    SizedBox(height: context.hp(3)),
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300.withValues(alpha: 0.2),
                      highlightColor: Colors.grey.shade100.withValues(alpha: 0.2),
                      child: Container(
                        width: context.wp(90),
                        height: context.hp(9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.background(context),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              final emptyList = <Map<String, dynamic>>[];
              final dayStatuses = _calculateDayStatuses(statsProvider, emptyList);

              return getStatusCard(dayStatuses: dayStatuses, isDarkMode: isDarkMode);
            }

            final sessions = snapshot.data!;
            final dayStatuses = _calculateDayStatuses(statsProvider, sessions);

            return getStatusCard(dayStatuses: dayStatuses, isDarkMode: isDarkMode);
          },
        );
      },
    );
  }

  Widget getStatusCard({required List<_DayStatus> dayStatuses, required bool isDarkMode}) {
    return Container(
      padding: context.paddingSM,
      decoration: BoxDecoration(
        color: AppColors.background(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '집중 달성한 날',
                  style: AppTextStyles.getTitle(context),
                ),
                const SizedBox(width: 8),
                JustTheTooltip(
                  backgroundColor: AppColors.textPrimary(context).withValues(alpha: 0.9),
                  preferredDirection: AxisDirection.up,
                  tailLength: 10.0,
                  tailBaseWidth: 20.0,
                  triggerMode: TooltipTriggerMode.tap,
                  enableFeedback: true,
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '1시간 이상 집중한 날을 표시해요',
                      style: TextStyle(
                        color: AppColors.background(context),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.info,
                    size: context.lg,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.hp(3)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayStatuses.map((status) {
              return Column(
                children: [
                  Text(status.weekday, style: AppTextStyles.getCaption(context)),
                  SizedBox(height: context.hp(1)),
                  Container(
                    width: context.xxl,
                    height: context.xxl,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _buildStatusIcon(status.status),
                    ),
                  ),
                  SizedBox(height: context.hp(1)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<_DayStatus> _calculateDayStatuses(StatsProvider statsProvider, List<Map<String, dynamic>> sessions) {
    // weekOffset을 반영하여 해당 주의 시작일 계산
    final int weekOffset = statsProvider.weekOffset;
    final DateTime monday = statsProvider.weeklyRange['startOfWeek']!;

    // 현재 주인지, 이전 주인지, 미래 주인지 판단
    final bool isCurrentWeek = weekOffset == 0;
    final bool isPastWeek = weekOffset < 0;
    final bool isFutureWeek = weekOffset > 0;

    List<_DayStatus> dayStatuses = [];
    List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    // 현재 시간 (current week인 경우에만 사용)
    DateTime now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      DateTime currentDay = monday.add(Duration(days: i));
      DateTime currentDayDate = DateTime(currentDay.year, currentDay.month, currentDay.day);
      DateTime todayDate = DateTime(now.year, now.month, now.day);

      bool isToday = isCurrentWeek && currentDayDate.isAtSameMomentAs(todayDate);
      bool isBeforeInstallation = currentDayDate.isBefore(installDate);

      // 해당 날짜의 세션들 찾기
      List<Map<String, dynamic>> daySessions = sessions.where((session) {
        DateTime sessionDate = DateTime.parse(session['start_time']).toLocal();
        return sessionDate.year == currentDay.year && sessionDate.month == currentDay.month && sessionDate.day == currentDay.day;
      }).toList();

      // long_session_flag가 있으면 완료된 것으로 처리
      bool hasLongSession = daySessions.any((session) => session['long_session_flag'] == 1);

      DayStatusType status;
      if (hasLongSession) {
        status = DayStatusType.completed;
      } else {
        if (isBeforeInstallation) {
          // 앱 설치 전이면 notAvailable
          status = DayStatusType.notAvailable;
        } else if (isCurrentWeek) {
          // 현재 주: 오늘 이후는 upcoming, 그 이전은 missed
          if (currentDay.isAfter(now)) {
            status = DayStatusType.upcoming;
          } else {
            // 오늘인 경우에도 아직 진행중일 수 있으므로 간단하게 upcoming으로 처리할 수도 있음
            status = isToday ? DayStatusType.upcoming : DayStatusType.missed;
          }
        } else if (isPastWeek) {
          // 이전 주: 모든 날은 과거이므로 missed (단, long_session_flag가 있으면 completed는 위에서 처리됨)
          status = DayStatusType.missed;
        } else if (isFutureWeek) {
          // 미래 주: 모든 날은 upcoming
          status = DayStatusType.upcoming;
        } else {
          status = DayStatusType.upcoming;
        }
      }

      dayStatuses.add(_DayStatus(
        weekday: weekdays[i],
        date: currentDay.day,
        status: status,
      ));
    }

    return dayStatuses;
  }

  Widget _buildStatusIcon(DayStatusType status) {
    const double containerSize = 36.0; // 원 크기 고정

    switch (status) {
      case DayStatusType.completed:
        return Container(
          width: containerSize,
          height: containerSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueAccent,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 24,
          ),
        );
      case DayStatusType.missed:
        return Container(
          width: containerSize,
          height: containerSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.redAccent,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 20,
          ),
        );
      case DayStatusType.upcoming:
        return Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background(context),
            border: Border.all(
              color: Colors.grey.shade300, // 더 밝은 회색
              width: 1.0,
            ),
          ),
          // 선택적으로 중앙에 특수 아이콘 추가
        );
      case DayStatusType.notAvailable:
        return Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.backgroundSecondary(context),
          ),
        );
    }
  }
}

enum DayStatusType {
  completed, // long_session_flag가 있는 날
  missed, // 활동을 놓친 날
  upcoming, // 아직 도래하지 않은 날
  notAvailable, // 앱 설치 전이라 데이터가 없는 경우
}

class _DayStatus {
  final String weekday;
  final int date;
  final DayStatusType status;

  _DayStatus({
    required this.weekday,
    required this.date,
    required this.status,
  });
}
