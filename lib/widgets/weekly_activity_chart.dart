import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class WeeklyActivityChart extends StatefulWidget {
  const WeeklyActivityChart({super.key});

  @override
  State<WeeklyActivityChart> createState() => _WeeklyActivityChartState();
}

class _WeeklyActivityChartState extends State<WeeklyActivityChart> with SingleTickerProviderStateMixin {
  String selectedActivityName = "";
  int _lastOffset = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 애니메이션 디버깅을 위한 리스너 추가
    _animationController.addStatusListener((status) {
      print("Animation status: $status");
    });
    _animationController.addListener(() {
      print("Animation value: ${_animationController.value}");
      // 애니메이션 값이 변경될 때마다 화면 갱신 강제
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateSelectedActivity(String activityName) {
    print("Activity selected: $activityName");
    setState(() {
      if (selectedActivityName == activityName) {
        selectedActivityName = "";
      } else {
        selectedActivityName = activityName;
      }
    });

    // 애니메이션 재시작 (setState 전에 호출)
    _animationController.reset();
    _animationController.forward().then((_) {
      print("애니메이션 완료");
    });

    setState(() {
      // 상태 업데이트
    });
  }

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

  String _formatMinutes(double totalMinutes) {
    final minutesInt = totalMinutes.toInt();
    final hours = minutesInt ~/ 60;
    final mins = minutesInt % 60;

    if (hours > 0) {
      return '$hours시간 $mins분';
    } else {
      return '$mins분';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, stats, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: stats.getWeeklyActivityChart(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300.withOpacity(0.2),
                highlightColor: Colors.grey.shade100.withOpacity(0.2),
                child: Container(
                  width: context.wp(90),
                  height: context.hp(30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.background(context),
                  ),
                ),
              );
            }

            if (_lastOffset != stats.weekOffset) {
              _lastOffset = stats.weekOffset;
              // selectedActivityName 초기화 (build 메서드 내에서 직접 setState 호출은 피해야 하므로 마이크로태스크로 예약)
              Future.microtask(() {
                if (mounted) {
                  setState(() {
                    selectedActivityName = "";
                  });
                }
              });
            }

            // "현재" 세션(실제 사용 기록)
            final sessionData = stats.currentSessions;
            final chartData = snapshot.data!;
            final totalUsageTime = _calculateTotalUsageTime(sessionData);

            // chartData 에서 활동별로 고유 정보 추출
            Set<String> uniqueActivities = {};
            Map<String, String> activityColors = {};
            Map<String, String> activityIcons = {};

            for (final data in chartData) {
              final activityName = data['activity_name'] as String;
              final activityColor = data['activity_color'] as String;
              final activityIcon = data['activity_icon'] as String;

              if (!uniqueActivities.contains(activityName)) {
                uniqueActivities.add(activityName);
                activityColors[activityName] = activityColor;
                activityIcons[activityName] = activityIcon;
              }
            }

            // 활동별 전체 시간 파악 -> 많이 쓴 순서대로 정렬
            final Map<String, double> activityTotalMinutes = {};
            for (final data in chartData) {
              final activityName = data['activity_name'] as String;
              final minutes = data['minutes'] as double;
              activityTotalMinutes[activityName] = (activityTotalMinutes[activityName] ?? 0) + minutes;
            }

            // 많이 쓴 순서대로 소팅
            List<String> sortedActivities = uniqueActivities.toList()
              ..sort((a, b) => (activityTotalMinutes[b] ?? 0).compareTo(activityTotalMinutes[a] ?? 0));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 타이틀
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '주간 활동 시간',
                          style: AppTextStyles.getTitle(context),
                        ),
                        Text(
                          '이번주 활동 시간을 막대그래프로 확인해 보세요',
                          style: AppTextStyles.getCaption(context),
                        ),
                      ],
                    ),
                    Image.asset(
                      getIconImage('bar_chart'),
                      width: context.xxxl,
                      height: context.xxxl,
                    ),
                  ],
                ),

                // 총 사용 시간
                Text(
                  totalUsageTime,
                  style: AppTextStyles.getHeadline(context).copyWith(color: AppColors.textSecondary(context)),
                ),

                // 주간 막대 그래프
                SizedBox(
                  height: context.hp(20),
                  child: CustomPaint(
                    willChange: true, // 반드시 willChange를 true로 설정
                    size: const Size(double.infinity, 250),
                    painter: BarChartPainter(
                      chartData: chartData,
                      textColor: AppColors.textPrimary(context),
                      selectedActivityName: selectedActivityName,
                      animationValue: _animationController.value,
                    ),
                  ),
                ),

                SizedBox(height: context.hp(2)),
                // Legend (아이콘 + 색상 원만 표시)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 24.0,
                    direction: Axis.horizontal,
                    children: sortedActivities.map(
                      (activityName) {
                        final colorStr = activityColors[activityName] ?? '#CCCCCC';
                        final iconStr = activityIcons[activityName] ?? 'default_icon';
                        final color = ColorService.hexToColor(colorStr);

                        // 활동별 총 시간 문자열
                        final totalMinutes = activityTotalMinutes[activityName] ?? 0.0;
                        final timeStr = _formatMinutes(totalMinutes);

                        final isNothingSelected = selectedActivityName == "";
                        final isSelected = selectedActivityName == activityName;
                        final shouldPaint = isNothingSelected || isSelected;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _updateSelectedActivity(activityName);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 색상 원 + 아이콘
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: context.xxl,
                                    height: context.xxl,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        getIconImage(iconStr),
                                        width: context.xl,
                                        height: context.xl,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: context.xxl,
                                    height: context.xxl,
                                    decoration: BoxDecoration(
                                      color: AppColors.background(context).withOpacity(shouldPaint ? 0 : 0.7),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: context.hp(1)),
                              // 총 시간 표시

                              Text(
                                activityName.length >= 6 ? '${activityName.substring(0, 6)}...' : activityName,
                                style: TextStyle(
                                  color: AppColors.textPrimary(context).withOpacity(shouldPaint ? 1 : 0.2),
                                  fontSize: context.sm,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color: AppColors.textPrimary(context).withOpacity(shouldPaint ? 1 : 0.2),
                                  fontSize: context.sm,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// 실제 차트를 그리는 CustomPainter
class BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> chartData;
  final Color textColor;
  final String selectedActivityName;
  final double animationValue; // 애니메이션 진행 값 (0.0 ~ 1.0)

  BarChartPainter({
    required this.chartData,
    required this.textColor,
    required this.selectedActivityName,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // 차트 영역
    final double chartAreaHeight = height - 40;
    final double baselineY = height - 30;

    // 요일별 (0~6), 활동별 minutes를 저장
    final Map<int, Map<String, Map<String, dynamic>>> dailyActivityData = {};

    // chartData에서 요일, 활동별 minutes 누적
    for (final data in chartData) {
      final activityName = data['activity_name'] as String;
      final colorStr = data['activity_color'] as String;
      final weekday = data['weekday'] as int; // 1(월) ~ 7(일)
      final minutes = data['minutes'] as double;

      // 1(월) ~ 7(일)을 0~6으로 매핑 (일:0, 월:1, ... 토:6)
      final dayIndex = (weekday + 6) % 7;

      if (!dailyActivityData.containsKey(dayIndex)) {
        dailyActivityData[dayIndex] = {};
      }
      if (!dailyActivityData[dayIndex]!.containsKey(activityName)) {
        dailyActivityData[dayIndex]![activityName] = {
          'minutes': 0.0,
          'color': colorStr,
        };
      }
      dailyActivityData[dayIndex]![activityName]!['minutes'] += minutes;
    }

    // 하루 중 최대값 찾기
    double maxTotalValue = 0;
    for (final dayData in dailyActivityData.values) {
      double totalForDay = 0;
      for (final activityData in dayData.values) {
        totalForDay += activityData['minutes'] as double;
      }
      if (totalForDay > maxTotalValue) {
        maxTotalValue = totalForDay;
      }
    }
    if (maxTotalValue <= 0) {
      maxTotalValue = 100; // 데이터가 없을 때 기본값
    }

    // 막대 높이 비율
    final double scaleFactor = (chartAreaHeight * 0.9) / maxTotalValue;

    // 격자선/기준선 페인트
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;
    final Paint linePaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1;

    // 가로선 3개
    for (int i = 1; i <= 3; i++) {
      final double y = baselineY - chartAreaHeight * i / 4;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
    // x축(기준선)
    canvas.drawLine(Offset(0, baselineY), Offset(width, baselineY), linePaint);

    // 요일 텍스트
    final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 요일별 위치 계산
    const int daysCount = 7;
    final double dayWidth = width / daysCount;
    final double barWidth = dayWidth * 0.5;

    // 요일 레이블 그리기
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

    // 막대 그리기
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final dayData = dailyActivityData[dayIndex] ?? {};
      final double xCenter = dayIndex * dayWidth + dayWidth / 2;
      final double barLeft = xCenter - barWidth / 2;

      double yOffset = baselineY;

      // 활동별로 많은 순서대로 막대를 쌓아 그린다
      final sortedActivities = dayData.keys.toList()
        ..sort((a, b) => (dayData[b]!['minutes'] as double).compareTo(dayData[a]!['minutes'] as double));

      for (final activityName in sortedActivities) {
        final activityData = dayData[activityName]!;
        final minutes = activityData['minutes'] as double;
        final colorStr = activityData['color'] as String;

        final bool isNothingSelected = selectedActivityName.isEmpty;
        final bool isSelected = selectedActivityName == activityName;
        final bool shouldPaint = isNothingSelected || isSelected;

        Color color;
        if (shouldPaint) {
          // 선택되었거나 아무것도 선택되지 않은 경우 원래 색상
          color = ColorService.hexToColor(colorStr);
        } else {
          // 다른 활동이 선택된 경우 회색 또는 투명도 낮추기
          final originalColor = ColorService.hexToColor(colorStr);
          final targetColor = Colors.grey.withOpacity(0.5);

          // 시작 색상에서 목표 색상으로 보간
          color = Color.lerp(originalColor, targetColor, animationValue)!;
        }
        if (minutes <= 0) continue;

        final double barHeight = minutes * scaleFactor;
        final double barTop = yOffset - barHeight;

        final Paint barPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        // 그림자 효과용 Path
        final path = Path()
          ..moveTo(barLeft, yOffset)
          ..lineTo(barLeft, barTop)
          ..lineTo(barLeft + barWidth, barTop)
          ..lineTo(barLeft + barWidth, yOffset)
          ..close();

        // 그림자 효과
        canvas.drawShadow(path, Colors.black.withOpacity(0.1), 2, true);

        // 직사형 막대
        final RRect roundRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
          const Radius.circular(0),
        );
        canvas.drawRRect(roundRect, barPaint);

        // 막대 윗부분 하이라이트
        final Paint highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        final Path highlightPath = Path()
          ..moveTo(barLeft + 1, barTop + 1)
          ..lineTo(barLeft + barWidth - 1, barTop + 1);
        canvas.drawPath(highlightPath, highlightPaint);

        // 다음 활동을 위해 Y축 시작점 갱신 (막대 쌓기)
        yOffset = barTop;
      }
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    // animationValue 변경이 있는지 확인하고 디버깅 출력
    final shouldRedraw = oldDelegate.selectedActivityName != selectedActivityName || oldDelegate.animationValue != animationValue;

    print("애니메이션 값: $animationValue, 이전 값: ${oldDelegate.animationValue}, 다시 그리기: $shouldRedraw");

    return shouldRedraw;
  }
}
