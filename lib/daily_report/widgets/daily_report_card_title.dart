import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project1/daily_report/widgets/app_icon_avatar.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class DailyReportCardTitle extends StatelessWidget {
  final String ratio;
  final DateTime selectedDate;

  const DailyReportCardTitle({
    required this.ratio,
    required this.selectedDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
    final dayName = dayNames[selectedDate.weekday % 7];
    final dateFormatter = DateFormat('M월 d일');
    final yearFormatter = DateFormat('yyyy년');
    final date = dateFormatter.format(selectedDate);
    final year = yearFormatter.format(selectedDate);

    final TextStyle dayNameStyles = ratio == '4:5'
        ? AppTextStyles.getHeadline(context).copyWith(
            fontFamily: 'Neo',
            fontSize: context.xxl,
            color: AppColors.textSecondary(context),
          )
        : ratio == '1:1'
            ? AppTextStyles.getTitle(context).copyWith(
                fontFamily: 'Neo',
                color: AppColors.textSecondary(context),
              )
            : AppTextStyles.getTitle(context).copyWith(
                fontFamily: 'Neo',
                color: AppColors.textSecondary(context),
              );

    final TextStyle dateStyles = ratio == '4:5'
        ? AppTextStyles.getTitle(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context),
          )
        : ratio == '1:1'
            ? AppTextStyles.getBody(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(context),
              )
            : AppTextStyles.getCaption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(context),
              );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayName,
          style: dayNameStyles,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(date, style: dateStyles),
            Text(
              year,
              style: ratio == '9:16'
                  ? AppTextStyles.getCaption(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary(context),
                    )
                  : AppTextStyles.getBody(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary(context),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
