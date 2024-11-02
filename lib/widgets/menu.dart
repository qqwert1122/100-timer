import 'package:flutter/material.dart';
import 'package:project1/screens/member_page.dart';
import 'package:project1/screens/onboarding_page.dart';
import 'package:project1/screens/tip_page.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> menuItems = [
    {
      'title': '팁',
      'description': '사용법을 확인하세요',
      'icon': Icons.tips_and_updates_outlined,
      'color': Colors.orangeAccent,
      'imageUrl': 'assets/images/sticker_tip_4.png',
      'size': [130.0, 130.0],
      'position': [-10.0, -0.0],
      'landingPage': TipPage(),
    },
    {
      'title': '온보딩',
      'description': '친구를 초대하고 다양한 기능을 제공받으세요',
      'icon': Icons.card_giftcard_rounded,
      'color': Colors.deepOrangeAccent,
      'imageUrl': 'assets/images/sticker_onboarding_3.png',
      'size': [135.0, 135.0],
      'position': [-10.0, -10.0],
      'landingPage': OnboardingPage(),
    },
    {
      'title': '초대',
      'description': '친구를 초대하고 다양한 기능을 제공받으세요',
      'icon': Icons.card_giftcard_rounded,
      'color': Colors.pink[200],
      'imageUrl': 'assets/images/sticker_invite_3.png',
      'size': [180.0, 180.0],
      'position': [-40.0, -40.0],
      'landingPage': TipPage(),
    },
    {
      'title': '구독',
      'description': '구독하고 다양한 기능을 제공받으세요',
      'icon': Icons.payments_rounded,
      'color': Colors.redAccent,
      'imageUrl': 'assets/images/sticker_bill_4.png',
      'size': [150.0, 150.0],
      'position': [-20.0, -20.0],
      'landingPage': TipPage(),
    },
    {
      'title': '상점',
      'description': '활동에 유용한 물건을 구경하세요',
      'icon': Icons.shopping_cart_rounded,
      'color': Colors.amberAccent,
      'imageUrl': 'assets/images/sticker_cart_7.png',
      'size': [130.0, 130.0],
      'position': [-10.0, -10.0],
      'landingPage': TipPage(),
    },
    {
      'title': '멤버',
      'description': '멤버들과 활동시간을 공유해요',
      'icon': Icons.group_rounded,
      'color': Colors.blue[100],
      'imageUrl': 'assets/images/sticker_group_7.png',
      'size': [140.0, 140.0],
      'position': [-10.0, -10.0],
      'landingPage': MemberPage(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    late AnimationController _controller;
    late Animation<double> _fadeAnimation;

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
      _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
      _controller.forward();
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    Color darken(Color color, [double amount = 0.2]) {
      final hsl = HSLColor.fromColor(color);
      final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
      return hslDark.toColor();
    }

    return Center(
      child: GridView.builder(
        padding: const EdgeInsets.all(32.0),
        shrinkWrap: true,
        itemCount: menuItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2열
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          childAspectRatio: 0.9, // 정사각형
        ),
        itemBuilder: (context, index) {
          final item = menuItems[index];
          final startColor = item['color'] as Color;
          final endColor = darken(startColor, 0.2); // 그라데이션 끝 색상

          return GestureDetector(
            onTap: () {
              final landingPage = item['landingPage'];
              if (landingPage != null && landingPage is Widget) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => landingPage,
                  ),
                );
              } else {
                // landingPage가 null이거나 Widget이 아닌 경우 처리
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('페이지가 정의되지 않았습니다.')),
                );
              }
            },
            child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      startColor.withOpacity(0.9),
                      endColor,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(16.0), // 둥근 모서리
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // 그림자 위치
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Text(
                        item['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    if (item['imageUrl'] != null)
                      Positioned(
                        right: item['position'][0], // 카드 밖으로 살짝 넘기기
                        bottom: item['position'][1],
                        child: SizedBox(
                          width: item['size'][0], // GIF 이미지의 너비
                          height: item['size'][1], // GIF 이미지의 높이
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.asset(
                              item['imageUrl']!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                  ],
                )),
          );
        },
      ),
    );
  }
}
