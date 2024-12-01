import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';

class ActivityHeatMap extends StatefulWidget {
  const ActivityHeatMap({super.key});

  @override
  _ActivityHeatMapState createState() => _ActivityHeatMapState();
}

class _ActivityHeatMapState extends State<ActivityHeatMap> {
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  // 최대 활동 시간 설정 (예: 10시간)
  final int maxActivityTime = 36000; // 10시간을 초 단위로 표현

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final locale = Localizations.localeOf(context).toString();

    // 디바이스의 가로 길이
    double deviceWidth = MediaQuery.of(context).size.width;

    // 한 주는 7일이므로, 날짜 칸의 크기를 계산
    double squareSize = (deviceWidth - 32) / 9; // 양쪽 패딩 16씩 제외

    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: HeatMapCalendar(
        initDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
        datasets: timerProvider.heatMapDataSet.map((date, value) {
          int level = ((value / maxActivityTime) * 4).ceil();
          level = level.clamp(1, 4); // 레벨 값을 1~4로 제한
          print("Date: $date, Value: $value, Level: $level"); // 디버깅 로그
          return MapEntry(date, level);
        }),
        colorMode: ColorMode.opacity,
        colorsets: {
          1: ColorService.hexToColor("#32CD32").withOpacity(0.25),
          2: ColorService.hexToColor("#32CD32").withOpacity(0.5),
          3: ColorService.hexToColor("#32CD32").withOpacity(0.75),
          4: ColorService.hexToColor("#32CD32").withOpacity(1.0),
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
          String activityTime = seconds != null ? '${(seconds / 3600).toStringAsFixed(1)}시간' : '데이터 없음';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$formattedDate: $activityTime')),
          );
        },
      ),
    );
  }
}
