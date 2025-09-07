import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/notification_service.dart';
import 'package:project1/utils/prefs_service.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/time_formatter.dart';
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

  int _customDuration = 3600;

  List<Map<String, dynamic>> pomodoroItems = [
    {
      'title': '30',
      'value': 1800,
      'maxCount': 5,
      'currentCount': 0,
      'gradientColors': [Colors.greenAccent, Colors.yellow],
      'isCustom': false,
    },
    {
      'title': '1',
      'value': 3600,
      'maxCount': 5,
      'currentCount': 0,
      'gradientColors': [Colors.yellowAccent, Colors.pink],
      'isCustom': false,
    },
    {
      'title': '2',
      'value': 7200,
      'maxCount': 5,
      'currentCount': 0,
      'gradientColors': [Colors.blueAccent, Colors.lime],
      'isCustom': false,
    },
    {
      'title': '커스텀 모드',
      'value': 0,
      'maxCount': 0,
      'currentCount': 0,
      'gradientColors': [Colors.amber, Colors.red],
      'isCustom': true,
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
    _customDuration = PrefsService().customDuration;
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

  void _showCustomTimeModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildTimePickerModal(),
    );
  }

  Widget _buildTimePickerModal() {
    int selectedHour = (_customDuration / 3600).floor();
    int selectedMinute = ((_customDuration % 3600) / 60).floor();

    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        height: 350,
        padding: context.paddingSM,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.background(context),
        ),
        child: Column(
          children: [
            Text('시간 선택', style: AppTextStyles.getTitle(context)),
            SizedBox(height: context.hp(2)),
            Expanded(
              child: Row(
                children: [
                  // 시간 피커
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                          initialItem: selectedHour),
                      itemExtent: 40,
                      onSelectedItemChanged: (int index) {
                        setModalState(() {
                          selectedHour = index;
                          _customDuration =
                              (selectedHour * 3600) + (selectedMinute * 60);
                        });
                      },
                      children: List.generate(24, (index) {
                        bool isSelected = selectedHour == index;
                        return Center(
                          child: Text(
                            '${index}시간',
                            style: AppTextStyles.getBody(context).copyWith(
                              color: isSelected
                                  ? AppColors.textPrimary(context)
                                  : AppColors.textSecondary(context),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  // 분 피커
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                          initialItem: selectedMinute),
                      itemExtent: 40,
                      onSelectedItemChanged: (int index) {
                        setModalState(() {
                          selectedMinute = index;
                          _customDuration =
                              (selectedHour * 3600) + (selectedMinute * 60);
                        });
                      },
                      children: List.generate(60, (index) {
                        bool isSelected = selectedMinute == index;
                        return Center(
                          child: Text(
                            '${index}분',
                            style: AppTextStyles.getBody(context).copyWith(
                              color: isSelected
                                  ? AppColors.textPrimary(context)
                                  : AppColors.textSecondary(context),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.hp(2)),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startCustomTimer(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: context.paddingXS,
                    ),
                    child: Padding(
                      padding: context.paddingXS,
                      child: Text(
                        '시작',
                        style: AppTextStyles.getBody(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startCustomTimer() async {
    if (_customDuration <= 0) {
      Fluttertoast.showToast(
        msg: "시간을 선택해주세요",
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.redAccent.shade200,
        textColor: Colors.white,
        fontSize: context.md,
      );
      return;
    }

    Navigator.pop(context);

    // 커스텀 시간 저장
    PrefsService().customDuration = _customDuration;

    final timerProvider = Provider.of<TimerProvider>(context, listen: false);

    HapticFeedback.lightImpact();
    await FacebookAppEvents().logEvent(
      name: 'timer_start',
      parameters: {
        'mode': 'focus',
        'target': _customDuration,
        'activity': timerProvider.currentActivityName,
        'isWeeklyTargetExceeded': timerProvider.isWeeklyTargetExceeded,
      },
      valueToSum: 5,
    );

    try {
      await timerProvider.startTimer(
        activityId: timerProvider.currentActivityId!,
        mode: 'PMDR',
        targetDuration: _customDuration,
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

    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const TimerRunningPage(isNewSession: true),
      ),
    );
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
                color: index < currentCount
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
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
                            index == 3
                                ? Text(
                                    '커스텀',
                                    style:
                                        AppTextStyles.getBody(context).copyWith(
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    item['title'],
                                    style: AppTextStyles.getTimeDisplay(context)
                                        .copyWith(
                                      color: Colors.white,
                                      fontFamily: 'chab',
                                    ),
                                  ),
                            SizedBox(width: context.wp(1)),
                            index == 3
                                ? Container()
                                : Text(
                                    index == 0 ? '분' : '시간',
                                    style:
                                        AppTextStyles.getBody(context).copyWith(
                                      fontWeight: FontWeight.w200,
                                      color: Colors.white,
                                    ),
                                  ),
                          ],
                        ),
                        index == 3
                            ? Column(
                                children: [
                                  SizedBox(height: context.hp(1)),
                                  Text(
                                    formatTime(_customDuration),
                                    style: AppTextStyles.getTitle(context)
                                        .copyWith(
                                      color: Colors.white,
                                      fontFamily: 'Neo',
                                    ),
                                  ),
                                ],
                              )
                            : Container(),
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
                if (item['isCustom']) {
                  _showCustomTimeModal();
                  return;
                }

                HapticFeedback.lightImpact();
                await FacebookAppEvents().logEvent(
                  name: 'timer_start',
                  parameters: {
                    'mode': 'focus',
                    'target': item['value'] as int,
                    'activity': timerProvider.currentActivityName,
                    'isWeeklyTargetExceeded':
                        timerProvider.isWeeklyTargetExceeded,
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
