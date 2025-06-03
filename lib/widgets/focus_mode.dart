import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/notification_service.dart';
import 'package:project1/utils/prefs_service.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:showcaseview/showcaseview.dart';

class FocusMode extends StatefulWidget {
  final Map<String, dynamic> timerData;

  const FocusMode({super.key, required this.timerData});

  static final GlobalKey countKey = GlobalKey(debugLabel: 'focusMode');

  @override
  State<FocusMode> createState() => _FocusModeState();
}

class _FocusModeState extends State<FocusMode> with TickerProviderStateMixin {
  late final StatsProvider _statsProvider;

  List<Map<String, dynamic>> pomodoroItems = [
    {
      'title': '30',
      'value': 1800,
      'maxCount': 5,
      'currentCount': 0,
      'gradientColors': [Colors.greenAccent, Colors.yellow],
    },
    {
      'title': '1',
      'value': 3600,
      'maxCount': 5,
      'currentCount': 0,
      'gradientColors': [Colors.yellowAccent, Colors.pink],
    },
    {
      'title': '2',
      'value': 7200,
      'maxCount': 5,
      'currentCount': 0,
      'gradientColors': [Colors.blueAccent, Colors.lime],
    },
    {
      'title': '4',
      'value': 14400,
      'maxCount': 5,
      'currentCount': 0,
      'gradientColors': [Colors.amber, Colors.red],
    },
  ];

  // Onboarding flag
  bool _needShowOnboarding = false;

  // Onboarding GlobalKey
  final GlobalKey _valueKey = GlobalKey();
  final _countKey = FocusMode.countKey;

  @override
  void initState() {
    super.initState();
    _statsProvider = Provider.of<StatsProvider>(context, listen: false);
    _initPomodoroCounts();

    _needShowOnboarding = !PrefsService().getOnboarding('focusMode');
    if (_needShowOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return; // 위젯이 살아 있을 때만
            ShowCaseWidget.of(context).startShowCase([
              _valueKey,
              _countKey,
            ]);
          });
        },
      );
    }
  }

  Future<void> _initPomodoroCounts() async {
    final updatedItems = List<Map<String, dynamic>>.from(pomodoroItems);

    for (var item in updatedItems) {
      final targetDuration = item['value'] as int;
      final count = await _statsProvider.getCompletedFocusMode(targetDuration);
      item['currentCount'] = count;
    }

    if (mounted) {
      // 위젯이 빌드 트리에 있는지 확인
      setState(() {
        pomodoroItems = updatedItems;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);

    return SingleChildScrollView(
      child: Padding(
        padding: context.paddingHorizSM,
        child: _buildPomodoroMenu(timerProvider),
      ),
    );
  }

  Widget _buildPomodoroMenu(TimerProvider timerProvider) {
    Widget buildCountIndicator(int maxCount, int currentCount) {
      return Row(
        children: List.generate(
          maxCount,
          (index) => Padding(
            padding: EdgeInsets.only(right: context.wp(1)),
            child: Container(
              width: context.wp(2),
              height: context.wp(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < currentCount ? Colors.white : Colors.white.withValues(alpha: 0.3),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.7,
          ),
          itemCount: pomodoroItems.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final item = pomodoroItems[index];

            Widget card = Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: item['gradientColors'],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: context.paddingSM,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              item['title'],
                              style: AppTextStyles.getTimeDisplay(context).copyWith(
                                color: Colors.white,
                                fontFamily: 'chab',
                              ),
                            ),
                            SizedBox(width: context.wp(1)),
                            Text(
                              index == 0 ? '분' : '시간',
                              style: AppTextStyles.getBody(context).copyWith(
                                fontWeight: FontWeight.w200,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        index == 0
                            ? Showcase(
                                key: _countKey,
                                description: '해당 주차에 집중한 횟수를 표시해요',
                                targetBorderRadius: BorderRadius.circular(16),
                                targetPadding: context.paddingXS,
                                targetShapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                overlayOpacity: 0.5,
                                child: buildCountIndicator(
                                  item['maxCount'],
                                  item['currentCount'],
                                ),
                              )
                            : buildCountIndicator(
                                item['maxCount'],
                                item['currentCount'],
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            if (index == 0) {
              card = Showcase(
                key: _valueKey,
                description: '정해진 시간 동안 집중하는 모드에요',
                overlayOpacity: 0.5,
                targetBorderRadius: BorderRadius.circular(16),
                child: card,
              );
            }

            return GestureDetector(
              onTap: () async {
                HapticFeedback.lightImpact();
                await FacebookAppEvents().logEvent(
                  name: 'timer_start',
                  parameters: {
                    'mode': 'focus',
                    'target': item['value'] as int,
                    'activity': timerProvider.currentActivityName,
                    'isWeeklyTargetExceeded': timerProvider.isWeeklyTargetExceeded,
                  },
                  valueToSum: 5,
                );
                final int target = item['value'] as int; // 초 단위
                try {
                  await timerProvider.startTimer(
                    activityId: timerProvider.currentActivityId!,
                    mode: 'PMDR',
                    targetDuration: target,
                  );
                } catch (e) {
                  Fluttertoast.showToast(
                    msg: "타이머 시작 중 오류가 발생했습니다",
                    gravity: ToastGravity.TOP,
                    backgroundColor: Colors.redAccent.shade200,
                    textColor: Colors.white,
                    fontSize: context.md,
                  );
                  return;
                }
                // 페이지 전환 (TimerRunningPage는 그리기 전용)
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const TimerRunningPage(
                      isNewSession: true,
                    ),
                  ),
                );
              },
              child: card,
            );
          },
        ),
      ],
    );
  }
}
