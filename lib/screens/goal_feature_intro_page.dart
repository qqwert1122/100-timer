import 'package:carousel_slider/carousel_slider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class GoalFeatureIntroPage extends StatefulWidget {
  const GoalFeatureIntroPage({
    super.key,
  });

  @override
  State<GoalFeatureIntroPage> createState() => _GoalFeatureIntroPageState();
}

class _GoalFeatureIntroPageState extends State<GoalFeatureIntroPage> {
  void _launchURL() async {
    final uri = Uri.parse('https://forms.gle/wu5majckKn2er9NX7');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    final List<Map<String, dynamic>> goalSamples = [
      {
        'title': '어플리케이션 출시',
        'color': '#F67280',
        'icon': 'laptop',
      },
      {
        'title': '바디프로필 촬영',
        'color': '#C06C84',
        'icon': 'fitness',
      },
      {
        'title': '영어점수 100점',
        'color': '#6C5B7B',
        'icon': 'hundred',
      },
      {
        'title': '책 12권 읽기',
        'color': '#355C7D',
        'icon': 'openbook',
      },
    ];

    Widget _buildIntroLine(BuildContext context, String text) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.check,
            size: context.md,
            color: AppColors.textPrimary(context),
          ),
          SizedBox(width: context.wp(2)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.getBody(context).copyWith(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      );
    }

    Widget dayStatus(List<int> statusList, BuildContext context) {
      double containerSize = context.lg;

      Widget _buildCircle(int status) {
        switch (status) {
          case 1:
            return Container(
              width: containerSize,
              height: containerSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            );
          case -1:
            return Container(
              width: containerSize,
              height: containerSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            );
          case 0:
          default:
            return Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
                color: AppColors.backgroundSecondary(context),
              ),
            );
        }
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: statusList
            .map((status) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _buildCircle(status),
                ))
            .toList(),
      );
    }

    Widget fitnessCard() {
      return Container(
        width: double.infinity,
        padding: context.paddingSM,
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary(context).withOpacity(0.08), // 그림자 색상
              blurRadius: 10, // 그림자 흐림 정도
              offset: const Offset(-2, 8), // 그림자 위치 (가로, 세로)
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: context.xxl,
                  height: context.xxl,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50.0)),
                  child: Image.asset(
                    getIconImage('fitness'),
                    width: context.xl,
                    height: context.xl,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: context.xl,
                        height: context.xl,
                        color: Colors.grey.withOpacity(0.2),
                        child: Icon(Icons.broken_image,
                            size: context.xl, color: Colors.grey),
                      );
                    },
                  ),
                ),
                SizedBox(width: context.wp(2)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '활동 | ',
                          style: AppTextStyles.getBody(context).copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        Text(
                          '피트니스',
                          style: AppTextStyles.getBody(context).copyWith(
                            fontFamily: 'neo',
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: context.wp(1),
                      runSpacing: context.hp(1),
                      children: [
                        Text(
                          '3개월',
                          style: AppTextStyles.getBody(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '동안',
                          style: AppTextStyles.getBody(context).copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '매주',
                          style: AppTextStyles.getBody(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '피트니스',
                          style: AppTextStyles.getBody(context).copyWith(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '3회',
                          style: AppTextStyles.getBody(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '하기',
                          style: AppTextStyles.getBody(context).copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: context.hp(2)),
            Padding(
              padding: context.paddingHorizXS,
              child: dayStatus([1, 1, -1, 1, 1, 1, 1, 1, 0, 0], context),
            ),
            SizedBox(height: context.hp(1)),
            Padding(
              padding: context.paddingHorizXS,
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: context.wp(2),
                runSpacing: context.hp(1),
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.checkCircle2,
                        size: context.md,
                        color: Colors.blueAccent,
                      ),
                      SizedBox(width: context.wp(1)),
                      Text(
                        '7',
                        style: AppTextStyles.getCaption(context).copyWith(
                          color: Colors.blueAccent,
                        ),
                      ),
                      Text('/15회', style: AppTextStyles.getCaption(context)),
                    ],
                  ),
                  Text(
                    '|',
                    style: AppTextStyles.getCaption(context),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.lineChart,
                        size: context.md,
                        color: Colors.grey,
                      ),
                      SizedBox(width: context.wp(1)),
                      Text(
                        '47% 달성',
                        style: AppTextStyles.getCaption(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: context.hp(1)),
            Padding(
              padding: context.paddingHorizXS,
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: context.wp(2),
                runSpacing: context.hp(1),
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.timer,
                        size: context.md,
                        color: Colors.grey,
                      ),
                      SizedBox(width: context.wp(1)),
                      Text(
                        '누적 활동 시간   11h 32m',
                        style: AppTextStyles.getCaption(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget runningCard() {
      return Container(
        width: double.infinity,
        padding: context.paddingSM,
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary(context).withOpacity(0.08), // 그림자 색상
              blurRadius: 10, // 그림자 흐림 정도
              offset: const Offset(-2, 8), // 그림자 위치 (가로, 세로)
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: context.xxl,
                  height: context.xxl,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50.0)),
                  child: Image.asset(
                    getIconImage('running'),
                    width: context.xl,
                    height: context.xl,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: context.xl,
                        height: context.xl,
                        color: Colors.grey.withOpacity(0.2),
                        child: Icon(Icons.broken_image,
                            size: context.xl, color: Colors.grey),
                      );
                    },
                  ),
                ),
                SizedBox(width: context.wp(2)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '활동 | ',
                          style: AppTextStyles.getBody(context).copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        Text(
                          '러닝',
                          style: AppTextStyles.getBody(context).copyWith(
                            fontFamily: 'neo',
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: context.wp(1),
                      runSpacing: context.hp(1),
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.calendarDays,
                              size: context.sm,
                            ),
                            SizedBox(width: context.wp(1)),
                            Text(
                              '2025-12-31',
                              style: AppTextStyles.getCaption(context).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '까지',
                          style: AppTextStyles.getBody(context).copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '매일',
                          style: AppTextStyles.getBody(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '러닝',
                          style: AppTextStyles.getBody(context).copyWith(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '30분',
                          style: AppTextStyles.getBody(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '하기',
                          style: AppTextStyles.getBody(context).copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: context.hp(2)),
            Padding(
              padding: context.paddingHorizXS,
              child: dayStatus([1, 1, 1, 1, 1, 1, 0, 0, 0, 0], context),
            ),
            SizedBox(height: context.hp(1)),
            Padding(
              padding: context.paddingHorizXS,
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: context.wp(2),
                runSpacing: context.hp(1),
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.checkCircle2,
                        size: context.md,
                        color: Colors.blueAccent,
                      ),
                      SizedBox(width: context.wp(1)),
                      Text(
                        '6',
                        style: AppTextStyles.getCaption(context).copyWith(
                          color: Colors.blueAccent,
                        ),
                      ),
                      Text(
                        '/248회',
                        style: AppTextStyles.getCaption(context),
                      ),
                    ],
                  ),
                  Text(
                    '|',
                    style: AppTextStyles.getCaption(context),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.lineChart,
                        size: context.md,
                        color: Colors.grey,
                      ),
                      SizedBox(width: context.wp(1)),
                      Text(
                        '2% 달성',
                        style: AppTextStyles.getCaption(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: context.hp(1)),
            Padding(
              padding: context.paddingHorizXS,
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: context.wp(2),
                runSpacing: context.hp(1),
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.timer,
                        size: context.md,
                        color: Colors.grey,
                      ),
                      SizedBox(width: context.wp(1)),
                      Text(
                        '누적 활동 시간   3h 11m',
                        style: AppTextStyles.getCaption(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget goalCard() {
      return Container(
        padding: context.paddingHorizSM,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary(context),
          borderRadius: BorderRadius.circular(16.0), // 둥근 모서리
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary(context).withOpacity(0.08), // 그림자 색상
              blurRadius: 10, // 그림자 흐림 정도
              offset: const Offset(-2, 8), // 그림자 위치 (가로, 세로)
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.hp(1)),
            Row(
              children: [
                Text(
                  '목표 |',
                  style: AppTextStyles.getBody(context).copyWith(
                    fontFamily: 'Neo',
                    color: AppColors.textSecondary(context),
                  ),
                ),
                SizedBox(width: context.wp(2)),
                Text(
                  '바디프로필 찍기',
                  style: AppTextStyles.getBody(context).copyWith(
                    fontFamily: 'Neo',
                  ),
                ),
                SizedBox(width: context.wp(2)),
                Image.asset(
                  getIconImage('fitness'),
                  width: context.xxl,
                  height: context.xxl,
                  errorBuilder: (context, error, stackTrace) {
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
              ],
            ),
            Divider(color: AppColors.backgroundTertiary(context)),
            SizedBox(height: context.hp(1)),
            fitnessCard(),
            SizedBox(height: context.hp(4)),
            runningCard(),
            SizedBox(height: context.hp(2)),
          ],
        ),
      );
    }

    Widget goalChart() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0), // 둥근 모서리
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary(context).withOpacity(0.08), // 그림자 색상
              blurRadius: 10, // 그림자 흐림 정도
              offset: const Offset(-2, 8), // 그림자 위치 (가로, 세로)
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '달성률',
              style: AppTextStyles.getBody(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.hp(1)),
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 배경 막대
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Container(
                  height: 10,
                  width: MediaQuery.of(context).size.width * 0.9 * 0.47,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Positioned(
                  left: (MediaQuery.of(context).size.width * 0.9 * 0.47) - 25,
                  bottom: 15,
                  child: Container(
                    padding: context.paddingXS,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      ' 7 / 15 ',
                      style: AppTextStyles.getCaption(context),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.hp(4)),
            Text(
              '연속 달성',
              style: AppTextStyles.getBody(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.hp(1)),
            dayStatus([1, -1, 1, 1, 1, -1, -1, 1, 1, 1, 0, 0], context),
            SizedBox(height: context.hp(4)),
            Text(
              '누적 활동 시간',
              style: AppTextStyles.getBody(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.hp(1)),
            Row(
              children: [
                Text(
                  '61h',
                  style: AppTextStyles.getTimeDisplay(context).copyWith(
                    fontFamily: 'chab',
                    color: Colors.redAccent,
                  ),
                ),
                Text(
                  ' | 100h',
                  style: AppTextStyles.getTimeDisplay(context).copyWith(
                    fontFamily: 'chab',
                    color: AppColors.backgroundTertiary(context),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 30,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 0), // 시작점
                        const FlSpot(1, 10),
                        const FlSpot(2, 25),
                        const FlSpot(3, 20),
                        const FlSpot(4, 30),
                        const FlSpot(5, 40),
                        const FlSpot(6, 35),
                        const FlSpot(7, 45),
                        const FlSpot(8, 60),
                        const FlSpot(9, 65),
                        const FlSpot(10, 70),
                      ],
                      isCurved: true,
                      color: Colors.redAccent,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.redAccent.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: 10,
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildDayWithReminder(
        BuildContext context, String day, bool isActive, Color? color) {
      return Column(
        children: [
          // 요일 텍스트
          Text(
            day,
            style: AppTextStyles.getCaption(context).copyWith(
              color: isActive ? AppColors.textPrimary(context) : Colors.grey,
            ),
          ),
          SizedBox(height: context.hp(1)),
          // 알림 원형 아이콘
          Container(
            width: context.xl,
            height: context.xl,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color : Colors.transparent,
              border: isActive
                  ? null
                  : Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
            ),
            child: isActive
                ? Icon(
                    LucideIcons.bell,
                    size: context.sm,
                    color: Colors.white,
                  )
                : null,
          ),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(color: AppColors.background(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: context.hp(4)),
                // 제목
                Padding(
                  padding: context.paddingSM,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '신규 기능 추가',
                        style: AppTextStyles.getBody(context).copyWith(
                          color: Colors.blueAccent,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            '목표 기능을\n준비 중이에요',
                            style:
                                AppTextStyles.getHeadline(context).copyWith(),
                          ),
                          SizedBox(width: context.wp(2)),
                          Shimmer.fromColors(
                            baseColor: Colors.orangeAccent,
                            highlightColor: Colors.white,
                            direction: ShimmerDirection.ltr,
                            child: Image.asset(
                              getIconImage('sparkles'),
                              width: context.xxl,
                              height: context.xxl,
                              errorBuilder: (context, error, stackTrace) {
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.hp(3)),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade400,
                  highlightColor: AppColors.background(context),
                  child: Text(
                    '목표를 정하세요',
                    style: AppTextStyles.getBody(context),
                  ),
                ),
                SizedBox(height: context.hp(1)),
                CarouselSlider.builder(
                  itemCount: goalSamples.length,
                  options: CarouselOptions(
                    height: 150,
                    enableInfiniteScroll: true,
                    viewportFraction: 0.5,
                    enlargeCenterPage: false,
                    autoPlay: true,
                  ),
                  itemBuilder:
                      (BuildContext context, int index, int realIndex) {
                    final goal = goalSamples[index];

                    return Container(
                      padding: context.paddingXS,
                      margin: context.paddingXS,
                      decoration: BoxDecoration(
                        color: ColorService.hexToColor(goal['color']),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary(context)
                                .withOpacity(0.08), // 그림자 색상
                            blurRadius: 10, // 그림자 흐림 정도
                            offset: const Offset(-2, 8), // 그림자 위치 (가로, 세로)
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            getIconImage(goal['icon']),
                            width: context.wp(15),
                            height: context.wp(15),
                            errorBuilder: (context, error, stackTrace) {
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
                          SizedBox(height: context.hp(2)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  goal['title'],
                                  style:
                                      AppTextStyles.getBody(context).copyWith(
                                    color: Colors.white,
                                    fontFamily: 'neo',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: context.hp(5)),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade400,
                  highlightColor: AppColors.background(context),
                  child: Text(
                    '목표 카드를 만드세요',
                    style: AppTextStyles.getBody(context),
                  ),
                ),
                SizedBox(height: context.hp(1)),
                goalCard(),
                SizedBox(height: context.hp(5)),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade400,
                  highlightColor: AppColors.background(context),
                  child: Text(
                    '목표를 추적하세요',
                    style: AppTextStyles.getBody(context),
                  ),
                ),
                SizedBox(height: context.hp(1)),
                goalChart(),
                SizedBox(height: context.hp(5)),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade400,
                  highlightColor: AppColors.background(context),
                  child: Text(
                    '목표를 관리하세요',
                    style: AppTextStyles.getBody(context),
                  ),
                ),
                SizedBox(height: context.hp(1)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0), // 둥근 모서리
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary(context)
                            .withOpacity(0.08), // 그림자 색상
                        blurRadius: 10, // 그림자 흐림 정도
                        offset: const Offset(-2, 8), // 그림자 위치 (가로, 세로)
                      ),
                    ],
                  ),
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '알림 스케줄',
                          style: AppTextStyles.getBody(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: context.hp(2)),
                        // 요일 표시 행
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDayWithReminder(
                                context, '월', true, Colors.blueAccent),
                            _buildDayWithReminder(
                                context, '화', true, Colors.blueAccent),
                            _buildDayWithReminder(
                                context, '수', true, Colors.blueAccent),
                            _buildDayWithReminder(
                                context, '목', false, Colors.transparent),
                            _buildDayWithReminder(
                                context, '금', true, Colors.orangeAccent),
                            _buildDayWithReminder(
                                context, '토', false, Colors.transparent),
                            _buildDayWithReminder(
                                context, '일', false, Colors.transparent),
                          ],
                        ),
                        SizedBox(height: context.hp(2)),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.bell,
                                    size: context.sm,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: context.wp(1)),
                                  Text(
                                    '오후 7:30',
                                    style: AppTextStyles.getCaption(context)
                                        .copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: context.wp(2)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.bell,
                                    size: context.sm,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: context.wp(1)),
                                  Text(
                                    '오후 9:30',
                                    style: AppTextStyles.getCaption(context)
                                        .copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(height: context.hp(10)),
                Container(
                  padding: context.paddingHorizSM,
                  child: Column(
                    children: [
                      _buildIntroLine(context, '여러 개의 목표 카드 생성'),
                      SizedBox(height: context.hp(1)),
                      _buildIntroLine(context, '상위 목표별로 목표 통합 관리'),
                      SizedBox(height: context.hp(1)),
                      _buildIntroLine(context, '목표 카드별 목표 시간/횟수 설정'),
                      SizedBox(height: context.hp(1)),
                      _buildIntroLine(context, '잊지 않도록 정해진 시간에 리마인드'),
                      SizedBox(height: context.hp(1)),
                      _buildIntroLine(context, '달성한 만큼 목표를 그래프로 확인'),
                      SizedBox(height: context.hp(1)),
                      _buildIntroLine(context, '활동 시 자동으로 목표 달성 체크'),
                      SizedBox(height: context.hp(1)),
                      _buildIntroLine(context, '다양한 목표 통계 제공'),
                    ],
                  ),
                ),
                SizedBox(height: context.hp(5)),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '이 기능이 마음에 드시나요?',
                      style: AppTextStyles.getBody(context),
                    ),
                    SizedBox(height: context.hp(0.5)),
                    Text(
                      '여러분의 의견을 들려주세요!',
                      style: AppTextStyles.getCaption(context),
                    ),
                    SizedBox(height: context.hp(2)),
                    Container(
                      margin: context.paddingHorizSM,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchURL(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(LucideIcons.send,
                            size: context.lg, color: Colors.white),
                        label: Text(
                          '출시되면 알려주세요',
                          style: AppTextStyles.getBody(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: context.hp(5)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
