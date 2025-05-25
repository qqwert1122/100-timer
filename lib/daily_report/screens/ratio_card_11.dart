import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/daily_report/widgets/daily_report_card_title.dart';
import 'package:project1/daily_report/widgets/data_insufficient_widget.dart';
import 'package:project1/daily_report/widgets/seven_day_streak_widget.dart';
import 'package:project1/daily_report/widgets/total_activity_summary_widget.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:shimmer/shimmer.dart';

class RatioCard11 extends StatefulWidget {
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

  const RatioCard11({
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
  State<RatioCard11> createState() => _RatioCard11State();
}

class _RatioCard11State extends State<RatioCard11> {
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
          children: [
            DailyReportCardTitle(
              selectedDate: widget.selectedDate,
              ratio: '1:1',
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
                          ratio: '1:1',
                          hourlyData: widget.hourlyData,
                          activityTimes: widget.activityTimes,
                        ),
                        SizedBox(height: context.hp(2)),
                        Shimmer.fromColors(
                          baseColor: Colors.blueAccent,
                          highlightColor: Colors.deepPurple,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${widget.currentSteak}일 연속 활동중',
                                style: AppTextStyles.getTitle(context).copyWith(
                                  color: Colors.blueAccent,
                                ),
                              ),
                              SizedBox(width: context.wp(2)),
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
                                    '1시간 이상 활동하면 이어져요',
                                    style: TextStyle(
                                      color: AppColors.background(context),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                child: Icon(
                                  LucideIcons.info,
                                  size: context.lg,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '타이머100',
                            style: AppTextStyles.getCaption(context).copyWith(
                              color: AppColors.textSecondary(context).withValues(alpha: 0.2),
                              letterSpacing: -0.3,
                              height: 1.0,
                              fontFamily: 'Neo',
                            ),
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
