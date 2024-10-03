import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';

class ActivityHeatMap extends StatefulWidget {
  @override
  _ActivityHeatMapState createState() => _ActivityHeatMapState();
}

class _ActivityHeatMapState extends State<ActivityHeatMap> {
  Map<DateTime, int> activityData = {};
  DateTime startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  void _loadActivityData() {
    // 예시 데이터: 실제로는 데이터베이스나 상태 관리에서 가져와야 합니다.
    setState(() {
      activityData = {
        DateTime.now().subtract(Duration(days: 3)): 18000, // 5시간
        DateTime.now().subtract(Duration(days: 2)): 36000, // 10시간
        DateTime.now().subtract(Duration(days: 1)): 9000, // 2.5시간
        DateTime.now(): 27000, // 7.5시간
      };
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      startDate = DateTime(startDate.year, startDate.month - 1, 1);
      endDate = DateTime(endDate.year, endDate.month - 1,
          DateTime(endDate.year, endDate.month - 1 + 1, 0).day);
    });
  }

  void _goToNextMonth() {
    setState(() {
      startDate = DateTime(startDate.year, startDate.month + 1, 1);
      endDate = DateTime(endDate.year, endDate.month + 1,
          DateTime(endDate.year, endDate.month + 1 + 1, 0).day);
    });
  }

  // 최대 활동 시간 설정 (예: 10시간)
  final int maxActivityTime = 36000;

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    final locale = Localizations.localeOf(context).toString();

    // 디바이스의 가로 길이
    double deviceWidth = MediaQuery.of(context).size.width;

    // 한 주는 7일이므로, 날짜 칸의 크기를 계산
    double squareSize = (deviceWidth - 32) / 9; // 양쪽 패딩 16씩 제외

    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: HeatMapCalendar(
        initDate: DateTime.now().subtract(Duration(days: 30)),
        datasets: timerProvider.heatMapDataSet.map((date, value) {
          // 활동 시간에 따라 1부터 4까지의 값을 할당
          int level = ((value / 36000) * 4).ceil();
          if (level > 4) level = 4;
          return MapEntry(date, level);
        }),
        colorMode: ColorMode.opacity,
        colorsets: {
          1: Colors.redAccent.shade100,
          2: Colors.redAccent.shade200,
          3: Colors.redAccent.shade400,
          4: Colors.redAccent.shade700,
        },
        defaultColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        textColor: Colors.black87,
        showColorTip: false,
        size: squareSize,
        monthFontSize: 16,
        weekFontSize: 14,
        onClick: (value) {
          // 날짜 클릭 시 동작
          String formattedDate = DateFormat.yMMMd(locale).format(value);
          int? seconds = timerProvider.heatMapDataSet[value];
          String activityTime = seconds != null
              ? '${(seconds / 3600).toStringAsFixed(1)}시간'
              : '데이터 없음';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$formattedDate: $activityTime')),
          );
        },
      ),
    );
  }
}
