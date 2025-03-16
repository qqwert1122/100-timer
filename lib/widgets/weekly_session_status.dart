import 'package:flutter/material.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/responsive_size.dart';

class WeeklySessionStatus extends StatefulWidget {
  final bool isSimple;

  const WeeklySessionStatus({super.key, required this.isSimple});

  @override
  State<WeeklySessionStatus> createState() => _WeeklySessionStatusState();
}

class _WeeklySessionStatusState extends State<WeeklySessionStatus> {
  final DateTime now = DateTime.now();

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
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '데이터를 불러오는 중 오류가 발생했습니다',
                  style: AppTextStyles.getCaption(context).copyWith(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  '이 주에 기록된 데이터가 없습니다',
                  style: AppTextStyles.getCaption(context),
                ),
              );
            }

            final sessions = snapshot.data!;
            final dayStatuses = _calculateDayStatuses(statsProvider, sessions);

            return Container(
              padding: context.paddingSM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.isSimple
                      ? Container()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('집중 달성한 날', style: AppTextStyles.getTitle(context)),
                            IconButton(
                              icon: Icon(Icons.refresh, size: context.xl),
                              onPressed: () {
                                // Future를 새로 가져오도록 setState 호출
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                  widget.isSimple
                      ? Container()
                      : Text(
                          '1시간 이상 집중한 날은 달성 표시가 돼요',
                          style: AppTextStyles.getCaption(context),
                        ),
                  SizedBox(height: context.hp(widget.isSimple ? 0 : 3)),
                  Container(
                    padding: context.paddingSM,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.backgroundSecondary(context),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 2,
                          spreadRadius: 3,
                          color: Colors.grey.shade200,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: dayStatuses.map((status) {
                        return Column(
                          children: [
                            Text(status.weekday, style: AppTextStyles.getCaption(context)),
                            SizedBox(height: context.hp(1)),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade700 : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: _buildStatusIcon(status.status),
                              ),
                            ),
                            const SizedBox(height: 4),
                            widget.isSimple
                                ? Container()
                                : Text(
                                    '${status.date}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: status.status == DayStatusType.upcoming
                                          ? isDarkMode
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade400
                                          : isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
      bool isToday = isCurrentWeek && currentDay.year == now.year && currentDay.month == now.month && currentDay.day == now.day;

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
        if (isCurrentWeek) {
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
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
        );
    }
  }
}

enum DayStatusType {
  completed, // 체크 표시 (long_session_flag가 있는 경우)
  missed, // X 표시 (활동하지 않고 지난 날)
  upcoming, // 빈 원 (아직 도래하지 않은 날)
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
