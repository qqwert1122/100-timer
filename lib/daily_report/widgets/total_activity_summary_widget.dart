import 'package:flutter/material.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';

class TotalActivitySummaryWidget extends StatelessWidget {
  final String ratio;
  final List<Map<String, dynamic>> hourlyData;
  final Map<String, Map<String, dynamic>> activityTimes;

  const TotalActivitySummaryWidget({
    required this.ratio,
    required this.hourlyData,
    required this.activityTimes,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sortedActivities = activityTimes.entries.toList()
      ..sort((a, b) => b.value['duration'].compareTo(a.value['duration']));

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: ratio == '4:5'
              ? 120
              : ratio == '1:1'
                  ? 100
                  : 140,
          child: CustomPaint(
            size: Size(double.infinity, 200),
            painter: HourlyBarChartPainter(chartData: hourlyData),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 80,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: sortedActivities.map((activity) {
                  final duration = activity.value['duration'] as int;
                  final timeStr = '${(duration ~/ 60)}분';

                  return Container(
                    margin: EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: ColorService.hexToColor(
                                    activity.value['activity_color'])
                                .withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Image.asset(
                              getIconImage(activity.value['activity_icon']),
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          activity.key.length >= 4
                              ? '${activity.key.substring(0, 4)}...'
                              : activity.key,
                          style: TextStyle(fontSize: 10),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HourlyBarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> chartData;

  HourlyBarChartPainter({required this.chartData});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // 차트 영역
    final double chartAreaHeight = height - 40;
    final double baselineY = height - 30;

    // 시간대별 활동 데이터 정리 (0-23시 전체)
    final Map<int, Map<String, Map<String, dynamic>>> hourlyActivityData = {};

    // 0-23시 초기화
    for (int hour = 0; hour < 24; hour++) {
      hourlyActivityData[hour] = {};
    }

    for (final data in chartData) {
      final startHour = data['hour'] as int;
      final minutes = data['minutes'] as double;
      final activityName = data['activity_name'] as String;
      final colorStr = data['activity_color'] as String;

      // duration을 시간대별로 분배
      double remainingMinutes = minutes;
      int currentHour = startHour;

      while (remainingMinutes > 0 && currentHour < 24) {
        double minutesForThisHour =
            (remainingMinutes > 60) ? 60 : remainingMinutes;

        if (!hourlyActivityData[currentHour]!.containsKey(activityName)) {
          hourlyActivityData[currentHour]![activityName] = {
            'minutes': 0.0,
            'color': colorStr,
          };
        }
        hourlyActivityData[currentHour]![activityName]!['minutes'] +=
            minutesForThisHour;

        remainingMinutes -= minutesForThisHour;
        currentHour++;
      }
    }

    // 최대값 찾기
    double maxTotalValue = 0;
    for (final hourData in hourlyActivityData.values) {
      double totalForHour = 0;
      for (final activityData in hourData.values) {
        totalForHour += activityData['minutes'] as double;
      }
      if (totalForHour > maxTotalValue) {
        maxTotalValue = totalForHour;
      }
    }
    if (maxTotalValue <= 0) maxTotalValue = 60;

    final double scaleFactor = (chartAreaHeight * 0.9) / maxTotalValue;

    // 격자선 그리기 (기존과 동일)
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    final Paint linePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final double y = baselineY - chartAreaHeight * i / 4;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
    canvas.drawLine(Offset(0, baselineY), Offset(width, baselineY), linePaint);

    // 24시간 전체 표시
    final double hourWidth = width / 24;
    final double barWidth = hourWidth * 0.6;

    // 시간 레이블 (4시간 간격으로만 표시)
    final textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int hour = 0; hour < 24; hour += 4) {
      textPainter.text = TextSpan(
        text: '${hour}시',
        style: textStyle,
      );
      textPainter.layout();
      final double xCenter = hour * hourWidth + hourWidth / 2;
      textPainter.paint(
        canvas,
        Offset(xCenter - textPainter.width / 2, height - 20),
      );
    }

    // 막대 그리기 (0-23시 전체)
    for (int hour = 0; hour < 24; hour++) {
      final hourData = hourlyActivityData[hour] ?? {};
      final double xCenter = hour * hourWidth + hourWidth / 2;
      final double barLeft = xCenter - barWidth / 2;

      double yOffset = baselineY;

      if (hourData.isEmpty) {
        // 빈 시간대 표시 (회색 점선)
        final Paint emptyPaint = Paint()
          ..color = Colors.grey.withValues(alpha: 0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(xCenter, baselineY - 5),
          Offset(xCenter, baselineY),
          emptyPaint,
        );
        continue;
      }

      // 활동별 막대 쌓기 (기존 로직)
      final sortedActivities = hourData.keys.toList()
        ..sort((a, b) => (hourData[b]!['minutes'] as double)
            .compareTo(hourData[a]!['minutes'] as double));

      for (final activityName in sortedActivities) {
        final activityData = hourData[activityName]!;
        final minutes = activityData['minutes'] as double;
        final colorStr = activityData['color'] as String;

        if (minutes <= 0) continue;

        final Color color = ColorService.hexToColor(colorStr);
        final double barHeight = minutes * scaleFactor;
        final double barTop = yOffset - barHeight;

        final Paint barPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        final RRect roundRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
          const Radius.circular(0),
        );
        canvas.drawRRect(roundRect, barPaint);

        yOffset = barTop;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
