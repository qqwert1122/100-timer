import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';

class TotalSecondsCards extends StatefulWidget {
  const TotalSecondsCards({super.key});

  @override
  State<TotalSecondsCards> createState() => _TotalSecondsCardsState();
}

class _TotalSecondsCardsState extends State<TotalSecondsCards> {
  final CarouselController _controller = CarouselController();
  double _page = 0.0;

  List<TotalSecondsCardData> get _cards => const [
        TotalSecondsCardData(
          emoji: 'trophy',
          title: '주 100시간',
          subtitle: '모든 생산적인 활동을 기록해요',
          value: 100,
        ),
        TotalSecondsCardData(
          emoji: 'high_voltage',
          title: '주 80시간',
          subtitle: '하루 11~12시간씩,\n몰입하는 루틴을 만들어봐요',
          value: 80,
        ),
        TotalSecondsCardData(
          emoji: 'sparkles',
          title: '주 60시간',
          subtitle: '하루 8시간,\n일주일 동안 꾸준히 실천해요',
          value: 60,
        ),
        TotalSecondsCardData(
          emoji: 'star',
          title: '주 40시간',
          subtitle: '하루 5~6시간씩,\n일과 후 자기계발에 집중해요',
          value: 40,
        ),
        TotalSecondsCardData(
          emoji: 'clapping',
          title: '주 20시간',
          subtitle: '하루 2~3시간씩,\n작은 루틴부터 시작해요',
          value: 20,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context), // 모달 전체 탭 시 닫기
      child: Center(
        child: CarouselSlider.builder(
          itemCount: _cards.length,
          options: CarouselOptions(
            viewportFraction: 0.8,
            enlargeCenterPage: true,
            onScrolled: (pos) => setState(() => _page = pos ?? 0.0),
          ),
          itemBuilder: (context, index, realIndex) {
            final double offset = _page - index;
            final double angle = offset * 0.12;

            return Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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
                Transform.rotate(
                  angle: angle,
                  child: Container(
                    height: context.hp(50),
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: _TotalSecondsCard(card: _cards[index]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TotalSecondsCard extends StatelessWidget {
  final TotalSecondsCardData card;
  const _TotalSecondsCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                Text(
                  card.title,
                  style: AppTextStyles.getHeadline(context).copyWith(
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Neo',
                  ),
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
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.asset(
                        getIconImage(card.emoji),
                        width: context.wp(12),
                        height: context.wp(12),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.asset(
                        getIconImage(card.emoji),
                        width: context.wp(12),
                        height: context.wp(12),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.asset(
                        getIconImage(card.emoji),
                        width: context.wp(12),
                        height: context.wp(12),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.asset(
                        getIconImage(card.emoji),
                        width: context.wp(12),
                        height: context.wp(12),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
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
                Container(
                  margin: context.paddingHorizXS,
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
                    label: Text(
                      '이번주만 바꾸기',
                      style: AppTextStyles.getBody(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.hp(1)),
                Container(
                  margin: context.paddingHorizXS,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: Text(
                      '이번주부터 쭉 바꾸기',
                      style: AppTextStyles.getBody(context).copyWith(
                        color: Colors.white,
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
