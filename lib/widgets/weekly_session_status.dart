import 'package:flutter/material.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/database_service.dart';
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
  List<Map<String, dynamic>> sessions = [];
  bool isLoading = true;
  late StatsProvider _statsProvider;

  @override
  void initState() {
    super.initState();
    _statsProvider = Provider.of<StatsProvider>(context, listen: false);
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    if (!mounted) return;

    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final weeklyData = await _statsProvider.getWeeklySessionFlags();
      print('weeklyData: $weeklyData');

      if (mounted) {
        setState(() {
          sessions = weeklyData;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading session data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<_DayStatus> _calculateDayStatuses() {
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    List<_DayStatus> dayStatuses = [];
    List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    if (sessions.isEmpty) {
      return List.generate(7, (i) {
        DateTime currentDay = monday.add(Duration(days: i));
        return _DayStatus(
          weekday: weekdays[i],
          date: currentDay.day,
          status: DayStatusType.upcoming,
        );
      });
    }
    for (int i = 0; i < 7; i++) {
      DateTime currentDay = monday.add(Duration(days: i));
      bool isToday = currentDay.day == now.day && currentDay.month == now.month && currentDay.year == now.year;

      // 해당 날짜의 세션들 찾기
      List<Map<String, dynamic>> daySessions = sessions.where((session) {
        DateTime sessionDate = DateTime.parse(session['start_time']);
        return sessionDate.year == currentDay.year && sessionDate.month == currentDay.month && sessionDate.day == currentDay.day;
      }).toList();

      // long_session_flag가 있는지 확인
      bool hasLongSession = daySessions.any((session) => session['long_session_flag'] == 1);

      DayStatusType status;
      if (hasLongSession) {
        status = DayStatusType.completed; // 체크 완료
      } else if (currentDay.isAfter(now)) {
        status = DayStatusType.upcoming; // 미래
      } else {
        // 여기서 currentDay <= now 인 상태
        // 만약 currentDay가 '오늘'이고 아직 자정 전이면?
        if (isToday && now.hour < 24) {
          // 원하는 로직대로라면 "WAIT"
          status = DayStatusType.upcoming;
        } else {
          // 이미 날짜가 지났거나, 세션이 없으면 missed
          status = DayStatusType.missed;
        }
      }

      dayStatuses.add(_DayStatus(
        weekday: weekdays[i],
        date: currentDay.day,
        status: status,
      ));

      print('status : $status');
    }
    print('dayStatuses : $dayStatuses');

    return dayStatuses;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final dayStatuses = _calculateDayStatuses();

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
                    Text('이번 주 현황', style: AppTextStyles.getTitle(context)),
                    IconButton(
                      icon: Icon(Icons.refresh, size: context.xl),
                      onPressed: _loadSessionData,
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

// 나머지 enum과 _DayStatus 클래스는 동일

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
