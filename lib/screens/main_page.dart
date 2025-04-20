import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/screens/activity_log_page.dart';
import 'package:project1/screens/chart_page.dart';
import 'package:project1/screens/goal_feature_intro_page.dart';
import 'package:project1/screens/setting_page.dart';
import 'package:project1/screens/timer_page.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/utils/responsive_size.dart';
// 다른 페이지용 임포트 추가

class MainPage extends StatefulWidget {
  final Map<String, dynamic> timerData;

  const MainPage({Key? key, required this.timerData}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initPages();
  }

  void _initPages() {
    // 타이머 상태에 따라 첫 번째 탭 페이지 결정
    Widget timerTab;
    if (widget.timerData['timer_state'] != 'STOP') {
      timerTab = TimerRunningPage(
        timerData: widget.timerData,
        isNewSession: false,
      );
    } else {
      timerTab = TimerPage(timerData: widget.timerData);
    }

    // 4개의 탭에 해당하는 페이지들
    _pages = [
      timerTab,
      const ActivityLogPage(),
      GoalFeatureIntroPage(),
      const ChartPage(),
      const SettingPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.2), // 경계선 색상
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

// 임시 페이지 위젯 (실제 구현 전까지 사용)
class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
