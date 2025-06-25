import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class BreakCompletionWidget extends StatefulWidget {
  const BreakCompletionWidget({super.key});

  @override
  State<BreakCompletionWidget> createState() => _BreakCompletionWidgetState();
}

class _BreakCompletionWidgetState extends State<BreakCompletionWidget> {
  bool _isBreakCompletionEnabled = false;

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
                  '휴식 완료',
                  style: AppTextStyles.getBody(context).copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '휴식 종료 시 알려줘요',
                  style: AppTextStyles.getBody(context).copyWith(color: AppColors.textSecondary(context)),
                ),
              ],
            ),
            CupertinoSwitch(
              value: _isBreakCompletionEnabled,
              onChanged: (bool value) async {
                HapticFeedback.lightImpact();
                setState(() {
                  _isBreakCompletionEnabled = !_isBreakCompletionEnabled;
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
