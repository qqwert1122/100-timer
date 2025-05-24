import 'package:flutter/material.dart';
import 'package:project1/daily_report/widgets/daily_report_card_title.dart';
import 'package:project1/daily_report/widgets/data_insufficient_widget.dart';
import 'package:project1/daily_report/widgets/seven_day_streak_widget.dart';
import 'package:project1/daily_report/widgets/total_activity_summary_widget.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class RatioCard916 extends StatefulWidget {
  final double width;
  final double height;
  final DateTime selectedDate;
  final bool isDataInsufficient;
  final int totalSeconds;
  final Map<String, Map<String, dynamic>> activityTimes;
  final List<Map<String, dynamic>> activities;
  final List<int> sevenDayTimes;
  final List<Map<String, dynamic>> hourlyData;
  final Map<String, dynamic> comparisonData;
  final int currentSteak;

  const RatioCard916({
    required this.width,
    required this.height,
    required this.selectedDate,
    required this.isDataInsufficient,
    required this.totalSeconds,
    required this.activityTimes,
    required this.activities,
    required this.sevenDayTimes,
    required this.hourlyData,
    required this.comparisonData,
    required this.currentSteak,
    super.key,
  });

  @override
  State<RatioCard916> createState() => _RatioCard916State();
}

class _RatioCard916State extends State<RatioCard916> {
  late final TimerProvider timerProvider;

  @override
  void initState() {
    super.initState();
    timerProvider = Provider.of<TimerProvider>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) {
      return '$hours시간 $minutes분';
    } else if (hours > 0) {
      return '$hours시간';
    } else {
      return '$minutes분';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.background(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: context.paddingSM,
        child: Column(
          children: [
            DailyReportCardTitle(
              selectedDate: widget.selectedDate,
              ratio: '9:16',
            ),
            Expanded(
              child: widget.isDataInsufficient
                  ? Center(child: DataInsufficientWidget())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              _formatTime(widget.totalSeconds),
                              style: AppTextStyles.getHeadline(context).copyWith(
                                fontFamily: 'Neo',
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(width: context.wp(2)),
                            Text(
                              widget.comparisonData['displayText'] ?? '',
                              style: AppTextStyles.getCaption(context).copyWith(
                                color: (widget.comparisonData['isIncrease'] ?? false) ? Colors.redAccent : Colors.blueAccent,
                                letterSpacing: -0.3,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        TotalActivitySummaryWidget(
                          ratio: '9:16',
                          hourlyData: widget.hourlyData,
                          activityTimes: widget.activityTimes,
                        ),
                        SizedBox(height: context.hp(4)),
                        Padding(
                          padding: context.paddingSM,
                          child: SevenDayStreakWidget(
                            dailyTimes: widget.sevenDayTimes,
                            selectedDate: widget.selectedDate,
                            currentStreak: widget.currentSteak,
                            ratio: '9:16',
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
