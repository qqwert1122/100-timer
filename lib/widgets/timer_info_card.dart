import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';

class TimerInfoCard extends StatefulWidget {
  final TimerProvider timerProvider;
  final VoidCallback showActivityModal;

  const TimerInfoCard({
    required this.timerProvider,
    required this.showActivityModal,
    super.key,
  });

  @override
  State<TimerInfoCard> createState() => _TimerInfoCardState();
}

class _TimerInfoCardState extends State<TimerInfoCard> {
  StatsProvider? statsProvider;
  TimerProvider? timerProvider;

  int totalDuration = 0;
  int totalSeconds = 1;

  List<int> _dailyDurations = List.filled(7, 0);
  List<double> _dailyPercents = List.filled(7, 0.0);

  @override
  void initState() {
    super.initState();
    statsProvider = Provider.of<StatsProvider>(context, listen: false);
    timerProvider = Provider.of<TimerProvider>(context, listen: false);
    _loadWeeklyStats();
  }

  Future<void> _loadWeeklyStats() async {
    final duration = await statsProvider!.getTotalDurationForCurrentWeek();
    final total = await statsProvider!.getTotalSecondsForCurrnetWeek();

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    List<int> dailyDurations = [];
    for (var date in weekDays) {
      // StatsProvider에 날짜 단위로 duration을 가져오는 메서드가 있다고 가정
      final d = await statsProvider!.getTotalDurationForDate(date);
      dailyDurations.add(d);
    }

    int remaining = total;
    List<double> percents = [];
    for (int i = 0; i < 7; i++) {
      final daysLeft = 7 - i;
      final target = remaining / daysLeft; // 남은 일수로 균등 분배
      final actual = dailyDurations[i].toDouble();
      final pct = (actual / (target > 0 ? target : 1)).clamp(0.0, 1.0);
      percents.add(pct);
      remaining -= actual.toInt(); // 다음 요일 목표 계산을 위해 차감
    }

    if (mounted) {
      setState(() {
        totalDuration = duration;
        totalSeconds = total != 0 ? total : 1; // 0이면 퍼센트 계산 에러 방지
        _dailyDurations = dailyDurations;
        _dailyPercents = percents;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 주간 날짜 관련 변수
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
    const weekdayNames = ["월", "화", "수", "목", "금", "토", "일"];
    final todayString = '${now.month}월 ${now.day}일';

    // 퍼센트 관련 변수
    double percent = (totalDuration / totalSeconds);
    String percentText = (percent * 100).toStringAsFixed(0);

    return Padding(
      padding: context.paddingSM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 주간 날짜
          Container(
            decoration: BoxDecoration(
              color: AppColors.background(context),
              borderRadius: const BorderRadius.all(
                Radius.circular(16.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textSecondary(context).withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: context.paddingSM,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timerProvider!.isWeeklyTargetExceeded ? '이번 주 초과 달성 시간' : '이번 주 남은 목표 시간',
                            style: AppTextStyles.getCaption(context).copyWith(
                              color: AppColors.textSecondary(context),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Consumer<TimerProvider>(
                            builder: (context, provider, child) {
                              return Text(
                                provider.formattedTime,
                                style: AppTextStyles.getTimeDisplay(context).copyWith(
                                  color: timerProvider!.isWeeklyTargetExceeded ? Colors.blueAccent : AppColors.primary(context),
                                  fontFamily: 'chab',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      CircularPercentIndicator(
                        radius: context.wp(10),
                        lineWidth: context.wp(5),
                        animation: true,
                        percent: percent.clamp(0.0, 1.0),
                        center: Text(
                          '$percentText %',
                          style: AppTextStyles.getCaption(context).copyWith(),
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: timerProvider!.isWeeklyTargetExceeded ? Colors.blueAccent : Colors.redAccent,
                        backgroundColor: AppColors.backgroundSecondary(context),
                      ),
                    ],
                  ),
                  SizedBox(height: context.hp(1)),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final date = weekDays[i];
                      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                      final formattedDate = weekdayNames[date.weekday - 1];
                      final pct = _dailyPercents[i].clamp(0.0, 1.0);

                      return Column(
                        children: [
                          // 요일 표시
                          Text(
                            formattedDate,
                            style: AppTextStyles.getCaption(context).copyWith(
                              color: isToday ? AppColors.primary(context) : AppColors.textSecondary(context),
                            ),
                          ),
                          SizedBox(height: context.hp(0.5)),
                          // 날짜 + 프로그레스
                          CircularPercentIndicator(
                            radius: context.wp(4),
                            lineWidth: context.wp(2),
                            animation: true,
                            percent: pct,
                            center: Text(
                              '${date.day}',
                              style: AppTextStyles.getCaption(context).copyWith(
                                fontWeight: FontWeight.w900,
                                color: isToday ? AppColors.primary(context) : AppColors.textSecondary(context),
                              ),
                            ),
                            progressColor: isToday ? AppColors.primary(context) : AppColors.textSecondary(context).withOpacity(0.4),
                            backgroundColor: AppColors.backgroundSecondary(context),
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.hp(1)),

          // 활동 선택
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.showActivityModal();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: context.xs, vertical: context.md),
              decoration: BoxDecoration(
                color: AppColors.background(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textSecondary(context).withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.sm),
                      child: Text(
                        '활동 선택',
                        style: AppTextStyles.getBody(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Image.asset(
                          getIconImage(widget.timerProvider.currentActivityIcon),
                          width: context.xl,
                          height: context.xl,
                          errorBuilder: (context, error, stackTrace) {
                            // 이미지를 로드하는 데 실패한 경우의 대체 표시
                            return Container(
                              width: context.xl,
                              height: context.xl,
                              color: Colors.grey.withOpacity(0.2),
                              child: Icon(
                                Icons.broken_image,
                                size: context.xl,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                        SizedBox(width: context.wp(1)),
                        Flexible(
                          child: Builder(
                            builder: (context) {
                              final activityName = widget.timerProvider.currentActivityName;
                              final displayText = activityName.length > 15 ? '${activityName.substring(0, 15)}...' : activityName;

                              return Text(
                                displayText,
                                style: AppTextStyles.getBody(context).copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Transform(
                          // 중심을 기준으로 좌우 대칭(수평 반전)하기
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..scale(-1.0, 1.0),
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: context.lg)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
