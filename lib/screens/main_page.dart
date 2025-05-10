import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/screens/activity_log_page.dart';
import 'package:project1/screens/chart_page.dart';
import 'package:project1/screens/goal_feature_intro_page.dart';
import 'package:project1/screens/setting_page.dart';
import 'package:project1/screens/timer_page.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
// 다른 페이지용 임포트 추가

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final TimerProvider timerProvider;
  int _selectedIndex = 0;
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    timerProvider = Provider.of<TimerProvider>(context, listen: false);
    _initTimer();
  }

  void _initTimer() async {
    Widget timerTab;
    if (timerProvider.timerData!['timer_state'] != 'STOP') {
      // timer_state == 'PAUSED', 'RUNNING'
      timerTab = const TimerRunningPage(
        isNewSession: false,
      );
    } else {
      // timer_state == 'STOP'
      timerTab = TimerPage(timerData: timerProvider.timerData!);
    }

    // 4개의 탭에 해당하는 페이지들
    _pages = [
      timerTab,
      const ActivityLogPage(),
      GoalFeatureIntroPage(),
      const ChartPage(),
      const SettingPage(),
    ];

    setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.grey,
          ),
        ),
      );
    }

    final bool isTimerRunningPage = _pages[_selectedIndex] is TimerRunningPage;

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: isTimerRunningPage
          ? null
          : Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2), // 경계선 색상
                    width: 1,
                  ),
                ),
              ),
              child: ClipRRect(
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: AppColors.background(context),
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  selectedItemColor: AppColors.primary(context),
                  unselectedItemColor: AppColors.textSecondary(context),
                  selectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: context.sm,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: context.sm,
                  ),
                  elevation: 10,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(LucideIcons.timer),
                      label: '타이머',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(LucideIcons.galleryVerticalEnd),
                      label: '기록',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(LucideIcons.flag),
                      label: '목표',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(LucideIcons.lineChart),
                      label: '통계',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(LucideIcons.settings2),
                      label: '설정',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
