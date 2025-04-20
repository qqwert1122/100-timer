import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/screens/setting_page.dart';
import 'package:project1/screens/subscription_bottom_sheet.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';

class TimerPageHeader extends StatefulWidget {
  const TimerPageHeader({super.key});

  @override
  State<TimerPageHeader> createState() => _TimerPageHeaderState();
}

class _TimerPageHeaderState extends State<TimerPageHeader> {
  void _showSubscriptionPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const SubscriptionBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  "100 timer",
                  // _statsProvider!.getCurrentWeekLabel().toString(),
                  style: AppTextStyles.getTitle(context).copyWith(
                    fontFamily: 'Neo',
                  ),
                ),
                Image.asset(
                  getIconImage('fire'),
                  width: context.xl,
                  height: context.xl,
                  errorBuilder: (context, error, stackTrace) {
                    // 이미지를 로드하는 데 실패한 경우의 대체 표시
                    return Container(
                      width: context.xl,
                      height: context.xl,
                      color: Colors.grey.withOpacity(0.2),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        size: context.xl,
                        color: Colors.grey,
                      ),
                    );
                  },
                )
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showSubscriptionPage();
                },
                child: Image.asset(
                  getIconImage('crown'),
                  width: context.wp(8),
                  height: context.wp(8),
                  errorBuilder: (context, error, stackTrace) {
                    // 이미지를 로드하는 데 실패한 경우의 대체 표시
                    return Container(
                      width: context.xl,
                      height: context.xl,
                      color: Colors.grey.withOpacity(0.2),
                      child: Icon(
                        Icons.settings,
                        size: context.xl,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
