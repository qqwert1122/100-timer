import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int sampleSeconds = 360000;
  Timer? _timer;
  bool isRunning = false;

  String get formattedTime {
    final hours = (sampleSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((sampleSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (sampleSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _onIntroEnd(context) {
    Navigator.pop(context); // 이전 화면으로 돌아감
  }

  void startSampleTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        setState(() {
          sampleSeconds--;
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      startSampleTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 위젯이 dispose될 때 타이머 중지
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    List<Map<String, dynamic>> words = [
      {"word": "피트니스", "icon": Icons.fitness_center, "color": Colors.redAccent},
      {"word": "영어 공부", "icon": Icons.language, "color": Colors.deepOrange},
      {"word": "공부", "icon": Icons.school, "color": Colors.orange},
      {"word": "독서", "icon": Icons.library_books, "color": Colors.amber},
      {"word": "타이머 어플 코딩", "icon": Icons.computer_rounded, "color": Colors.lightBlue},
      {"word": "업무", "icon": Icons.work, "color": Colors.blue},
      {"word": "명상", "icon": Icons.self_improvement, "color": Colors.blueAccent},
      {"word": "일기 쓰기", "icon": Icons.edit, "color": Colors.indigo},
    ];

    final List<PageViewModel> pages = [
      // 첫 번째 페이지
      PageViewModel(
        title: "",
        bodyWidget: Padding(
          padding: EdgeInsets.all(
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
              ),
              Row(
                children: [
                  Text(
                    "매주 ",
                    style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    "100시간",
                    style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.w900, color: Colors.redAccent),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    "한 주를 ",
                    style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    "버닝",
                    style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.w900, color: Colors.redAccent),
                  ),
                  Text(
                    "하세요",
                    style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              SizedBox(
                height: 16,
              ),
              Row(
                children: [
                  Text(
                    "매주 월요일마다 주어지는 100시간\n일, 공부, 운동으로 불태우세요",
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Wrap(
                spacing: 12.0, // 각 단어 간의 가로 간격
                runSpacing: 8.0, // 줄 간의 세로 간격
                children: words.map((word) {
                  return Container(
                    decoration: BoxDecoration(
                      color: word['color'],
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              word['word'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Icon(
                              word['icon'],
                              size: 12,
                              color: Colors.white,
                            ),
                          ],
                        )),
                  );
                }).toList(),
              ),
              SizedBox(
                height: 30,
              ),
              Text(
                formattedTime,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.redAccent,
                  fontSize: 50,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'chab',
                ),
              ),
            ],
          ),
        ),
      ),

      PageViewModel(
        titleWidget: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alarm, size: 28.0),
            const SizedBox(width: 10),
            const Text(
              "시간 관리",
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bodyWidget: Column(
          children: [
            Text(
              "앱의 주요 기능을 설명하는 두 번째 페이지입니다.",
              style: const TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('알림 받기'),
              value: true,
              onChanged: (bool value) {
                // 알림 설정 변경 로직 추가
              },
            ),
          ],
        ),
        image: Center(child: Image.asset('assets/images/sticker_tip_2.png', height: 175.0)),
        decoration: const PageDecoration(),
      ),
      // 세 번째 페이지
      PageViewModel(
        titleWidget: Text(
          "시작하기",
          style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        ),
        bodyWidget: Column(
          children: [
            Text(
              "지금 바로 앱을 사용해보세요!",
              style: const TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _onIntroEnd(context); // 온보딩 종료 및 이전 화면으로 이동
              },
              child: const Text('앱 시작하기'),
            ),
          ],
        ),
        image: Center(child: Image.asset('assets/images/sticker_tip_3.png', height: 175.0)),
        decoration: const PageDecoration(),
      ),
    ];

    return IntroductionScreen(
      pages: pages,
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // 스킵 버튼을 누를 때도 동일하게 처리
      showSkipButton: false,
      skip: const Text("건너뛰기"),
      next: const Text(
        "다음",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.redAccent,
        ),
      ),
      done: const Text("시작하기",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.redAccent,
          )),
      dotsDecorator: const DotsDecorator(
        color: Colors.grey,
        activeColor: Colors.redAccent,
        size: Size.square(8.0),
        activeSize: Size(8.0, 8.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
