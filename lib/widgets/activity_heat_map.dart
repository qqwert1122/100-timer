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
  @override
  void initState() {
    super.initState();

    // 위젯이 처음 생성될 때 데이터 초기화 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      if (timerProvider.heatMapDataSet.isEmpty) {
        print("히트맵 데이터가 비어있습니다. 데이터를 초기화합니다.");
        timerProvider.initializeHeatMapData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    double deviceWidth = MediaQuery.of(context).size.width;
    double squareSize = (deviceWidth - 32) / 9;

    // 레벨별 데이터 변환 (초 단위 데이터 기준)
    Map<DateTime, int> datasets = {};
    timerProvider.heatMapDataSet.forEach((date, duration) {
      int level = 0;
      // 초 단위 데이터를 시간 단위로 변환
      double hours = duration / 3600;
      if (duration <= 1) {
        level = 0;
      } else if (hours <= 2) {
        level = 1;
      } else if (hours <= 4) {
        level = 2;
      } else if (hours <= 6) {
        level = 3;
      } else {
        level = 4;
      }
      datasets[date] = level;
    });

    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [
                HeatMapCalendar(
                  initDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
                  datasets: datasets,
                  colorMode: ColorMode.color,
                  colorsets: {
                    0: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                    1: ColorService.hexToColor("#32CD32").withOpacity(0.25),
                    2: ColorService.hexToColor("#32CD32").withOpacity(0.5),
                    3: ColorService.hexToColor("#32CD32").withOpacity(0.75),
                    4: ColorService.hexToColor("#32CD32").withOpacity(1),
                  },
                  defaultColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                  textColor: isDarkMode ? Colors.white70 : Colors.black87,
                  showColorTip: false,
                  size: squareSize,
                  monthFontSize: 16,
                  weekFontSize: 14,
                  onMonthChange: (selectedMonth) {
                    timerProvider.initializeHeatMapData(
                      year: selectedMonth.year,
                      month: selectedMonth.month,
                    );
                  },
                  onClick: (value) {
                    String formattedDate = DateFormat.yMMMd(locale).format(value);
                    int? seconds = timerProvider.heatMapDataSet[value];
                    String activityTime = seconds != null ? '${(seconds / 3600).toStringAsFixed(1)}시간' : '데이터 없음';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$formattedDate: $activityTime')),
                    );
                  },
                ),
                // 범례 추가
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(context, "0시간", 0, isDarkMode),
                      const SizedBox(width: 8),
                      _buildLegendItem(context, "~1시간", 1, isDarkMode),
                      const SizedBox(width: 8),
                      _buildLegendItem(context, "~2시간", 2, isDarkMode),
                      const SizedBox(width: 8),
                      _buildLegendItem(context, "~3시간", 3, isDarkMode),
                      const SizedBox(width: 8),
                      _buildLegendItem(context, "3시간+", 4, isDarkMode),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String text, int level, bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: level == 0
                ? (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)
                : ColorService.hexToColor("#32CD32").withOpacity(level * 0.25),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.white70 : Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
