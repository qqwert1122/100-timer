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

  int totalDuration = 0;
  int totalSeconds = 1;

  @override
  void initState() {
    super.initState();
    statsProvider = Provider.of<StatsProvider>(context, listen: false);
    _loadWeeklyStats();
  }

  Future<void> _loadWeeklyStats() async {
    final duration = await statsProvider!.getTotalDurationForCurrentWeek();
    final total = await statsProvider!.getTotalSecondsForCurrnetWeek();

    if (mounted) {
      setState(() {
        totalDuration = duration;
        totalSeconds = total != 0 ? total : 1; // 0이면 퍼센트 계산 에러 방지
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
            ),
            child: Padding(
              padding: context.paddingSM,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'today',
                        style: AppTextStyles.getBody(context).copyWith(
                          color: AppColors.textSecondary(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: context.hp(1)),
                      Text(
                        todayString,
                        style: AppTextStyles.getTitle(context).copyWith(
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Neo',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: context.wp(5)),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: weekDays.map((date) {
                        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                        final formattedDate = weekdayNames[date.weekday - 1];

                        return Column(
                          children: [
                            Text(
                              formattedDate,
                              style: AppTextStyles.getCaption(context).copyWith(
                                color: isToday ? AppColors.primary(context) : AppColors.textSecondary(context),
                              ),
                            ),
                            SizedBox(height: context.hp(0.5)),
                            Container(
                              padding: const EdgeInsets.all(4.0),
                              decoration: isToday
                                  ? BoxDecoration(
                                      color: AppColors.primary(context).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    )
                                  : null,
                              child: Text(
                                '${date.day}',
                                style: AppTextStyles.getBody(context).copyWith(
                                  color: isToday ? AppColors.primary(context) : AppColors.textSecondary(context),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.hp(1)),

          // 남은 시간
          Container(
            decoration: BoxDecoration(
              color: AppColors.background(context),
              borderRadius: const BorderRadius.all(
                Radius.circular(16.0),
              ),
            ),
            child: Padding(
              padding: context.paddingSM,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이번 주 남은 시간',
                        style: AppTextStyles.getBody(context).copyWith(
                          color: AppColors.textSecondary(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Consumer<TimerProvider>(
                        builder: (context, provider, child) {
                          return Text(
                            provider.formattedTime,
                            style: AppTextStyles.getTimeDisplay(context).copyWith(
                              color: AppColors.primary(context),
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
                    progressColor: Colors.redAccent,
                    backgroundColor: AppColors.backgroundSecondary(context),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.hp(1)),

          // 활동 선택
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.showActivityModal();
                  },
                  child: Container(
                      padding: EdgeInsets.symmetric(horizontal: context.xs, vertical: context.sm),
                      decoration: BoxDecoration(
                        color: AppColors.background(context),
                        borderRadius: BorderRadius.circular(16),
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
                                SizedBox(width: context.wp(2)),
                                Flexible(
                                  child: Builder(
                                    builder: (context) {
                                      final activityName = widget.timerProvider.currentActivityName;
                                      final displayText = activityName.length > 10 ? '${activityName.substring(0, 10)}...' : activityName;

                                      return Text(
                                        displayText,
                                        style: AppTextStyles.getTitle(context).copyWith(fontWeight: FontWeight.w900),
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
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
