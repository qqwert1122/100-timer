import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final List<String> activities = [
    '전체',
    '운동',
    '공부',
    '독서',
    '명상',
    '요리',
    '산책',
    '기타'
  ];
  int _currentActivityIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: activities.length + 1,
          itemBuilder: (context, index, realIndex) {
            final isCentered = index == _currentActivityIndex;
            final opacity = isCentered ? 1.0 : 0.4;
            final fontSize = isCentered ? 32.0 : 20.0;
            if (index == activities.length) {
              // 마지막 아이템은 '추가' 버튼
              return GestureDetector(
                onTap: () {},
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  transform:
                      Matrix4.translationValues(0, isCentered ? -30 : -25, 0),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // 그림자 색상
                          spreadRadius: 2, // 그림자 퍼짐 정도
                          blurRadius: 10, // 그림자 흐림 정도
                          offset: const Offset(0, 4), // 그림자 위치 (x, y)
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, -1), // 위쪽 그림자 추가
                          blurRadius: 5,
                        ),
                      ], // 그림자로 3D 효과 추가
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit, // '+' 아이콘
                          size: fontSize,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8), // 텍스트와 아이콘 사이의 간격
                        Text(
                          '편집',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            shadows: [
                              Shadow(
                                offset: const Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Colors.grey.shade700,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return Opacity(
                opacity: opacity,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    activities[index],
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color:
                          isCentered ? Colors.redAccent.shade200 : Colors.grey,
                    ),
                  ),
                ),
              );
            }
          },
          options: CarouselOptions(
            height: 100,
            initialPage: _currentActivityIndex,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            viewportFraction: 0.2, // 화면에 3개가 보이게 (1 / 3)
            scrollPhysics: const BouncingScrollPhysics(),
            pageSnapping: true, // 자동으로 페이지 맞춤
            onPageChanged: (index, reason) {
              setState(() {
                _currentActivityIndex = index;
              });
            },
          ),
        ),
      ],
    );
  }
}
