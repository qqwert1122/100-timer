import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project1/notifications/widgets/activity_completion_widget.dart';
import 'package:project1/notifications/widgets/activity_reminder_widget.dart';
import 'package:project1/notifications/widgets/break_completion_widget.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary(context),
      appBar: AppBar(
        title: Text(
          '알림 설정',
          style: AppTextStyles.getTitle(context),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ActivityReminderWidget(),
            SizedBox(height: context.hp(2)),
            ActivityCompletionWidget(),
            SizedBox(height: context.hp(2)),
            BreakCompletionWidget(),
          ],
        ),
      ),
    );
  }
}
