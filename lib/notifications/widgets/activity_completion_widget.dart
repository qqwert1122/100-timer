import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class ActivityCompletionWidget extends StatefulWidget {
  const ActivityCompletionWidget({super.key});

  @override
  State<ActivityCompletionWidget> createState() => _ActivityCompletionWidgetState();
}

class _ActivityCompletionWidgetState extends State<ActivityCompletionWidget> {
  bool _isActivityCompletionEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '활동 완료',
                  style: AppTextStyles.getBody(context).copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '활동 완료 시 알려줘요',
                  style: AppTextStyles.getBody(context).copyWith(color: AppColors.textSecondary(context)),
                ),
              ],
            ),
            CupertinoSwitch(
              value: _isActivityCompletionEnabled,
              onChanged: (bool value) async {
                HapticFeedback.lightImpact();
                setState(() {
                  _isActivityCompletionEnabled = !_isActivityCompletionEnabled;
                });
              },
              activeTrackColor: AppColors.primary(context),
              inactiveTrackColor: AppColors.backgroundSecondary(context),
            ),
          ],
        ),
        SizedBox(height: context.hp(2)),
      ],
    );
  }
}
