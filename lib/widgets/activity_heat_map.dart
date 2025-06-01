import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:intl/intl.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/stats_provider.dart';
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
      final statsProvider = Provider.of<StatsProvider>(context, listen: false);
      if (statsProvider.heatMapDataSet.isEmpty) {
        logger.d("히트맵 데이터가 비어있습니다. 데이터를 초기화합니다.");
        statsProvider.initializeHeatMapData();
      }
    });
  }

  List<String> lightModeColor = ["#F5F5F5", "#CFFF8D", "#9CFF2E", "#38E54D", "#06D001"];
  List<String> darkModeColor = ["#424242", "#113311", "#0B4B0B", "#057505", "#00AA00"];

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    double deviceWidth = MediaQuery.of(context).size.width;
    double squareSize = (deviceWidth - 32) / 9;

    // 레벨별 데이터 변환 (초 단위 데이터 기준)
    Map<DateTime, int> datasets = {};
    statsProvider.heatMapDataSet.forEach((date, duration) {
      int level = 0;
      // 초 단위 데이터를 시간 단위로 변환
      double hours = duration / 3600;
      if (duration <= 2) {
        level = 0;
      } else if (hours <= 4) {
        level = 1;
      } else if (hours <= 6) {
        level = 2;
      } else if (hours <= 8) {
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
                    0: ColorService.hexToColor(isDarkMode ? darkModeColor[0] : lightModeColor[0]),
                    1: ColorService.hexToColor(isDarkMode ? darkModeColor[1] : lightModeColor[1]),
                    2: ColorService.hexToColor(isDarkMode ? darkModeColor[2] : lightModeColor[2]),
                    3: ColorService.hexToColor(isDarkMode ? darkModeColor[3] : lightModeColor[3]),
                    4: ColorService.hexToColor(isDarkMode ? darkModeColor[4] : lightModeColor[4]),
                  },
                  defaultColor: AppColors.backgroundSecondary(context),
                  textColor: isDarkMode ? Colors.white70 : Colors.black87,
                  showColorTip: false,
                  size: squareSize,
                  monthFontSize: 16,
                  weekFontSize: 14,
                  onMonthChange: (selectedMonth) {
                    statsProvider.initializeHeatMapData(
                      year: selectedMonth.year,
                      month: selectedMonth.month,
                    );
                  },
                  onClick: (value) {
                    String formattedDate = DateFormat.yMMMd(locale).format(value);
                    int? seconds = statsProvider.heatMapDataSet[value];
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
                      _buildLegendItem(context, "0시간~", 0, isDarkMode),
                      const SizedBox(width: 8),
                      _buildLegendItem(context, "2시간~", 1, isDarkMode),
                      const SizedBox(width: 8),
                      _buildLegendItem(context, "4시간~", 2, isDarkMode),
                      const SizedBox(width: 8),
                      _buildLegendItem(context, "6시간~", 3, isDarkMode),
                      const SizedBox(width: 8),
                      _buildLegendItem(context, "8시간~", 4, isDarkMode),
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
            color: ColorService.hexToColor(isDarkMode ? darkModeColor[level] : lightModeColor[level]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.getCaption(context),
        ),
      ],
    );
  }
}
