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
import 'package:shimmer/shimmer.dart';

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
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AlarmPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: context.paddingXS,
                      decoration: BoxDecoration(
                        color: AppColors.background(context),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary(context).withValues(alpha: 0.08), // 그림자 색상
                            blurRadius: 10, // 그림자 흐림 정도
                            offset: const Offset(-2, 8), // 그림자 위치 (가로, 세로)
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.bell,
                        size: context.lg,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
