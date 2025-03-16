import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:provider/provider.dart';

class WeeklyLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  static const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  const WeeklyLineChart({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    // StatsProvider에서 현재 weekOffset 가져오기
    final statsProvider = Provider.of<StatsProvider>(context, listen: false);
    final weekOffset = statsProvider.weekOffset;

    // 현재 주가 아닌 경우(과거/미래 주)에는 해당 주의 모든 날짜를 표시
    // 현재 주인 경우에만 오늘까지만 표시
    final today = DateTime.now().weekday - 1; // 0: 월요일, ..., 6: 일요일로 변환
    final isCurrentWeek = weekOffset == 0;
    final lastDayToShow = isCurrentWeek ? today : 6; // 현재 주면 오늘까지, 아니면 일요일(6)까지

    final activityData = <String, Map<String, dynamic>>{};

    for (final session in sessions) {
      final name = session['activity_name'];
      if (!activityData.containsKey(name)) {
        activityData[name] = {
          'color': session['activity_color'],
          'minutes': List.filled(7, 0.0),
        };
      }
      final weekday = int.parse(session['weekday'].toString());
      final adjustedWeekday = weekday == 0 ? 6 : weekday - 1;
      activityData[name]!['minutes'][adjustedWeekday] = session['minutes'];
    }
    double maxMinutes = 0;
    for (var activity in activityData.values) {
      final minutes = activity['minutes'] as List<double>;
      final max = minutes.reduce((a, b) => a > b ? a : b);
      if (max > maxMinutes) maxMinutes = max;
    }

    // y축 최대값을 1시간 단위로 올림
    final yAxisMax = ((maxMinutes + 59) ~/ 120) * 120.0;
    const interval = 120.0; // 항상 1시간 간격

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: context.hp(15),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: yAxisMax,
                clipData: const FlClipData.all(), // 차트 영역을 벗어나지 않도록 클리핑
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        final hours = value ~/ 60;
                        return Text(hours > 0 ? '$hours시간' : '', style: AppTextStyles.getCaption(context));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        // 현재 주인 경우 오늘까지는 진한 색, 나머지는 연한 색
                        // 과거 주인 경우 모든 요일 진한 색
                        // 미래 주인 경우 모든 요일 연한 색
                        final bool useDarkColor = weekOffset < 0 || (isCurrentWeek && index <= today);
                        return Text(
                          weekdays[index],
                          style: AppTextStyles.getCaption(context).copyWith(
                            color: useDarkColor ? Colors.grey.shade600 : Colors.grey.shade300,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: activityData.entries.map((entry) {
                  final minutes = entry.value['minutes'] as List<double>;
                  final color = entry.value['color'] as String;

                  return LineChartBarData(
                    spots: List.generate(7, (index) {
                      // 현재 주인 경우 오늘 이후의 데이터는 표시하지 않음
                      // 과거 주인 경우는 모든 데이터 표시
                      // 미래 주인 경우는 모든 데이터 0으로 표시
                      if (weekOffset > 0 || (isCurrentWeek && index > today)) {
                        return FlSpot(index.toDouble(), 0);
                      }
                      return FlSpot(index.toDouble(), minutes[index]);
                    }),
                    isCurved: true,
                    color: Color(int.parse('FF${color.substring(1)}', radix: 16)),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
