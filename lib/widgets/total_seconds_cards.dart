import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';

class TotalSecondsCards extends StatelessWidget {
  const TotalSecondsCards({super.key});

  List<TotalSecondsCardData> get _cards => const [
        TotalSecondsCardData(
          emoji: 'fire',
          title: '100시간',
          subtitle: '모든 생산적인 활동을 기록해요',
        ),
        TotalSecondsCardData(
          emoji: 'high_voltage',
          title: '80시간',
          subtitle: '주중 집중! 평일 5일간 하루 16시간 몰입을 목표로 해요',
        ),
        TotalSecondsCardData(
          emoji: 'sparkles',
          title: '60시간',
          subtitle: '하루 8시간, 일주일 동안 꾸준히 실천해요',
        ),
        TotalSecondsCardData(
          emoji: 'star',
          title: '40시간',
          subtitle: '하루 5~6시간씩, 일과 후 자기계발에 집중해요',
        ),
        TotalSecondsCardData(
          emoji: 'clapping',
          title: '20시간',
          subtitle: '하루 2~3시간씩, 작은 루틴부터 시작해요',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Center(
        // 중앙 정렬 (또는 Positioned로 위치 조절 가능)
        child: PageView.builder(
          itemCount: _cards.length,
          controller: PageController(viewportFraction: 0.8),
          itemBuilder: (context, index) {
            return Column(
              children: [
                SizedBox(height: context.hp(15)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 50,
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background(context).withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      LucideIcons.x,
                      size: context.xl,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
                SizedBox(height: context.hp(2)),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: context.hp(50),
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _TotalSecondsCard(card: _cards[index]),
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
                    label: Text(
                      '변경',
                      style: AppTextStyles.getBody(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
          children: [
            /* 이모지 */
            Image.asset(
              getIconImage(card.emoji),
              width: context.wp(20),
              height: context.wp(20),
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            /* 제목 */
            Text(
              card.title,
              style: AppTextStyles.getHeadline(context)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            /* 내용 */
            Text(
              card.subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.getBody(context),
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
  const TotalSecondsCardData({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}
