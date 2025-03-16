import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  List<Map<String, dynamic>> avatarList = [
    {'name': '하트', 'price': 100, 'url': 'https://api.dicebear.com/9.x/thumbs/svg?seed=Leo&radius=50', 'api': true},
    {'name': '찡긋', 'price': 100, 'url': 'https://api.dicebear.com/9.x/thumbs/svg?seed=Sadie&radius=50', 'api': true},
    {'name': '흐믓', 'price': 100, 'url': 'https://api.dicebear.com/9.x/thumbs/svg?seed=Robert&radius=50', 'api': true},
    {'name': '음', 'price': 100, 'url': 'https://api.dicebear.com/9.x/thumbs/svg?seed=Jessica&radius=50', 'api': true},
    {'name': '하하', 'price': 100, 'url': 'https://api.dicebear.com/9.x/thumbs/svg?seed=Kingston&radius=50', 'api': true},
    {'name': '블루래빗', 'price': 200, 'url': 'assets/images/avatar_rabbit_1.png', 'api': false},
    {'name': '탄이', 'price': 300, 'url': 'assets/images/avatar_burning_1.png', 'api': false},
    {'name': '해파리', 'price': 300, 'url': 'assets/images/avatar_ghost_1.png', 'api': false},
    {'name': '냥', 'price': 100, 'url': 'assets/images/avatar_cat_1.png', 'api': false},
    {'name': '남자', 'price': 100, 'url': 'assets/images/avatar_man_1.png', 'api': false},
    {'name': '여자1', 'price': 100, 'url': 'assets/images/avatar_woman_1.png', 'api': false},
    {'name': '여자2', 'price': 100, 'url': 'assets/images/avatar_woman_2.png', 'api': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상점', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '귀여운 캐릭터',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              GridView.builder(
                padding: const EdgeInsets.all(32.0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: avatarList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 한 줄에 3개씩
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 0.7, // 가로세로 비율 조정
                ),
                itemBuilder: (context, index) {
                  final avatar = avatarList[index];

                  return Column(
                    children: [
                      avatar['api']
                          ? SvgPicture.network(
                              avatar['url'],
                              width: 50,
                              height: 50,
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                image: DecorationImage(
                                  // Container의 배경 이미지로 설정
                                  image: AssetImage(avatar['url']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                      Text(
                        avatar['name'],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${avatar['price'].toString()}원',
                        style: const TextStyle(fontSize: 12),
                      )
                    ],
                  );
                },
              ),
              const Text(
                '잠금 해제',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              const Text(
                '이런 상품 어때요?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              const SizedBox(
                height: 100,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
