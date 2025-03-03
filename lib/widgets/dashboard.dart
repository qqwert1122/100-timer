import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:project1/widgets/weekly_linechart.dart';
import 'package:project1/widgets/weekly_session_status.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class Dashboard extends StatefulWidget {
  final int remainingSeconds;
  final int totalSeconds;

  const Dashboard({
    Key? key,
    required this.remainingSeconds,
    this.totalSeconds = 360000, // 기본값: 100시간 (360,000초)
  }) : super(key: key);
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late int _remainingSeconds;
  Timer? _timer;
  TimerProvider? timerProvider;
  late DatabaseService _dbService;
  late StatsProvider _statsProvider;

  @override
  void initState() {
    super.initState();
    timerProvider = Provider.of<TimerProvider>(context, listen: false);
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    _statsProvider = Provider.of<StatsProvider>(context, listen: false);
    _remainingSeconds = widget.remainingSeconds;
    _start();
  }

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      setState(() {
        if (_remainingSeconds >= 30) {
          _remainingSeconds -= 30; // 1분(60초) 감소
        } else {
          _remainingSeconds = 0;
          _timer?.cancel();
        }
      });
    });
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double percent = (1 - _remainingSeconds / widget.totalSeconds);

    String percentText = (percent * 100).toStringAsFixed(0);
    List<Map<String, dynamic>> weeklyActivities = [];

    int totalCount = weeklyActivities.length;

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.hp(3)),
            Padding(
              padding: context.paddingSM,
              child: Text(
                '이번주 대시보드',
                style: AppTextStyles.getHeadline(context),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: context.paddingSM,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          offset: const Offset(0, 2),
                          blurRadius: 2,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: context.paddingSM,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("12월 5주차",
                                  style: AppTextStyles.getTitle(context)),
                              SizedBox(height: context.hp(1)),
                              Row(
                                children: [
                                  Text(
                                    timerProvider?.formattedHour ?? '0h',
                                    style: AppTextStyles.getTimeDisplay(context)
                                        .copyWith(
                                      fontFamily: 'chab',
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  SizedBox(width: context.wp(1)),
                                  Container(
                                    width: 1, // 선의 두께
                                    height: context.hp(2), // 선의 높이
                                    color: Colors.grey.shade400, // 선의 색상
                                    margin: EdgeInsets.symmetric(
                                        horizontal: context.wp(1)), // 양쪽 여백
                                  ),
                                  SizedBox(width: context.wp(1)),
                                  Text(
                                    '100',
                                    style: AppTextStyles.getTimeDisplay(context)
                                        .copyWith(
                                            fontFamily: 'chab',
                                            color: Colors.grey.shade300),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          CircularPercentIndicator(
                            radius: context.wp(12),
                            lineWidth: context.wp(5),
                            animation: true,
                            percent: percent.clamp(0.0, 1.0),
                            center: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  percentText,
                                  style:
                                      AppTextStyles.getBody(context).copyWith(
                                    fontSize: context.xl,
                                    color: Colors.redAccent,
                                    fontFamily: 'chab',
                                  ),
                                ),
                                SizedBox(width: context.wp(0.5)),
                                Text(
                                  '%',
                                  style: AppTextStyles.getCaption(context),
                                ),
                              ],
                            ),
                            circularStrokeCap: CircularStrokeCap.round,
                            progressColor: Colors.redAccent,
                            backgroundColor: AppColors.background(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.hp(3)),
            Padding(
              padding: context.paddingHorizSM,
              child: Text(
                '집중 달성한 날',
                style: AppTextStyles.getBody(context)
                    .copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const WeeklySessionStatus(isSimple: true),
            SizedBox(height: context.hp(3)),
            Padding(
              padding: context.paddingHorizSM,
              child: Text(
                '주간 활동 차트',
                style: AppTextStyles.getBody(context)
                    .copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _statsProvider.getWeeklyLineChart(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Padding(
                  padding: context.paddingSM,
                  child: WeeklyLineChart(sessions: snapshot.data!),
                );
              },
            ),
            Padding(
              padding: context.paddingHorizSM,
              child: Text(
                '이번주에',
                style: AppTextStyles.getBody(context)
                    .copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Padding(
              padding: context.paddingSM,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: context.hp(18),
                      padding: context.paddingSM,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary(context), // 보라색 배경
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: FutureBuilder<Map<String, dynamic>>(
                          future: _statsProvider.getWeeklyReport(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const CircularProgressIndicator();

                            final stats = snapshot.data!['mostActiveDate'];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '가장 활발했던 날',
                                  style: AppTextStyles.getBody(context)
                                      .copyWith(fontWeight: FontWeight.w900),
                                ),
                                SizedBox(height: context.hp(1)),
                                Text(
                                  stats == null
                                      ? '없음'
                                      : '${stats['dayName']}요일',
                                  style: AppTextStyles.getHeadline(context)
                                      .copyWith(
                                    color: stats == null
                                        ? Colors.grey
                                        : Colors.redAccent,
                                  ),
                                ),
                                SizedBox(
                                  height: context.hp(2),
                                ),
                                Text(
                                  stats == null
                                      ? ''
                                      : formatDuration(stats['total_duration']),
                                  style:
                                      AppTextStyles.getTitle(context).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            );
                          }),
                    ),
                  ),
                  SizedBox(width: context.wp(4)),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: context.hp(18),
                      padding: context.paddingSM,
                      decoration: BoxDecoration(
                        color: Colors.orange, // 주황색 배경
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: FutureBuilder<Map<String, dynamic>>(
                          future: _statsProvider.getWeeklyReport(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const CircularProgressIndicator();

                            final stats = snapshot.data!['mostActiveHour'];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '최대 집중시간',
                                  style: AppTextStyles.getBody(context)
                                      .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900),
                                ),
                                SizedBox(height: context.hp(1)),
                                Text(
                                  formatDuration(stats?['total_duration'] ?? 0),
                                  style: AppTextStyles.getHeadline(context)
                                      .copyWith(color: Colors.white),
                                ),
                                SizedBox(height: context.hp(3)),
                              ],
                            );
                          }),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: context.hp(30),
            ),
          ],
        ),
      );
    });
  }
}
