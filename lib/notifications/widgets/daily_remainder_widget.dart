import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/notifications/widgets/activity_completion_widget.dart';
import 'package:project1/notifications/widgets/activity_remainder_widget.dart';
import 'package:project1/notifications/widgets/break_completion_widget.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class DailyRemainderWidget extends StatefulWidget {
  const DailyRemainderWidget({super.key});

  @override
  State<DailyRemainderWidget> createState() => _DailyRemainderWidgetState();
}

class _DailyRemainderWidgetState extends State<DailyRemainderWidget> {
  void _showNotificationBottomSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text('취소'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: Text('저장'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 시간 피커
            Container(
              height: 150,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                onDateTimeChanged: (DateTime time) {},
              ),
            ),

            // 요일 선택
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('반복', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['월', '화', '수', '목', '금', '토', '일']
                        .map(
                          (day) => Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(day, style: TextStyle(color: Colors.white, fontSize: 14)),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

            // 활동 선택
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('활동', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('활동 선택'),
                        Icon(CupertinoIcons.chevron_right, size: 16),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.paddingSM,
      decoration: BoxDecoration(color: AppColors.background(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '데일리 리마인더',
                style: AppTextStyles.getTitle(context),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showNotificationBottomSheet();
                },
                child: Icon(
                  LucideIcons.plus,
                  size: context.lg,
                ),
              ),
            ],
          ),
          SizedBox(height: context.hp(2)),
        ],
      ),
    );
  }
}
