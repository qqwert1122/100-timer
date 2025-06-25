import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/notifications/widgets/activity_completion_widget.dart';
import 'package:project1/notifications/widgets/activity_remainder_widget.dart';
import 'package:project1/notifications/widgets/break_completion_widget.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class ActivityNotificationWidget extends StatefulWidget {
  const ActivityNotificationWidget({super.key});

  @override
  State<ActivityNotificationWidget> createState() => _ActivityNotificationWidgetState();
}

class _ActivityNotificationWidgetState extends State<ActivityNotificationWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.paddingSM,
      decoration: BoxDecoration(color: AppColors.background(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '활동 알림',
            style: AppTextStyles.getTitle(context),
          ),
          SizedBox(height: context.hp(2)),
          ActivityRemainderWidget(),
          ActivityCompletionWidget(),
          BreakCompletionWidget(),
        ],
      ),
    );
  }
}
