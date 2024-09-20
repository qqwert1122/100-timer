import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:project1/models/achievement.dart';
import 'package:project1/widgets/options.dart';
import 'package:project1/widgets/text_indicator.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:project1/styles/week_colors.dart';
import 'package:project1/widgets/alarm_message.dart';
import 'package:project1/widgets/footer.dart';
import 'package:project1/widgets/achievement_card.dart';
import 'package:project1/data/sample_records_data.dart';
import 'package:project1/data/sample_image_data.dart';
import 'package:project1/data/achievement_data.dart';
import 'package:project1/data/quotes_data.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with TickerProviderStateMixin {
  double _sheetSize = 0.1; // 초기 크기
  final DraggableScrollableController _controller =
      DraggableScrollableController();

  late Timer _timer;
  String _currentTime = "";
  String _randomQuote = '';
  int _currentIndex = 0;
  final int _burner = 0;

  late AnimationController _waveAnimationController;
  late Animation<double> _waveAnimation;

  final List<Color> _colors = getWeekColos();
  final List<Map<String, String>> _weekdays = getSampleRecords();
  final List<String> _quotes = getQuotes();
  final List<String> imgList = getSampleImages();
  final List<Achievement> achievements = getAchievements();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startTimeUpdates();
    _generateRandomQuote();
  }

  void _initAnimations() {
    _waveAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true); // 애니메이션을 반복하여 파도처럼 보이게 함

    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _waveAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startTimeUpdates() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime(); // 매초 시간 업데이트
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // 타이머 해제
    _controller.dispose();
    _waveAnimationController.dispose();
    super.dispose();
  }

  void _updateTime() {
    // 현재 시간을 가져와서 문자열로 변환
    setState(() {
      DateTime now = DateTime.now();
      _currentTime = "${now.month}월 ${now.day}일 ${now.hour}시 ${now.minute}분";
    });
  }

  void _generateRandomQuote() {
    final random = Random();
    setState(() {
      _randomQuote = _quotes[random.nextInt(_quotes.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(
                  height: 200,
                ),
                TextIndicator(
                  timerProvider: timerProvider,
                ),
                Container(
                  width: double.infinity,
                  height: 100,
                  alignment: Alignment.center,
                  child: timerProvider.isRunning
                      ? AnimatedBuilder(
                          animation: _waveAnimationController,
                          builder: (context, child) {
                            // 색상이 파도치는 효과를 주기 위해 그라데이션 사용
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.yellow,
                                    Colors.orange,
                                    isDarkMode
                                        ? Colors.redAccent.shade200
                                        : Colors.lime
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  stops: [
                                    _waveAnimation.value,
                                    _waveAnimation.value + 0.2,
                                    _waveAnimation.value + 0.4,
                                    _waveAnimation.value + 0.6,
                                  ],
                                ).createShader(bounds);
                              },
                              child: Text(
                                timerProvider.formattedTime,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 60,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'chab'),
                              ),
                            );
                          },
                        )
                      : Text(
                          timerProvider.formattedTime,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 60,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'chab'),
                        ),
                ),
                const SizedBox(height: 20),
                timerProvider.isRunning
                    ? AnimatedBuilder(
                        animation: _waveAnimationController,
                        builder: (context, child) {
                          // 색상이 파도치는 효과를 주기 위해 그라데이션 사용
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.yellow,
                                  Colors.orange,
                                  isDarkMode
                                      ? Colors.redAccent.shade200
                                      : Colors.lime
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                stops: [
                                  _waveAnimation.value,
                                  _waveAnimation.value + 0.2,
                                  _waveAnimation.value + 0.4,
                                  _waveAnimation.value + 0.6,
                                ],
                              ).createShader(bounds);
                            },
                            child: IconButton(
                              key: ValueKey<bool>(timerProvider.isRunning),
                              icon: Icon(timerProvider.isRunning
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded),
                              iconSize: 80,
                              color: Colors.white,
                              onPressed: () {
                                if (timerProvider.isRunning) {
                                  timerProvider.stopTimer();
                                } else {
                                  timerProvider.startTimer();
                                }
                              },
                            ),
                          );
                        },
                      )
                    : IconButton(
                        key: ValueKey<bool>(timerProvider.isRunning),
                        icon: Icon(timerProvider.isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                        iconSize: 80,
                        color: Colors.white,
                        onPressed: () {
                          if (timerProvider.isRunning) {
                            timerProvider.stopTimer();
                          } else {
                            timerProvider.startTimer();
                          }
                        },
                      ),
                const SizedBox(
                  height: 30,
                ),
                const AlarmMessage(),
              ],
            ),
          ),
          DraggableScrollableSheet(
            controller: _controller,
            initialChildSize: 0.13,
            minChildSize: 0.13,
            maxChildSize: 1,
            snap: true,
            snapAnimationDuration: const Duration(milliseconds: 200),
            builder: (BuildContext context, ScrollController scrollController) {
              return NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  setState(() {
                    _sheetSize = notification.extent; // 현재 크기 업데이트
                  });
                  return true;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black : Colors.grey.shade100,
                    borderRadius: _sheetSize >= 0.9
                        ? const BorderRadius.vertical(
                            top: Radius.circular(0),
                          )
                        : const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(top: 30),
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: _sheetSize >= 0.9 ? 30 : 0,
                        child: const SizedBox(height: 0),
                      ),
                      timerProvider.isRunning && _sheetSize >= 0.9
                          ? AnimatedBuilder(
                              animation: _waveAnimationController,
                              builder: (context, child) {
                                // 색상이 파도치는 효과를 주기 위해 그라데이션 사용
                                return ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.yellow,
                                        Colors.orange,
                                        isDarkMode
                                            ? Colors.redAccent.shade200
                                            : Colors.lime
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      stops: [
                                        _waveAnimation.value,
                                        _waveAnimation.value + 0.2,
                                        _waveAnimation.value + 0.4,
                                        _waveAnimation.value + 0.6,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      width: 60, // 고정된 너비
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 60, // 고정된 너비
                                height: 5,
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              '내 기록',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Icon(
                              Icons.history_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // GridView의 스크롤 비활성화
                      const Padding(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '이번주의 기록',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GridView.builder(
                        physics:
                            const NeverScrollableScrollPhysics(), // 스크롤 비활성화
                        shrinkWrap: true, // GridView의 크기를 자식에 맞추기
                        padding: const EdgeInsets.all(10.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2열
                          childAspectRatio: 2, // 정사각형 모양
                          crossAxisSpacing: 10, // 열 간격
                          mainAxisSpacing: 10, // 행 간격
                        ),

                        itemCount: _colors.length, // 총 8개
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.all(2), // 높이를 명시적으로 설정
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _colors[index],
                                  Colors.pink.shade50,
                                ],
                                begin: index % 2 == 0
                                    ? Alignment.topLeft
                                    : Alignment.bottomRight,
                                end: index % 2 == 0
                                    ? Alignment.bottomRight
                                    : Alignment.topLeft,
                              ),
                              borderRadius: BorderRadius.circular(15), // 둥근 모서리
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 5,
                                  left: 15,
                                  child: Text(
                                    _weekdays[index]['day'] ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Wiro',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Text(
                                    _weekdays[index]['burntime'] ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: TextButton(
                          onPressed: () {},
                          style: ButtonStyle(
                            foregroundColor:
                                WidgetStateProperty.all(Colors.white), // 텍스트 색상
                            backgroundColor: WidgetStateProperty.all(
                                Colors.blueAccent.shade400), // 배경색
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12.0), // 둥근 모서리 반경
                              ),
                            ),
                          ),
                          child: const Text(
                            '더 보기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '나의 달성',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CarouselSlider.builder(
                        itemCount: imgList.length,
                        itemBuilder: (BuildContext context, int itemIndex,
                            int pageViewIndex) {
                          double angle = 0.0;

                          // 현재 인덱스에 따라 기울기 각도 설정
                          if (itemIndex == _currentIndex - 1) {
                            angle = -0.1; // 왼쪽으로 기울기
                          } else if (itemIndex == _currentIndex) {
                            angle = 0.0; // 똑바로
                          } else if (itemIndex == _currentIndex + 1) {
                            angle = 0.1; // 오른쪽으로 기울기
                          }

                          return Transform.rotate(
                            angle: angle,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: AchievementCard(
                                  achievement: achievements[itemIndex],
                                ),
                              ),
                            ),
                          );
                        },
                        options: CarouselOptions(
                          height: 300,
                          autoPlay: false,
                          enlargeCenterPage: true,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentIndex = index; // 현재 인덱스 업데이트
                            });
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '옵션',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Options(),
                      const SizedBox(
                        height: 30,
                      ),
                      const Footer(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
