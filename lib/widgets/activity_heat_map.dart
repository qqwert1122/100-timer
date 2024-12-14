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

  final int maxActivityTime = 36000;

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    double deviceWidth = MediaQuery.of(context).size.width;
    double squareSize = (deviceWidth - 32) / 9;

    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: HeatMapCalendar(
        initDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
        datasets: timerProvider.heatMapDataSet.entries.fold<Map<DateTime, int>>({}, (map, entry) {
          if (entry.key != null && entry.value != null) {
            int level = 0;

            if (entry.value! <= 0) {
              level = 0;
            } else if (entry.value! < 3600) {
              level = 1;
            } else if (entry.value! < 7200) {
              level = 2;
            } else if (entry.value! < 10800) {
              level = 3;
            } else {
              level = 4;
            }

            map[entry.key!] = level;
          } else {
            debugPrint('Invalid entry: ${entry.key}, ${entry.value}');
          }
          return map;
        }),
        colorMode: ColorMode.opacity,
        colorsets: {
          0: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
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
