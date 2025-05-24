import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:shimmer/shimmer.dart';

class SevenDayStreakWidget extends StatelessWidget {
  final List<int> dailyTimes; // 7일간의 각 일별 시간(초)
  final DateTime selectedDate;
  final int currentStreak;
  final String ratio;

  const SevenDayStreakWidget({
    required this.dailyTimes,
    required this.selectedDate,
    required this.currentStreak,
    required this.ratio,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final date = selectedDate.subtract(Duration(days: 6 - index));
            final weekday = weekdays[date.weekday - 1];
            final hasActivity = dailyTimes.isNotEmpty && index < dailyTimes.length && dailyTimes[index] > 0;
            return Column(
              children: [
                Text(
                  weekday,
                  style: AppTextStyles.getCaption(context),
                ),
                SizedBox(height: context.hp(1)),
                Container(
                  width: ratio == '4:5' ? 30 : 25,
                  height: ratio == '4:5' ? 30 : 25,
                  decoration: BoxDecoration(
                    color: hasActivity ? Colors.blueAccent : AppColors.backgroundSecondary(context),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: hasActivity ? Icon(LucideIcons.check, color: Colors.white, size: 16) : null,
                  ),
                ),
              ],
            );
          }),
        ), // Streak 표시
        SizedBox(height: context.hp(1)),
        Shimmer.fromColors(
          baseColor: Colors.blueAccent,
          highlightColor: Colors.deepPurple,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$currentStreak일 연속 활동중',
                style: AppTextStyles.getTitle(context).copyWith(
                  color: Colors.blueAccent,
                  fontSize: ratio == '4:5' ? context.lg : context.md,
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
      ],
    );
  }
}
