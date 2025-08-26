import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/date_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/prefs_service.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class TotalSecondsCards extends StatefulWidget {
  const TotalSecondsCards({super.key});

  @override
  State<TotalSecondsCards> createState() => _TotalSecondsCardsState();
}

class _TotalSecondsCardsState extends State<TotalSecondsCards> {
  late DatabaseService _dbService;
  late TimerProvider _timerProvider;
  final prefsService = PrefsService();
  int currentTotalSeconds = 360000;
  int upComingTotalSeconds = PrefsService().totalSeconds;
  late int initialCardIndex;
  double _page = 0.0;

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    _timerProvider = Provider.of<TimerProvider>(context, listen: false);
    currentTotalSeconds = _timerProvider.timerData!['total_seconds'] ?? 360000;
    initialCardIndex = _findCardIndexByValue(currentTotalSeconds);
    _page = initialCardIndex.toDouble();
  }

  int _findCardIndexByValue(int value) {
    // 정확히 일치하는 값 찾기
    for (int i = 0; i < _cards.length; i++) {
      if (_cards[i].value == value) {
        return i;
      }
    }

    // 정확히 일치하는 값이 없으면 가장 가까운 값 찾기
    int closestIndex = 0;
    int minDiff = (value - _cards[0].value).abs();

    for (int i = 1; i < _cards.length; i++) {
      int diff = (value - _cards[i].value).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  void changeThisWeekTotalSeconds(int index) async {
    try {
      // timer update
      final thisWeek = DateService.getCurrentWeekStart();
      final timerId = await _dbService.getTimerId(thisWeek);

      if (timerId == null) {
        Fluttertoast.showToast(
          msg: "타이머가 존재하지 않습니다",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.redAccent.shade200,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        return;
      }

      final updateHour = (_cards[index].value / 3600).toInt();

      await _timerProvider.updateTotalSeconds(updateHour);
      Fluttertoast.showToast(
        msg: "${_cards[index].title}으로 목표가 변경되었습니다",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 14.0,
      );

      await FacebookAppEvents().logEvent(
        name: 'change_total_seconds',
        parameters: {
          'target': _cards[index].title,
        },
        valueToSum: 10,
      );

      Navigator.pop(context);
    } catch (e) {
      logger.e('e: $e');
      Fluttertoast.showToast(
        msg: "목표 변경 중 오류가 발생했습니다",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  void changePrefTotalSeconds(int index) {
    prefsService.totalSeconds = _cards[index].value;
  }

  List<TotalSecondsCardData> get _cards => const [
        TotalSecondsCardData(
          emoji: 'trophy',
          title: '주 100시간',
          subtitle: '모든 생산적인 활동을 기록해요',
          value: 360000,
        ),
        TotalSecondsCardData(
          emoji: 'fire',
          title: '주 80시간',
          subtitle: '하루 11~12시간씩,\n몰입하는 루틴을 만들어봐요',
          value: 288000,
        ),
        TotalSecondsCardData(
          emoji: 'high_voltage',
          title: '주 60시간',
          subtitle: '하루 8시간,\n일주일 동안 꾸준히 실천해요',
          value: 216000,
        ),
        TotalSecondsCardData(
          emoji: 'sparkles',
          title: '주 40시간',
          subtitle: '하루 5~6시간씩,\n일과 후 자기계발에 집중해요',
          value: 144000,
        ),
        TotalSecondsCardData(
          emoji: 'clapping',
          title: '주 20시간',
          subtitle: '하루 2~3시간씩,\n작은 루틴부터 시작해요',
          value: 72000,
        ),
        TotalSecondsCardData(
          emoji: 'smiling_face',
          title: '주 5시간',
          subtitle: '매일 퇴근 후 1시간씩,\n습관을 만들어봐요',
          value: 18000,
        ),
      ];

  Widget buildTotalSecondsCard(
      BuildContext context, TotalSecondsCardData card, int index) {
    return Card(
      color: AppColors.background(context),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.hp(1)),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        card.title,
                        style: AppTextStyles.getHeadline(context).copyWith(
                          fontWeight: FontWeight.w900,
                          fontFamily: 'neo',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: context.wp(2)),
                    card.value == currentTotalSeconds &&
                            currentTotalSeconds != upComingTotalSeconds
                        ? Row(
                            children: [
                              Text(
                                '이번주만 선택',
                                style:
                                    AppTextStyles.getCaption(context).copyWith(
                                  color: Colors.blueAccent,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(width: context.wp(1)),
                              Icon(
                                LucideIcons.checkCircle,
                                size: context.md,
                                color: Colors.blueAccent,
                              ),
                            ],
                          )
                        : const SizedBox(),
                    card.value == upComingTotalSeconds &&
                            currentTotalSeconds != upComingTotalSeconds
                        ? Row(
                            children: [
                              Text(
                                '다음 주 예정',
                                style:
                                    AppTextStyles.getCaption(context).copyWith(
                                  color: Colors.deepPurple,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(width: context.wp(1)),
                              Icon(
                                LucideIcons.checkCircle,
                                size: context.md,
                                color: Colors.deepPurple,
                              ),
                            ],
                          )
                        : const SizedBox(),
                    card.value == currentTotalSeconds &&
                            currentTotalSeconds == upComingTotalSeconds
                        ? Row(
                            children: [
                              Text(
                                '선택됨',
                                style:
                                    AppTextStyles.getCaption(context).copyWith(
                                  color: Colors.redAccent,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(width: context.wp(1)),
                              Icon(
                                LucideIcons.checkCircle,
                                size: context.md,
                                color: Colors.redAccent,
                              ),
                            ],
                          )
                        : const SizedBox(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  card.subtitle,
                  style: AppTextStyles.getBody(context),
                ),
              ],
            ),
            SizedBox(
              height: context.hp(15),
              width: double.infinity,
              child: Stack(
                children: [
                  ...List.generate(4, (index) {
                    // 위치 설정 (0: 좌상, 1: 우상, 2: 좌하, 3: 우하)
                    final isLeft = index == 0 || index == 2;
                    final isTop = index == 0 || index == 1;

                    return Positioned(
                      left: isLeft ? 0 : null,
                      right: !isLeft ? 0 : null,
                      top: isTop ? 0 : null,
                      bottom: !isTop ? 0 : null,
                      child: Opacity(
                        opacity: 0.3,
                        child: Image.asset(
                          getIconImage(card.emoji),
                          width: context.wp(12),
                          height: context.wp(12),
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: 1,
                      child: Image.asset(
                        getIconImage(card.emoji),
                        width: context.wp(40),
                        height: context.wp(40),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      changeThisWeekTotalSeconds(index);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentTotalSeconds == card.value
                          ? AppColors.backgroundSecondary(context)
                          : Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: Text(
                      '이번주만 바꾸기',
                      style: AppTextStyles.getBody(context).copyWith(
                        color: currentTotalSeconds == card.value
                            ? AppColors.textSecondary(context)
                            : Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.hp(1)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      changeThisWeekTotalSeconds(index);
                      changePrefTotalSeconds(index);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: upComingTotalSeconds == card.value
                          ? AppColors.backgroundSecondary(context)
                          : Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: Text(
                      '이번주부터 쭉 바꾸기',
                      style: AppTextStyles.getBody(context).copyWith(
                        color: upComingTotalSeconds == card.value
                            ? AppColors.textSecondary(context)
                            : Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context), // 모달 전체 탭 시 닫기
      child: Center(
        child: SizedBox(
          height: context.hp(100),
          child: CarouselSlider.builder(
            itemCount: _cards.length,
            options: CarouselOptions(
              height: context.hp(70),
              viewportFraction: 0.8,
              enlargeCenterPage: true,
              padEnds: true,
              enableInfiniteScroll: false,
              initialPage: initialCardIndex,
              onScrolled: (pos) => setState(() => _page = pos ?? 0.0),
            ),
            itemBuilder: (context, index, realIndex) {
              final double offset = _page - index;
              final double angle = offset * 0.12;

              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 50,
                      width: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background(context),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(LucideIcons.x,
                          size: context.xl,
                          color: AppColors.textPrimary(context)),
                    ),
                  ),
                  SizedBox(height: context.hp(2)),
                  GestureDetector(
                    onTap: () {},
                    child: Transform.rotate(
                      angle: angle,
                      child: Container(
                        height: context.hp(50),
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: buildTotalSecondsCard(
                            context, _cards[index], index),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class TotalSecondsCardData {
  final String emoji;
  final String title;
  final String subtitle;
  final int value;
  const TotalSecondsCardData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.value,
  });
}
