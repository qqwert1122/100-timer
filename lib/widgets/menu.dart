import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project1/screens/invite_page.dart';
import 'package:project1/screens/member_page.dart';
import 'package:project1/screens/onboarding_page.dart';
import 'package:project1/screens/shop_page.dart';
import 'package:project1/screens/tip_page.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> menuItems = [
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
    {
      'title': '구독',
      'description': '구독하고 다양한 기능을 제공받으세요',
      'icon': Icons.shopping_cart_rounded,
      'color': Colors.amberAccent,
      'imageUrl': 'assets/images/sticker_cart_7.png',
      'size': [130.0, 130.0],
      'position': [-10.0, -10.0],
      'landingPage': TipPage(),
    },
    {
      'title': '초대',
      'description': '친구를 초대하고 다양한 기능을 제공받으세요',
      'icon': Icons.card_giftcard_rounded,
      'color': Colors.pink[200],
      'imageUrl': 'assets/images/sticker_invite_3.png',
      'size': [180.0, 180.0],
      'position': [-40.0, -40.0],
      'landingPage': InvitePage(),
    },
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
      'imageUrl': 'assets/images/sticker_onboarding_4.png',
      'size': [160.0, 160.0],
      'position': [-20.0, -20.0],
      'landingPage': OnboardingPage(),
    },
  ];

  String userName = '양조현'; // 사용자 이름 변수
  String avatarUrl = 'https://api.dicebear.com/5.x/avataaars/svg?seed=User'; // 아바타 이미지 URL

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // 애니메이션 컨트롤러 초기화 등 필요한 초기화 코드
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    // 애니메이션 컨트롤러 dispose 등 필요한 해제 코드
    _controller.dispose();
    super.dispose();
  }

  Color darken(Color color, [double amount = 0.2]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final timerProvider = Provider.of<TimerProvider>(context);

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            // 프로필 구역 추가
            Container(
              padding: const EdgeInsets.all(32.0),
              margin: const EdgeInsets.only(top: 32.0, left: 32.0, right: 32.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.deepPurple,
                    Colors.blueAccent,
                  ],
                  stops: const [0.0, 1.0],
                ),
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "프로필" 제목
                  const Text(
                    '프로필 👑',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '잔여시간 ${timerProvider.formattedTime}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      SvgPicture.network(
                        'https://api.dicebear.com/9.x/thumbs/svg?seed=${userName}&radius=50',
                        width: 75,
                        height: 75,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // 이름 변경 로직
                            _changeUserName();
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: const Text(
                            '이름변경',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // 이름 변경 로직
                            _changeUserName();
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: const Text(
                            '아바타 변경',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(top: 10.0, left: 32.0, right: 32.0),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Text('광고 영역'),
            ),
            GridView.builder(
              padding: const EdgeInsets.all(32.0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menuItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2열
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                childAspectRatio: 0.9, // 비율 설정
              ),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final startColor = item['color'] as Color;
                final endColor = darken(startColor, 0.2); // 그라데이션 끝 색상

                return InkWell(
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
                              width: item['size'][0], // 이미지의 너비
                              height: item['size'][1], // 이미지의 높이
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
                    ),
                  ),
                );
              },
            ),
            const SizedBox(
              height: 100,
            ),
          ],
        ),
      ),
    );
  }

  // 이름 변경 함수
  void _changeUserName() async {
    String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempName = userName;
        return AlertDialog(
          title: const Text('이름 변경'),
          content: TextField(
            onChanged: (value) {
              tempName = value;
            },
            controller: TextEditingController(text: userName),
            decoration: const InputDecoration(
              hintText: '새로운 이름을 입력하세요',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 취소
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(tempName); // 새로운 이름 반환
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    if (newName!.isNotEmpty) {
      setState(() {
        userName = newName;
      });
    }
  }
}
