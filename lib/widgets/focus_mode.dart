import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/responsive_size.dart';

class FocusMode extends StatefulWidget {
  final Map<String, dynamic> timerData;

  const FocusMode({super.key, required this.timerData});

  @override
  State<FocusMode> createState() => _FocusModeState();
}

class _FocusModeState extends State<FocusMode> with TickerProviderStateMixin {
  late final StatsProvider _statsProvider;
  List<Map<String, dynamic>> pomodoroItems = [
    {
      'title': '10',
      'value': 15,
      'maxCount': 3,
      'currentCount': 0,
      'gradientColors': [Colors.greenAccent, Colors.yellow],
    },
    {
      'title': '30',
      'value': 1800,
      'maxCount': 3,
      'currentCount': 0,
      'gradientColors': [Colors.yellowAccent, Colors.pink],
    },
    {
      'title': '1',
      'value': 3600,
      'maxCount': 3,
      'currentCount': 0,
      'gradientColors': [Colors.blueAccent, Colors.lime],
    },
    {
      'title': '2',
      'value': 7200,
      'maxCount': 3,
      'currentCount': 0,
      'gradientColors': [Colors.amber, Colors.red],
    },
  ];

  @override
  void initState() {
    super.initState();
    _statsProvider = Provider.of<StatsProvider>(context, listen: false); // DatabaseService 주입
    _initPomodoroCounts();
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
                color: index < currentCount ? Colors.white : Colors.white.withOpacity(0.3),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
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

            return GestureDetector(
              onTap: () async {
                await Future.delayed(const Duration(milliseconds: 100));
                timerProvider.setSessionModeAndTargetDuration(mode: 'PMDR', targetDuration: item['value']);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => TimerRunningPage(
                      timerData: widget.timerData,
                      isNewSession: true,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: item['gradientColors'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
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
                                style: TextStyle(
                                  fontSize: context.lg * 2,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  fontFamily: 'chab',
                                ),
                              ),
                              SizedBox(width: context.wp(1)),
                              Text(
                                index <= 1 ? '분' : '시간',
                                style: TextStyle(
                                  fontSize: context.sm,
                                  fontWeight: FontWeight.w200,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          buildCountIndicator(
                            item['maxCount'],
                            item['currentCount'],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
