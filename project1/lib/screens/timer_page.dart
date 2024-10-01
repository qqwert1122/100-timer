import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/models/achievement.dart';
import 'package:project1/screens/activity_log_page.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/widgets/options.dart';
import 'package:project1/widgets/text_indicator.dart';
import 'package:project1/widgets/weekly_activity_chart.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:project1/styles/week_colors.dart';
import 'package:project1/widgets/alarm_message.dart';
import 'package:project1/widgets/footer.dart';
import 'package:project1/widgets/achievement_card.dart';
import 'package:project1/data/sample_records_data.dart';
import 'package:project1/data/sample_image_data.dart';
import 'package:project1/data/achievement_data.dart';

class TimerPage extends StatefulWidget {
  final Map<String, dynamic> timerData;

  const TimerPage({super.key, required this.timerData});

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with TickerProviderStateMixin {
  double _sheetSize = 0.1; // 초기 크기
  final DraggableScrollableController _controller =
      DraggableScrollableController();
  bool isTimeClicked = false;
  int _currentIndex = 0;
  String userId = 'v3_4';
  String activityTimeText = '00:00:00'; // 초기 활동 시간 표시 값

  bool isSuspected = false;

  late AnimationController _slipAnimationController;
  late Animation<Offset> _slipAnimation;
  late AnimationController _waveAnimationController;
  late Animation<double> _waveAnimation;
  late AnimationController _breathingAnimationController;
  late Animation<double> _breathingAnimation;
  late AnimationController _timeAnimationController;
  late Animation<double> _totalTimeAnimation;
  late Animation<double> _activityTimeAnimation;

  final List<Color> _colors = getWeekColos();
  final List<Map<String, String>> _weekdays = getSampleRecords();
  final List<String> imgList = getSampleImages();
  final List<Achievement> achievements = getAchievements();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      timerProvider.setTimerData(widget.timerData);
      timerProvider.initializeWeeklyActivityData();
    });
    _initAnimations();
  }

  @override
  void dispose() {
    _controller.dispose();
    _slipAnimationController.dispose();
    _waveAnimationController.dispose();
    _breathingAnimationController.dispose();
    _timeAnimationController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _slipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500), // 1초 동안 애니메이션 실행
      vsync: this,
    );

    // 슬라이드 애니메이션 설정 (위에서 아래로)
    _slipAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // 시작 위치 (위쪽)
      end: Offset.zero, // 종료 위치 (원래 자리)
    ).animate(CurvedAnimation(
      parent: _slipAnimationController,
      curve: Curves.easeInOut, // 애니메이션 곡선
    ));

    _slipAnimationController.forward();

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

    _breathingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // 애니메이션 반복

    // 1.0에서 1.2로 크기가 변하도록 설정 (조금 커졌다가 작아지는 효과)
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _breathingAnimationController,
        curve: Curves.easeInOut, // 부드러운 숨쉬기 효과
      ),
    );

    _timeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _totalTimeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _timeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _activityTimeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void closeMessage() {
    setState(() {
      isSuspected = !isSuspected;
    });
  }

  void _toggleTimeView() {
    setState(() {
      isTimeClicked = !isTimeClicked;
    });

    if (isTimeClicked) {
      _timeAnimationController.forward(); // 애니메이션 실행
    } else {
      _timeAnimationController.reverse(); // 애니메이션 되돌리기
    }
  }

  Widget _buildTimeDisplay(TimerProvider timerProvider, bool isDarkMode) {
    return GestureDetector(
      onTap: _toggleTimeView,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 총 활동 시간 텍스트 (애니메이션으로 사라짐)
          FadeTransition(
            opacity: _totalTimeAnimation,
            child: AnimatedOpacity(
              opacity: isTimeClicked ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                timerProvider.formattedTime,
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.redAccent,
                    fontSize: 60,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'chab'),
              ),
            ),
          ),

          // 활동 시간 텍스트 (애니메이션으로 나타남)
          FadeTransition(
            opacity: _activityTimeAnimation,
            child: AnimatedOpacity(
              opacity: isTimeClicked ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: isTimeClicked
                  ? Text(
                      timerProvider.formattedActivityTime,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.redAccent,
                          fontSize: 60,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'chab'),
                    )
                  : Container(), // 클릭하지 않았을 때는 비어있는 컨테이너로 유지
            ),
          ),
        ],
      ),
    );
  }

  // Activities
  void _showActivityModal(TimerProvider timerProvider) {
    if (timerProvider.isRunning) {
      // 타이머가 작동 중일 때는 토스트 메시지 띄우기
      Fluttertoast.showToast(
        msg: "타이머를 중지하고 활동을 변경해주세요",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.redAccent.shade200,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25.0),
          ),
        ),
        builder: (BuildContext context) {
          return ActivityPicker(
            onSelectActivity: (String selectedActivity,
                String selectedActivityIcon, String selectedActivityListId) {
              timerProvider.setCurrentActivity(selectedActivityListId,
                  selectedActivity, selectedActivityIcon);
              Navigator.pop(context);
            },
            selectedActivity: timerProvider.currentActivityName ?? '전체',
            userId: userId,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);

    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      body: SlideTransition(
        position: _slipAnimation,
        child: Stack(
          children: [
            // timer_page
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                isSuspected
                    ? Column(
                        children: [
                          const SizedBox(
                            height: 100,
                          ),
                          AlarmMessage(closeMessage: closeMessage),
                        ],
                      )
                    : const SizedBox(
                        height: 150,
                      ),
                const SizedBox(
                  height: 100,
                ),
                const Text(
                  '선택된 활동',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () =>
                      _showActivityModal(timerProvider), // 버튼을 클릭하면 모달 실행
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        getIconData(timerProvider.currentActivityIcon ??
                            'category_rounded'),
                        color: Colors.redAccent.shade200,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        timerProvider.currentActivityName ?? '전체',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent.shade200,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 30, color: Colors.red),
                    ],
                  ),
                ),
                // timer
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
                                          : Colors.redAccent.shade700
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
                                child: _buildTimeDisplay(
                                    timerProvider, isDarkMode));
                          },
                        )
                      : Text(
                          timerProvider.formattedTime,
                          style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.redAccent.shade200,
                              fontSize: 60,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'chab'),
                        ),
                ),
                const SizedBox(height: 20),
                // play button
                timerProvider.isRunning
                    ? AnimatedBuilder(
                        animation: _breathingAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _breathingAnimation.value, // 크기 애니메이션 적용
                            child: Container(
                              decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey.shade800
                                      : Colors.redAccent.shade400,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(0.3), // 그림자 색상
                                      spreadRadius: 2, // 그림자가 퍼지는 정도
                                      blurRadius: 10, // 그림자 흐림 정도
                                      offset:
                                          const Offset(0, 5), // 그림자 위치 (x, y)
                                    ),
                                  ]),
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
                                    timerProvider.startTimer(
                                        activityId:
                                            timerProvider.currentActivityId ??
                                                '${userId}1');
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.redAccent.shade400,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3), // 그림자 색상
                                spreadRadius: 2, // 그림자가 퍼지는 정도
                                blurRadius: 10, // 그림자 흐림 정도
                                offset: const Offset(0, 5), // 그림자 위치 (x, y)
                              ),
                            ]),
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
                              timerProvider.startTimer(
                                  activityId: timerProvider.currentActivityId ??
                                      '${userId}1');
                            }
                          },
                        ),
                      ),
                const SizedBox(
                  height: 50,
                ),
                TextIndicator(
                  timerProvider: timerProvider,
                ),
                const SizedBox(
                  height: 30,
                ),
              ],
            ),
            // draggable sheet
            DraggableScrollableSheet(
              controller: _controller,
              initialChildSize: 0.13,
              minChildSize: 0.13,
              maxChildSize: 1,
              snap: true,
              snapAnimationDuration: const Duration(milliseconds: 200),
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    setState(() {
                      _sheetSize = notification.extent; // 현재 크기 업데이트
                    });
                    return true;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      color: _sheetSize >= 0.2
                          ? (isDarkMode
                              ? const Color(0xff181C14)
                              : Colors.white)
                          : (isDarkMode
                              ? Colors.black
                              : Colors.redAccent.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3), // 그림자 색상
                          spreadRadius: 4, // 그림자가 퍼지는 정도
                          blurRadius: 10, // 그림자 흐림 정도
                          offset: const Offset(0, -1), // 그림자 위치 (x, y)
                        ),
                      ],
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
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 60, // 고정된 너비
                            height: 5,
                            decoration: BoxDecoration(
                              color: _sheetSize >= 0.2
                                  ? (isDarkMode ? Colors.white : Colors.black)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                '내 기록',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: _sheetSize >= 0.2
                                      ? (isDarkMode
                                          ? Colors.white
                                          : Colors.black)
                                      : Colors.white,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Icon(
                                Icons.history_rounded,
                                color: _sheetSize >= 0.2
                                    ? (isDarkMode ? Colors.white : Colors.black)
                                    : Colors.white,
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
                        WeeklyActivityChart(),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ActivityLogPage()),
                              );
                            },
                            style: ButtonStyle(
                              foregroundColor: WidgetStateProperty.all(
                                  Colors.white), // 텍스트 색상
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
                        const Options(),
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
      ),
    );
  }
}
