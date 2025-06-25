import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class ActivityRemainderWidget extends StatefulWidget {
  const ActivityRemainderWidget({super.key});

  @override
  State<ActivityRemainderWidget> createState() => _ActivityRemainderWidgetState();
}

class _ActivityRemainderWidgetState extends State<ActivityRemainderWidget> {
  bool _isActivityReminderEnabled = false;
  int _activityReminderInterval = 1;

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
                  '활동중',
                  style: AppTextStyles.getBody(context).copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${_activityReminderInterval}시간마다 알려줘요',
                  style: AppTextStyles.getBody(context).copyWith(color: AppColors.textSecondary(context)),
                ),
              ],
            ),
            CupertinoSwitch(
              value: _isActivityReminderEnabled,
              onChanged: (bool value) async {
                HapticFeedback.lightImpact();
                setState(() {
                  _isActivityReminderEnabled = !_isActivityReminderEnabled;
                });
              },
              activeTrackColor: AppColors.primary(context),
              inactiveTrackColor: AppColors.backgroundSecondary(context),
            ),
          ],
        ),
        SizedBox(height: context.hp(2)),
        if (_isActivityReminderEnabled)
          Column(
            children: [
              Row(
                children: [1, 2, 3, 4].map((hour) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: context.xs),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _activityReminderInterval = hour;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: context.xs),
                          decoration: BoxDecoration(
                            color: _activityReminderInterval == hour ? AppColors.primary(context) : AppColors.backgroundSecondary(context),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '$hour시간',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.getCaption(context).copyWith(
                              color: _activityReminderInterval == hour ? AppColors.background(context) : AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: context.hp(2)),
            ],
          ),
      ],
    );
  }
}
