import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class ActivityReminderWidget extends StatefulWidget {
  const ActivityReminderWidget({super.key});

  @override
  State<ActivityReminderWidget> createState() => _ActivityReminderWidgetState();
}

class _ActivityReminderWidgetState extends State<ActivityReminderWidget> {
  bool _isActivityReminderEnabled = false;
  int _activityReminderInterval = 1;

  // 기본값 1시간
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.paddingSM,
      decoration: BoxDecoration(color: AppColors.background(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '활동중 알림',
                style: AppTextStyles.getTitle(context),
              ),
              Text(
                '활동 중 ${_activityReminderInterval}시간마다 알려줘요',
                style: AppTextStyles.getBody(context).copyWith(color: AppColors.textSecondary(context)),
              ),
            ],
          ),
          SizedBox(height: context.hp(2)),
          Container(
            padding: context.paddingSM,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary(context).withValues(alpha: 0.08), // 그림자 색상
                  blurRadius: 10, // 그림자 흐림 정도
                  offset: const Offset(-2, 8), // 그림자 위치 (가로, 세로)
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/logos/logo_2.png',
                  width: context.xxl,
                  height: context.xxl,
                  errorBuilder: (context, error, stackTrace) {
                    // 이미지를 로드하는 데 실패한 경우의 대체 표시
                    return Container(
                      width: context.xl,
                      height: context.xl,
                      color: Colors.grey.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.broken_image,
                        size: context.xl,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
                SizedBox(width: context.wp(2)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '타이머 100',
                        style: AppTextStyles.getBody(context).copyWith(
                          wordSpacing: -0.3,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        '독서를 1시간째 진행 중이에요!',
                        style: AppTextStyles.getBody(context).copyWith(
                          wordSpacing: -0.3,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _isActivityReminderEnabled,
                  onChanged: (bool value) async {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isActivityReminderEnabled = !_isActivityReminderEnabled;
                    });
                  },
                  activeTrackColor: Colors.redAccent,
                  inactiveTrackColor: Colors.redAccent.withValues(alpha: 0.1),
                ),
              ],
            ),
          ),
          SizedBox(height: context.hp(2)),
          if (_isActivityReminderEnabled)
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
                        padding: EdgeInsets.symmetric(vertical: context.sm),
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
        ],
      ),
    );
  }
}
