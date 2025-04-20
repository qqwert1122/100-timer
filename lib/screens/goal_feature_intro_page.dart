import 'dart:ffi';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class GoalFeatureIntroPage extends StatelessWidget {
  final String interestFormUrl;

  GoalFeatureIntroPage({
    Key? key,
    this.interestFormUrl = 'https://your-google-form-url.com',
  }) : super(key: key);

  void _launchURL() async {
    final uri = Uri.parse(interestFormUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    Widget _samPleBadge({
      required Color backgroundColor,
      required String label,
      required Color textColor,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: context.sm,
          ),
        ),
      );
    }

    Widget _samPleCalendarBadge({
      required String label,
    }) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.background(context),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                SizedBox(width: context.wp(1)),
                Icon(
                  LucideIcons.calendarDays,
                  size: context.sm,
                ),
                _samPleBadge(
                  backgroundColor: AppColors.background(context),
                  label: label,
                  textColor: AppColors.textPrimary(context),
                ),
              ],
            ),
          ),
          SizedBox(width: context.wp(0.5)),
          Text(
            '까지',
            style: TextStyle(fontSize: context.sm),
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

    Widget _sampleGoalCard1() {
      return Container(
        padding: context.paddingSM,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background(context),
          boxShadow: [
            BoxShadow(
              color: AppColors.backgroundTertiary(context),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                SizedBox(width: context.wp(2)),
                Text(
                  '바디프로필 찍기',
                  style: AppTextStyles.getTitle(context).copyWith(
                    fontFamily: 'Neo',
                  ),
                ),
              ],
            ),
            Divider(color: AppColors.backgroundSecondary(context)),
            SizedBox(height: context.hp(1)),
            Text(
              '  목표 카드',
              style: AppTextStyles.getBody(context).copyWith(
                fontFamily: 'Neo',
              ),
            ),
            SizedBox(height: context.hp(1)),
            Container(
              width: double.infinity,
              padding: context.paddingSM,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDarkMode ? Colors.indigo : Colors.indigo.shade50,
                    isDarkMode ? Colors.blueAccent : Colors.blue.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.backgroundTertiary(context),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        getIconImage('running'),
                        width: context.xl,
                        height: context.xl,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: context.xl,
                            height: context.xl,
                            color: Colors.grey.withOpacity(0.2),
                            child: Icon(Icons.broken_image, size: context.xl, color: Colors.grey),
                          );
                        },
                      ),
                      SizedBox(width: context.wp(2)),
                      Text(
                        '러닝',
                        style: AppTextStyles.getBody(context).copyWith(
                          fontFamily: 'Neo',
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white),
                  SizedBox(height: context.hp(1)),
                  Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: context.wp(2),
                    runSpacing: context.hp(1),
                    children: [
                      _samPleCalendarBadge(label: '2025-12-31'),
                      _samPleBadge(
                        backgroundColor: AppColors.background(context),
                        label: '매일',
                        textColor: AppColors.textPrimary(context),
                      ),
                      _samPleBadge(
                        backgroundColor: Colors.blueAccent,
                        label: '러닝',
                        textColor: Colors.white,
                      ),
                      _samPleBadge(
                        backgroundColor: Colors.indigo,
                        label: '30분',
                        textColor: Colors.white,
                      ),
                      Text(
                        '하기',
                        style: TextStyle(
                          fontSize: context.sm,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.hp(1)),
                  Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: context.wp(2),
                    runSpacing: context.hp(1),
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '성공 조건 | 90% 이상',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: context.sm,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.alarmClock,
                              size: context.md,
                            ),
                            SizedBox(width: context.wp(1)),
                            Text(
                              '매일 06:00',
                              style: TextStyle(
                                fontSize: context.sm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                        '17',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sm,
                          color: Colors.blueAccent,
                        ),
                      ),
                      Text(
                        '/248회',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sm,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '|',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.sm,
                      color: Colors.grey,
                    ),
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
                        '7% 달성',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sm,
                          color: Colors.grey,
                        ),
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
                        '누적 활동 시간   9h 32m',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sm,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: context.hp(4)),
            Container(
              width: double.infinity,
              padding: context.paddingSM,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDarkMode ? Colors.pink : Colors.pinkAccent.shade100,
                    isDarkMode ? Colors.amberAccent : Colors.amber.shade200,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.backgroundTertiary(context),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        getIconImage('fitness'),
                        width: context.xl,
                        height: context.xl,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: context.xl,
                            height: context.xl,
                            color: Colors.grey.withOpacity(0.2),
                            child: Icon(Icons.broken_image, size: context.xl, color: Colors.grey),
                          );
                        },
                      ),
                      SizedBox(width: context.wp(2)),
                      Text(
                        '피트니스',
                        style: AppTextStyles.getBody(context).copyWith(
                          fontFamily: 'Neo',
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white),
                  SizedBox(height: context.hp(1)),
                  Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: context.wp(2),
                    runSpacing: context.hp(1),
                    children: [
                      _samPleCalendarBadge(label: '3개월'),
                      _samPleBadge(
                        backgroundColor: AppColors.background(context),
                        label: '매주',
                        textColor: AppColors.textPrimary(context),
                      ),
                      _samPleBadge(
                        backgroundColor: Colors.yellow,
                        label: '피트니스',
                        textColor: Colors.black,
                      ),
                      _samPleBadge(
                        backgroundColor: Colors.indigo,
                        label: '3회',
                        textColor: Colors.white,
                      ),
                      Text(
                        '하기',
                        style: TextStyle(
                          fontSize: context.sm,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.hp(1)),
                  Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: context.wp(2),
                    runSpacing: context.hp(1),
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '성공 조건 | 90% 이상',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: context.sm,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.alarmClock,
                              size: context.md,
                            ),
                            SizedBox(width: context.wp(1)),
                            Text(
                              '월,수,금 09:00',
                              style: TextStyle(
                                fontSize: context.sm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: context.hp(2)),
            Padding(
              padding: context.paddingHorizXS,
              child: dayStatus([1, 1, 0, 0, 0, 0, 0, 0, 0, 0], context),
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
                        '2',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sm,
                          color: Colors.blueAccent,
                        ),
                      ),
                      Text(
                        '/12회',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sm,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '|',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.sm,
                      color: Colors.grey,
                    ),
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
                        '16% 달성',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sm,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '|',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.sm,
                      color: Colors.grey,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.trendingUp,
                        size: context.lg,
                        color: AppColors.primary(context),
                      ),
                      SizedBox(width: context.wp(1)),
                      Text(
                        '2주 연속 달성!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sm,
                          color: AppColors.primary(context),
                        ),
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

    Widget _sampleGoalCard2() {
      return Container(
        padding: context.paddingSM,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background(context),
          boxShadow: [
            BoxShadow(
              color: AppColors.backgroundTertiary(context),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  getIconImage('hundred'),
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
                SizedBox(width: context.wp(2)),
                Text(
                  '영어점수 100점 맞기',
                  style: AppTextStyles.getTitle(context).copyWith(
                    fontFamily: 'Neo',
                  ),
                ),
              ],
            ),
            Divider(color: AppColors.backgroundSecondary(context)),
            SizedBox(height: context.hp(1)),
            Text(
              '  목표 카드',
              style: AppTextStyles.getBody(context).copyWith(
                fontFamily: 'Neo',
              ),
            ),
            SizedBox(height: context.hp(1)),
            Container(
              width: double.infinity,
              padding: context.paddingSM,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDarkMode ? Colors.purple : Colors.purple.shade50,
                    isDarkMode ? Colors.blueAccent : Colors.blue.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.backgroundTertiary(context),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        getIconImage('writing'),
                        width: context.xl,
                        height: context.xl,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: context.xl,
                            height: context.xl,
                            color: Colors.grey.withOpacity(0.2),
                            child: Icon(Icons.broken_image, size: context.xl, color: Colors.grey),
                          );
                        },
                      ),
                      SizedBox(width: context.wp(2)),
                      Text(
                        '영단어 50개 암기',
                        style: AppTextStyles.getBody(context).copyWith(
                          fontFamily: 'Neo',
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white),
                  SizedBox(height: context.hp(1)),
                  Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: context.wp(2),
                    runSpacing: context.hp(1),
                    children: [
                      _samPleCalendarBadge(label: '6월'),
                      _samPleBadge(
                        backgroundColor: AppColors.background(context),
                        label: '매주',
                        textColor: AppColors.textPrimary(context),
                      ),
                      _samPleBadge(
                        backgroundColor: Colors.deepPurple,
                        label: '영단어 50개 암기',
                        textColor: Colors.white,
                      ),
                      _samPleBadge(
                        backgroundColor: Colors.indigo,
                        label: '2회',
                        textColor: Colors.white,
                      ),
                      Text(
                        '하기',
                        style: TextStyle(
                          fontSize: context.sm,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.hp(1)),
                  Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: context.wp(2),
                    runSpacing: context.hp(1),
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '성공 조건 | 90% 이상',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: context.sm,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.alarmClock,
                              size: context.md,
                            ),
                            SizedBox(width: context.wp(1)),
                            Text(
                              '화,목 14:00',
                              style: TextStyle(
                                fontSize: context.sm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: context.hp(2)),
            Padding(
              padding: context.paddingHorizXS,
              child: dayStatus([1, 1, 0, 0, 0, 0, 0, 0, 0, 0], context),
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
                        '2',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sm,
                          color: Colors.blueAccent,
                        ),
                      ),
                      Text(
                        '/8회',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sm,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '|',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.sm,
                      color: Colors.grey,
                    ),
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
                        '25% 달성',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sm,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '|',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.sm,
                      color: Colors.grey,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.trendingUp,
                        size: context.md,
                        color: AppColors.primary(context),
                      ),
                      SizedBox(width: context.wp(1)),
                      Text(
                        '2주 연속 달성!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sm,
                          color: AppColors.primary(context),
                        ),
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(color: AppColors.backgroundSecondary(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: context.hp(8)),
                // 제목
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '목표 기능을 준비중이에요',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.getHeadline(context).copyWith(
                        color: AppColors.primary(context),
                        fontFamily: 'Neo',
                      ),
                    ),
                    SizedBox(width: context.wp(1)),
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
                SizedBox(height: context.hp(2)),
                Container(
                  margin: context.paddingHorizSM,
                  padding: context.paddingHorizSM,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                SizedBox(height: context.hp(8)),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade400,
                  highlightColor: AppColors.background(context),
                  child: Text(
                    ' - 목표 기능은 이렇게 생겼어요 - ',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: context.md,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Neo',
                    ),
                  ),
                ),
                SizedBox(height: context.hp(2)),
                _sampleGoalCard1(),
                SizedBox(height: context.hp(4)),
                _sampleGoalCard2(),
                SizedBox(height: context.hp(1)),
                Text(
                  '목표 기능/디자인은 일부 다르게 출시될 수 있어요',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: context.sm,
                  ),
                ),
                SizedBox(height: context.hp(10)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '이 기능이 마음에 드시나요?',
                      style: TextStyle(
                        fontSize: context.md,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: context.hp(0.5)),
                    Text(
                      '여러분의 의견을 들려주세요!',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: context.sm,
                      ),
                    ),
                    SizedBox(height: context.hp(2)),
                    Container(
                      margin: context.paddingHorizSM,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(LucideIcons.send, size: context.lg, color: Colors.white),
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

  Widget _buildIntroLine(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          LucideIcons.checkCircle,
          size: context.lg,
          color: AppColors.textPrimary(context),
        ),
        SizedBox(width: context.wp(2)),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.getBody(context).copyWith(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
