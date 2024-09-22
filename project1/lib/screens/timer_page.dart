import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/models/achievement.dart';
import 'package:project1/screens/add_activity_page.dart';
import 'package:project1/utils/activity_service.dart';
import 'package:project1/utils/timer_service.dart';
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
  bool _isRunning = false;

  int _remainingSeconds = TimerService.weeklyTotalTimeInSeconds;
  int _activityId = 1;
  int _currentIndex = 0;

  bool isSuspected = false;

  late AnimationController _slipAnimationController;
  late Animation<Offset> _slipAnimation;
  late AnimationController _waveAnimationController;
  late Animation<double> _waveAnimation;
  late AnimationController _breathingAnimationController;
  late Animation<double> _breathingAnimation;

  final List<Color> _colors = getWeekColos();
  final List<Map<String, String>> _weekdays = getSampleRecords();
  final List<String> imgList = getSampleImages();
  final List<Achievement> achievements = getAchievements();

  @override
  void initState() {
    super.initState();
    Provider.of<TimerProvider>(context, listen: false)
        .createOrLoadTimer(1); // userId 1로 예시
    _initAnimations();
  }

  @override
  void dispose() {
    _timer.cancel(); // 타이머 해제
    _controller.dispose();
    _slipAnimationController.dispose();
    _waveAnimationController.dispose();
    _breathingAnimationController.dispose();
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
  }

  void closeMessage() {
    setState(() {
      isSuspected = !isSuspected;
    });
  }

  // Activities

  String _selectedActivity = '전체'; // 초기 선택된 활동
  final List<Map<String, dynamic>> activities = [
    {'name': '전체', 'icon': Icons.list},
    {'name': '운동', 'icon': Icons.fitness_center},
    {'name': '공부', 'icon': Icons.school},
    {'name': '독서', 'icon': Icons.book},
    {'name': '명상', 'icon': Icons.self_improvement},
    {'name': '요리', 'icon': Icons.restaurant},
    {'name': '산책', 'icon': Icons.directions_walk},
    {'name': '기타', 'icon': Icons.more_horiz},
  ];

  void _removeActivity(int index) {
    setState(() {
      activities.removeAt(index); // 해당 인덱스의 항목 삭제
    });
  }

  Future<void> _showDeleteConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 외부 클릭으로 다이얼로그 닫히지 않음
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '정말 삭제하시겠습니까',
            style: TextStyle(
              fontSize: 16,
              color: Colors.redAccent,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text('삭제할 경우 해당 활동의 기록이 모두 삭제되며 복구할 수 없습니다.'),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '취소',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
            ),
            TextButton(
              child: const Text(
                '삭제',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
              onPressed: () {
                _removeActivity(index); // 항목 삭제
                Navigator.of(context).pop(); // 다이얼로그 닫기
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('${activities[index]['name']} 활동이 삭제되었습니다.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

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
          return Container(
            height: 400,
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(
                    top: 16,
                    left: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft, // 제목을 왼쪽에 정렬
                    child: Text(
                      '활동 선택하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10), // 제목과 리스트 간 간격
                Expanded(
                  child: ListView.builder(
                    itemCount: activities.length + 1,
                    itemBuilder: (context, index) {
                      if (index == activities.length) {
                        // 마지막 항목은 '활동 추가' 버튼
                        return ListTile(
                          leading: const Icon(Icons.add, color: Colors.blue),
                          title: const Text(
                            '활동 추가',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            // 활동 추가 페이지로 이동
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AddActivityPage()),
                            );
                          },
                        );
                      }

                      if (activities[index]['name'] == '전체') {
                        return ListTile(
                          leading: Icon(activities[index]['icon']),
                          title: Text(
                            activities[index]['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedActivity =
                                  activities[index]['name']; // 활동 선택
                            });
                            Navigator.pop(context); // 모달 닫기
                          },
                        );
                      }

                      return Slidable(
                        key: Key(activities[index]['name']),
                        closeOnScroll: true,
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                () {}; // 수정 기능
                              },
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              flex: 1,
                              autoClose: true,
                            ),
                            SlidableAction(
                              onPressed: (context) {
                                _showDeleteConfirmationDialog(index);
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              flex: 1,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 0), // 항목 간 간격을 좁게 설정
                          child: ListTile(
                            leading:
                                Icon(activities[index]['icon']), // 아이콘을 왼쪽에 표시
                            title: Text(
                              activities[index]['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedActivity =
                                    activities[index]['name']; // 활동 선택
                              });
                              Navigator.pop(context); // 모달 닫기
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
                      Text(
                        _selectedActivity,
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent.shade200,
                            fontFamily: 'Wiro'),
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
                                        : Colors.pink
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
                                style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.redAccent,
                                    fontSize: 60,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'chab'),
                              ),
                            );
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
                                          .withOpacity(0.3), // 그림자 색상 (흰색)
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
                                    timerProvider.startTimer();
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
                                color: Colors.black
                                    .withOpacity(0.3), // 그림자 색상 (흰색)
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
                              timerProvider.startTimer();
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
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _sheetSize >= 0.3
                          ? (isDarkMode
                              ? const Color(0xff181C14)
                              : Colors.white)
                          : (isDarkMode
                              ? Colors.black
                              : Colors.redAccent.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3), // 그림자 색상 (흰색)
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
                              color: _sheetSize >= 0.3
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
                              padding: EdgeInsets.all(16),
                              child: Text(
                                '내 기록',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: _sheetSize >= 0.3
                                      ? (isDarkMode
                                          ? Colors.white
                                          : Colors.black)
                                      : Colors.white,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Icon(
                                Icons.history_rounded,
                                color: _sheetSize >= 0.3
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
                                borderRadius:
                                    BorderRadius.circular(15), // 둥근 모서리
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.3), // 그림자 색상 (흰색)
                                    spreadRadius: 1, // 그림자가 퍼지는 정도
                                    blurRadius: 5, // 그림자 흐림 정도
                                    offset: const Offset(0, 2), // 그림자 위치 (x, y)
                                  ),
                                ],
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
