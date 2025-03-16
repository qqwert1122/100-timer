import 'package:flutter/material.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:provider/provider.dart';

class WeeklyActivityChart extends StatefulWidget {
  const WeeklyActivityChart({super.key});

  @override
  State<WeeklyActivityChart> createState() => _WeeklyActivityChartState();
}

class _WeeklyActivityChartState extends State<WeeklyActivityChart> {
  int? _selectedDayIndex;

  // 앱 총 사용 시간 계산 (시간과 분 형식)
  String _calculateTotalUsageTime(List<Map<String, dynamic>> sessionData) {
    int totalMinutes = 0;

    for (final session in sessionData) {
      final duration = session['duration'] as int? ?? 0;
      totalMinutes += duration ~/ 60; // 초를 분으로 변환
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else {
      return '$minutes분';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(builder: (context, stats, child) {
      return FutureBuilder<List<Map<String, dynamic>>>(
          future: stats.getWeeklyLineChart(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sessionData = stats.currentSessions;
            final chartData = snapshot.data!;
            final totalUsageTime = _calculateTotalUsageTime(sessionData);

            // 활동 색상 정의 - 더 세련된 색상으로 변경
            final activityColors = [
              const Color(0xFF4CAF50), // 첫 번째 활동 (업무) - 더 부드러운 녹색
              const Color(0xFF448AFF), // 두 번째 활동 (소셜 미디어) - 더 부드러운 파란색
              const Color(0xFFFDD835), // 세 번째 활동 (엔터테인먼트) - 더 부드러운 노란색
              const Color(0xFFAB47BC), // 네 번째 활동 (기타) - 더 부드러운 보라색
            ];

            // 활동 이름과 시간 데이터
            final activityNames = ['업무', '소셜 미디어', '엔터테인먼트', '기타'];
            final activityTimes = [
              '10시간 41분',
              '2시간 53분',
              '49분',
              '12분',
            ];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '주간 활동 시간',
                          style: AppTextStyles.getTitle(context),
                        ),
                        SizedBox(
                          height: context.hp(1),
                        ),
                        Text(
                          '활동 시간을 막대그래프로 확인해 보세요',
                          style: AppTextStyles.getCaption(context),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1)),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Row(
                      children: [
                        Text(
                          totalUsageTime,
                          style: AppTextStyles.getHeadline(context),
                        ),
                        SizedBox(width: context.wp(2)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: context.wp(2), vertical: context.hp(1)),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '8%↑',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 주간 활동 차트 (요일별 바 차트)
                  Container(
                    height: 250,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: _buildCustomBarChart(context, activityColors),
                  ),

                  Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1)),

                  // 활동별 색상 및 시간 표시
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        activityColors.length,
                        (index) => _buildActivityLegendItem(
                          context,
                          activityColors[index],
                          activityNames[index],
                          activityTimes[index],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
    });
  }

  // 커스텀 바 차트 생성 - Canvas를 직접 그려서 만듦
  Widget _buildCustomBarChart(BuildContext context, List<Color> activityColors) {
    return CustomPaint(
      size: const Size(double.infinity, 250),
      painter: BarChartPainter(activityColors),
    );
  }

  // 활동 범례 아이템 - 아이콘과 이름 표시
  Widget _buildActivityLegendItem(BuildContext context, Color color, String name, String time) {
    // 각 활동별 아이콘 매핑
    final Map<String, IconData> activityIcons = {
      '업무': Icons.work,
      '소셜 미디어': Icons.chat,
      '엔터테인먼트': Icons.movie,
      '기타': Icons.more_horiz,
    };

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              activityIcons[name] ?? Icons.circle,
              size: 28,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// 막대 차트를 직접 그리는 CustomPainter
class BarChartPainter extends CustomPainter {
  final List<Color> activityColors;

  BarChartPainter(this.activityColors);

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // 요일 레이블 위치 계산
    const int daysCount = 7;
    final double dayWidth = width / daysCount;
    final double barWidth = dayWidth * 0.5; // 더 날씬한 막대

    // 요일별 데이터 (고정 샘플 데이터)
    final List<List<double>> dailyData = [
      [20, 15, 5, 3], // 일
      [25, 10, 8, 2], // 월
      [30, 20, 10, 5], // 화
      [35, 15, 12, 4], // 수
      [25, 20, 8, 3], // 목
      [20, 15, 10, 5], // 금
      [15, 10, 5, 2], // 토
    ];

    // 격자 그리기 (가로선)
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    // 세 개의 가로 격자선 (25%, 50%, 75% 높이)
    for (int i = 1; i <= 3; i++) {
      final double y = height - 30 - (height - 40) * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        gridPaint,
      );
    }

    // 기준선 그리기 (x축)
    final Paint linePaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, height - 30), // 기준선 y 위치 (아래에서 30픽셀 위)
      Offset(width, height - 30),
      linePaint,
    );

    // 요일 텍스트 그리기
    final List<String> days = ['일', '월', '화', '수', '목', '금', '토'];
    const textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < days.length; i++) {
      textPainter.text = TextSpan(
        text: days[i],
        style: textStyle,
      );
      textPainter.layout();
      final double xCenter = i * dayWidth + dayWidth / 2;
      textPainter.paint(
        canvas,
        Offset(xCenter - textPainter.width / 2, height - 20),
      );
    }

    // 각 요일별 막대 그리기
    for (int dayIndex = 0; dayIndex < dailyData.length; dayIndex++) {
      final dayData = dailyData[dayIndex];
      final double xCenter = dayIndex * dayWidth + dayWidth / 2;
      final double barLeft = xCenter - barWidth / 2;

      // 각 활동별 막대 그리기
      double yOffset = height - 30; // 기준선으로부터 시작

      // 각 색상별 막대 그리기 (첫번째 색상은 가장 아래)
      for (int activityIndex = 0; activityIndex < dayData.length; activityIndex++) {
        // 활동 데이터 값
        final double value = dayData[activityIndex];

        // 활동의 높이 계산 (값에 비례)
        final double barHeight = value * 4; // 비율 조정

        // 막대 상단 y 좌표
        final double barTop = yOffset - barHeight;

        // 막대 그리기
        final Paint barPaint = Paint()
          ..color = activityColors[activityIndex]
          ..style = PaintingStyle.fill;

        // 그림자 효과를 위한 경로
        final path = Path()
          ..moveTo(barLeft, yOffset)
          ..lineTo(barLeft, barTop)
          ..lineTo(barLeft + barWidth, barTop)
          ..lineTo(barLeft + barWidth, yOffset)
          ..close();

        // 막대 그리기 (둥근 모서리)
        final RRect roundRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
          const Radius.circular(2), // 둥근 모서리
        );

        // 그림자 효과
        canvas.drawShadow(path, Colors.black.withOpacity(0.1), 2, true);

        // 둥근 막대 그리기
        canvas.drawRRect(roundRect, barPaint);

        // 하이라이트 효과 (막대 윗부분에 밝은 선)
        final Paint highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        final Path highlightPath = Path()
          ..moveTo(barLeft + 1, barTop + 1)
          ..lineTo(barLeft + barWidth - 1, barTop + 1);

        canvas.drawPath(highlightPath, highlightPaint);

        // 다음 활동의 시작점 업데이트 (쌓기)
        yOffset = barTop;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
