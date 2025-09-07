import 'package:auto_size_text/auto_size_text.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:project1/widgets/total_seconds_cards.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:showcaseview/showcaseview.dart';

class TimerInfoCard extends StatefulWidget {
  final TimerProvider timerProvider;
  final VoidCallback showActivityModal;
  final GlobalKey remainingSecondsKey;
  final GlobalKey weeklyProgressCircleKey;
  final GlobalKey activityListKey;

  const TimerInfoCard({
    required this.timerProvider,
    required this.showActivityModal,
    required this.remainingSecondsKey,
    required this.weeklyProgressCircleKey,
    required this.activityListKey,
    super.key,
  });

  @override
  State<TimerInfoCard> createState() => _TimerInfoCardState();
}

class _TimerInfoCardState extends State<TimerInfoCard>
    with TickerProviderStateMixin {
  StatsProvider? statsProvider;
  TimerProvider? timerProvider;

  int totalDuration = 0;
  int totalSeconds = 1;

  // 애니메이션 컨트롤러
  late AnimationController _congratulationsController;

  @override
  void initState() {
    super.initState();
    statsProvider = Provider.of<StatsProvider>(context, listen: false);
    _loadWeeklyStats();

    // 축하 애니메이션 컨트롤러 초기화
    _congratulationsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _congratulationsController.repeat();
  }

  @override
  void dispose() {
    _congratulationsController.dispose();
    super.dispose();
  }

  Future<void> _loadWeeklyStats() async {
    await statsProvider!.getWeeklyProgressCircle();
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    // 주간 날짜 관련 변수
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekDays =
        List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
    const weekdayNames = ["월", "화", "수", "목", "금", "토", "일"];

    return Consumer<StatsProvider>(
      builder: (context, statsProvider, child) {
        final totalDuration = statsProvider.totalDuration;
        final totalSeconds = statsProvider.totalSeconds;
        final dailyPercents = statsProvider.dailyPercents;

        double percent = (totalDuration / totalSeconds);
        String percentText = (percent * 100).toStringAsFixed(0);

        return Padding(
          padding: context.paddingXS,
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
                      color: AppColors.textSecondary(context)
                          .withValues(alpha: isDarkMode ? 0 : 0.2),
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
                                timerProvider.isWeeklyTargetExceeded
                                    ? '이번 주 달성 시간'
                                    : '이번 주 남은 시간',
                                style:
                                    AppTextStyles.getCaption(context).copyWith(
                                  color: AppColors.textSecondary(context),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Showcase(
                                key: widget.remainingSecondsKey,
                                description: '이번 주 남은 목표시간을 확인하세요',
                                targetBorderRadius: BorderRadius.circular(16),
                                targetPadding: const EdgeInsets.all(4.0),
                                targetShapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ), // 둥근 테두리
                                overlayOpacity: 0.5,
                                child: Consumer<TimerProvider>(
                                  builder: (context, provider, child) {
                                    final text = provider.formattedTime;

                                    final textWidget = AutoSizeText(
                                      text,
                                      style:
                                          AppTextStyles.getTimeDisplay(context)
                                              .copyWith(
                                        color: AppColors.primary(context),
                                        fontFamily: 'chab',
                                      ),
                                      minFontSize: 32,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                    return timerProvider.isWeeklyTargetExceeded
                                        ? Shimmer.fromColors(
                                            baseColor:
                                                AppColors.primary(context),
                                            highlightColor:
                                                AppColors.primary(context)
                                                    .withValues(alpha: 0.5),
                                            child: textWidget)
                                        : textWidget;
                                  },
                                ),
                              ),
                              timerProvider.isWeeklyTargetExceeded
                                  ? Shimmer.fromColors(
                                      baseColor: AppColors.primary(context),
                                      highlightColor:
                                          AppColors.background(context),
                                      child: Text(
                                        '이번주 ${timerProvider.formattedExceededTime}시간 만큼 초과 달성했어요',
                                        style: AppTextStyles.getBody(context)
                                            .copyWith(
                                          color: AppColors.primary(context)
                                              .withValues(alpha: 0.5),
                                          fontSize: context.sm,
                                        ),
                                      ),
                                    )
                                  : const SizedBox()
                            ],
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              timerProvider.isWeeklyTargetExceeded
                                  ? Shimmer.fromColors(
                                      baseColor: AppColors.primary(context),
                                      highlightColor: AppColors.primary(context)
                                          .withValues(alpha: 0.5),
                                      enabled:
                                          timerProvider.isWeeklyTargetExceeded,
                                      child: CircularPercentIndicator(
                                        radius: context.wp(10),
                                        lineWidth: context.wp(5),
                                        animation: true,
                                        percent: percent.clamp(0.0, 1.0),
                                        center: Text(
                                          '$percentText %',
                                          style:
                                              AppTextStyles.getCaption(context)
                                                  .copyWith(),
                                        ),
                                        circularStrokeCap:
                                            CircularStrokeCap.round,
                                        progressColor:
                                            AppColors.primary(context),
                                        backgroundColor:
                                            AppColors.backgroundSecondary(
                                                context),
                                      ),
                                    )
                                  : CircularPercentIndicator(
                                      radius: context.wp(10),
                                      lineWidth: context.wp(5),
                                      animation: true,
                                      percent: percent.clamp(0.0, 1.0),
                                      center: Text(
                                        '$percentText %',
                                        style: AppTextStyles.getCaption(context)
                                            .copyWith(),
                                      ),
                                      circularStrokeCap:
                                          CircularStrokeCap.round,
                                      progressColor: AppColors.primary(context),
                                      backgroundColor:
                                          AppColors.backgroundSecondary(
                                              context),
                                    ),
                              if (timerProvider.isWeeklyTargetExceeded)
                                Positioned.fill(
                                  child: OverflowBox(
                                    maxWidth: context.wp(40), // 원하는 최대 크기
                                    maxHeight: context.wp(40),
                                    child: Lottie.asset(
                                      'assets/images/congraturations.json',
                                      repeat: true,
                                      controller: _congratulationsController,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const SizedBox(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: context.hp(1)),
                      Showcase(
                        key: widget.weeklyProgressCircleKey,
                        description: '남은 목표를 맞추려면 오늘은 이만큼!',
                        targetBorderRadius: BorderRadius.circular(16),
                        targetPadding: const EdgeInsets.all(4.0),
                        targetShapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ), // 둥근 테두리
                        overlayOpacity: 0.5,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            7,
                            (i) {
                              final date = weekDays[i];
                              final isToday = date.year == now.year &&
                                  date.month == now.month &&
                                  date.day == now.day;
                              final formattedDate =
                                  weekdayNames[date.weekday - 1];
                              final pct = dailyPercents[i].clamp(0.0, 1.0);

                              return Column(
                                children: [
                                  // 요일 표시
                                  Text(
                                    formattedDate,
                                    style: AppTextStyles.getCaption(context)
                                        .copyWith(
                                      color: isToday
                                          ? AppColors.primary(context)
                                          : AppColors.textSecondary(context),
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
                                      style: AppTextStyles.getCaption(context)
                                          .copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: isToday
                                            ? AppColors.primary(context)
                                            : AppColors.textSecondary(context),
                                      ),
                                    ),
                                    progressColor: isToday
                                        ? AppColors.primary(context)
                                        : AppColors.textSecondary(context)
                                            .withValues(alpha: 0.4),
                                    backgroundColor:
                                        AppColors.backgroundSecondary(context),
                                    circularStrokeCap: CircularStrokeCap.round,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.hp(1)),

              // 활동 선택
              Showcase(
                key: widget.activityListKey,
                description: '목표 시간을 채워갈 활동을 선택해보세요',
                targetBorderRadius: BorderRadius.circular(16),
                targetPadding: const EdgeInsets.all(1.0),
                targetShapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                overlayOpacity: 0.5,
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await FacebookAppEvents().logEvent(
                      name: 'open_activities',
                      valueToSum: 1,
                    );
                    widget.showActivityModal();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        horizontal: context.xs, vertical: context.md),
                    decoration: BoxDecoration(
                      color: AppColors.background(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textSecondary(context)
                              .withValues(alpha: isDarkMode ? 0.0 : 0.2),
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
                            padding:
                                EdgeInsets.symmetric(horizontal: context.sm),
                            child: Text(
                              '활동 선택',
                              style: AppTextStyles.getBody(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                        ),
                        Consumer<TimerProvider>(
                          builder: (context, timerProvider, child) {
                            final activityIcon =
                                timerProvider.currentActivityIcon;
                            final activityName =
                                timerProvider.currentActivityName;
                            final displayText = activityName.length > 15
                                ? '${activityName.substring(0, 15)}...'
                                : activityName;

                            return Expanded(
                              flex: 6,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Image.asset(
                                    getIconImage(activityIcon),
                                    width: context.xl,
                                    height: context.xl,
                                    errorBuilder: (context, error, stackTrace) {
                                      // 이미지를 로드하는 데 실패한 경우의 대체 표시
                                      return Container(
                                        width: context.xl,
                                        height: context.xl,
                                        color:
                                            Colors.grey.withValues(alpha: 0.2),
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
                                    child: Text(
                                      displayText,
                                      style: AppTextStyles.getBody(context)
                                          .copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Transform(
                                // 중심을 기준으로 좌우 대칭(수평 반전)하기
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..scale(-1.0, 1.0),
                                child: Icon(Icons.arrow_back_ios_new_rounded,
                                    size: context.lg)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.hp(2)),
            ],
          ),
        );
      },
    );
  }
}
