import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/notifications/screens/alarm_page.dart';
import 'package:project1/screens/subscription_bottom_sheet.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:project1/widgets/total_seconds_cards.dart';
import 'package:provider/provider.dart';

class TimerPageHeader extends StatefulWidget {
  const TimerPageHeader({super.key});

  @override
  State<TimerPageHeader> createState() => _TimerPageHeaderState();
}

class _TimerPageHeaderState extends State<TimerPageHeader> {
  late final TimerProvider _timerProvider;
  int totalSeconds = 100;

  @override
  void initState() {
    super.initState();
    _timerProvider = Provider.of<TimerProvider>(context, listen: false);
    final _totalSeconds = _timerProvider.timerData!['total_seconds'] ?? 360000;
    totalSeconds = (_totalSeconds / 3600).toInt();
  }

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
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        final totalSeconds = timerProvider.timerData != null ? (timerProvider.timerData!['total_seconds'] / 3600).toInt() : 100; // 기본값

        return Padding(
          padding: EdgeInsets.symmetric(vertical: context.xs, horizontal: context.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await FacebookAppEvents().logEvent(
                    name: 'open_total_seconds',
                    valueToSum: 1,
                  );
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return const TotalSecondsCards();
                      });
                },
                child: Row(
                  children: [
                    Text(
                      '목표 시간',
                      style: AppTextStyles.getBody(context).copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    SizedBox(width: context.wp(2)),
                    Text(
                      '${totalSeconds}h',
                      style: AppTextStyles.getTitle(context).copyWith(
                        fontWeight: FontWeight.w900,
                        fontFamily: 'neo',
                      ),
                    ),
                    SizedBox(width: context.wp(1)),
                    Icon(
                      LucideIcons.chevronDown,
                      size: context.lg,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Stack(
                  //   alignment: Alignment.center,
                  //   clipBehavior: Clip.none,
                  //   children: [
                  //     GestureDetector(
                  //       onTap: () {
                  //         HapticFeedback.lightImpact();
                  //         Navigator.push(
                  //           context,
                  //           MaterialPageRoute(
                  //             builder: (context) => const AlarmPage(),
                  //           ),
                  //         );
                  //       },
                  //       child: Image.asset(
                  //         getIconImage('bell'),
                  //         width: context.xl,
                  //         height: context.xl,
                  //         errorBuilder: (context, error, stackTrace) {
                  //           // 이미지를 로드하는 데 실패한 경우의 대체 표시
                  //           return Container(
                  //             width: context.xl,
                  //             height: context.xl,
                  //             color: Colors.grey.withValues(alpha: 0.2),
                  //             child: Icon(
                  //               Icons.broken_image,
                  //               size: context.xl,
                  //               color: Colors.grey,
                  //             ),
                  //           );
                  //         },
                  //       ),
                  //     ),
                  //     Positioned(
                  //       bottom: 0,
                  //       right: -5,
                  //       child: GestureDetector(
                  //         onTap: () {
                  //           HapticFeedback.lightImpact();
                  //         },
                  //         child: Icon(
                  //           Icons.settings_rounded,
                  //           size: context.md,
                  //           color: Colors.grey,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  // GestureDetector(
                  //   onTap: () {
                  //     HapticFeedback.lightImpact();
                  //     _showSubscriptionPage();
                  //   },
                  //   child: Icon(
                  //     LucideIcons.crown,
                  //     size: context.xl,
                  //   ),
                  // ),
                  // SizedBox(width: context.wp(6)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
