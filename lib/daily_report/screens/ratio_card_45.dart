import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/daily_report/widgets/daily_report_card_title.dart';
import 'package:project1/daily_report/widgets/data_insufficient_widget.dart';
import 'package:project1/daily_report/widgets/seven_day_streak_widget.dart';
import 'package:project1/daily_report/widgets/total_activity_summary_widget.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class RatioCard45 extends StatefulWidget {
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

  const RatioCard45({
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
  State<RatioCard45> createState() => _RatioCard45State();
}

class _RatioCard45State extends State<RatioCard45> {
  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString();
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    return '$hours시간 $minutes분';
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DailyReportCardTitle(
              selectedDate: widget.selectedDate,
              ratio: '4:5',
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
                          ratio: '4:5',
                          hourlyData: widget.hourlyData,
                          activityTimes: widget.activityTimes,
                        ),
                        SizedBox(height: context.hp(2)),
                        SevenDayStreakWidget(
                          dailyTimes: widget.sevenDayTimes,
                          selectedDate: widget.selectedDate,
                          currentStreak: widget.currentSteak,
                          ratio: '4:5',
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
