import 'package:flutter/material.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:async';

class SubscriptionBottomSheet extends StatefulWidget {
  const SubscriptionBottomSheet({super.key});

  @override
  State<SubscriptionBottomSheet> createState() => _SubscriptionBottomSheetState();
}

class _SubscriptionBottomSheetState extends State<SubscriptionBottomSheet> {
  int _currentCarouselIndex = 0;
  bool _yearlySelected = true;
  late Timer _promotionTimer;
  int _remainingSeconds = 5 * 3600 + 23 * 60 + 45; // 05:23:45

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _promotionTimer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _promotionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _formatTime() {
    int hours = _remainingSeconds ~/ 3600;
    int minutes = (_remainingSeconds % 3600) ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> testimonials = [
      {"name": "민지(27세)", "text": "매일 조금씩 영어 공부하는 시간을 모으다 보니 어느새 외국인 친구와 대화가 됐어요! 작은 성취감이 정말 큰 기쁨이 되더라구요 😊"},
      {"name": "준혁(31세)", "text": "넷플릭스만 보던 저녁 시간에 책 읽기 도전! 일년 동안 쌓인 책이 벽을 이루고 친구들이 제 서재를 부러워해요 📚"},
      {"name": "소연(25세)", "text": "매일 15분씩 그림 연습한 결과, 이제 친구들 프사를 그려줄 수 있게 됐어요! 작은 부업까지 생겼답니다 🎨"}
    ];

    return Container(
      width: context.wp(100),
      height: context.hp(100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFF6B6B), // 밝은 빨간색
            const Color(0xFFFF8E3C), // 주황색
            AppColors.background(context),
          ],
          stops: const [0.0, 0.3, 0.7],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: context.paddingSM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더 부분
                  SizedBox(height: context.hp(5)),
                  Text(
                    '우리 함께 100시간을\n더 열정적으로 보내요 ✨',
                    style: AppTextStyles.getHeadline(context).copyWith(
                      fontFamily: 'neo',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.hp(2)),

                  // 서브 헤더
                  Container(
                    width: context.wp(100),
                    padding: EdgeInsets.all(context.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '시간이 부족한 게 아니에요,\n우리가 더 열정적으로 써볼 시간이에요!',
                      style: AppTextStyles.getBody(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: context.hp(3)),

                  // 프로 기능 카드들
                  Text(
                    '🦄 프로 버전에서 만날 수 있는 것들',
                    style: AppTextStyles.getTitle(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.hp(1)),
                ],
              ),
            ),
            // 기능 카드 컨테이너
            Container(
              height: context.hp(20),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFeatureCard(context, '귀여운 AI 친구', '당신의 시간 사용을 분석해주는 작은 비서', Icons.smart_toy),
                  _buildFeatureCard(context, '컬러풀 성장 그래프', '당신의 노력이 예쁜 그래프로 변신!', Icons.show_chart),
                  _buildFeatureCard(context, '맞춤형 도전 미션', '오늘은 독서 30분 어때요?', Icons.emoji_events),
                  _buildFeatureCard(context, '응원 커뮤니티', '같은 목표를 가진 친구들과 함께 으쌰으쌰!', Icons.groups),
                  _buildFeatureCard(context, '습관 형성 스티커판', '21일 동안 모으는 귀여운 디지털 스티커', Icons.stars),
                ],
              ),
            ),
            SizedBox(height: context.hp(3)),

            // 사용자 후기 캐러셀
            Padding(
              padding: context.paddingSM,
              child: Text(
                '프로 버전 친구들의 이야기',
                style: AppTextStyles.getTitle(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: context.hp(1)),
            CarouselSlider(
              options: CarouselOptions(
                  enlargeCenterPage: true,
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enableInfiniteScroll: true,
                  autoPlayAnimationDuration: Duration(milliseconds: 800),
                  viewportFraction: 0.8,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentCarouselIndex = index;
                    });
                  }),
              items: testimonials.map((item) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.all(context.md),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item["text"]!,
                            style: AppTextStyles.getBody(context),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "- ${item["name"]!}",
                            style: AppTextStyles.getCaption(context).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: testimonials.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentCarouselIndex == entry.key ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: context.hp(3)),

            // 구독 옵션
            Container(
              padding: EdgeInsets.all(context.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘의 나와 미래의 나, 어떻게 연결해볼까요?',
                    style: AppTextStyles.getBody(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.hp(1)),

                  // 토글 스위치
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _yearlySelected = false;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_yearlySelected ? const Color(0xFFFF8E3C) : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                '한 달 놀이',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !_yearlySelected ? Colors.white : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _yearlySelected = true;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _yearlySelected ? const Color(0xFFFF6B6B) : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                '일 년 놀이 (25% 할인)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _yearlySelected ? Colors.white : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.hp(2)),

                  // 가격 표시
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _yearlySelected ? '89,000원/년' : '9,900원/월',
                          style: AppTextStyles.getHeadline(context).copyWith(
                            fontWeight: FontWeight.bold,
                            color: _yearlySelected ? const Color(0xFFFF6B6B) : const Color(0xFFFF8E3C),
                          ),
                        ),
                        if (_yearlySelected)
                          Text(
                            '(월 7,416원)',
                            style: AppTextStyles.getCaption(context),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.hp(1)),

                  // 혜택 텍스트
                  Center(
                    child: Text(
                      '오늘 시작하면 7일 동안 무료로 놀 수 있어요 + 귀여운 시간 관리 e북도 드려요!',
                      style: AppTextStyles.getCaption(context),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: context.hp(2)),

                  // 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _yearlySelected ? const Color(0xFFFF6B6B) : const Color(0xFFFF8E3C),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '프로 친구 되기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.hp(2)),

            // 타이머 배너
            Container(
              padding: EdgeInsets.all(context.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B6B),
                    const Color(0xFFFF8E3C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '깜짝 선물 타임',
                        style: AppTextStyles.getTitle(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.card_giftcard, color: Colors.white, size: 24),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '오늘 하루만! 일 년 친구 되면 추가 10% 할인받을 수 있어요.',
                    style: AppTextStyles.getBody(context).copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '선물 상자가 닫히기까지: ${_formatTime()}',
                      style: TextStyle(
                        color: const Color(0xFFFF6B6B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.hp(2)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String description, IconData icon) {
    return Container(
      width: context.wp(60),
      margin: EdgeInsets.only(right: context.sm),
      padding: EdgeInsets.all(context.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFF6B6B), size: 30),
          SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.getBody(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: AppTextStyles.getCaption(context),
          ),
        ],
      ),
    );
  }
}
