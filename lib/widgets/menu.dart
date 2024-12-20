import 'dart:math'; // min 함수를 사용하기 위해 추가
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/screens/member_page.dart'; // MemberPage import 추가
import 'package:project1/utils/auth_provider.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:project1/widgets/content_section.dart';
import 'package:provider/provider.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // 친구 카드의 그라데이션 애니메이션을 위한 컨트롤러와 애니메이션
  late AnimationController _shimmerAnimationController;
  late Animation<Alignment> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    // 애니메이션 컨트롤러 초기화 등 필요한 초기화 코드
    int durationSeconds = Random().nextInt(5) + 5; // 5 ~ 9초

    _controller = AnimationController(
      duration: Duration(milliseconds: durationSeconds * 100),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Shimmer 애니메이션 컨트롤러 초기화
    _shimmerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // 애니메이션 주기
    )..repeat();

    _shimmerAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(-1.0, -1.0),
          end: const Alignment(1.0, -1.0),
        ).chain(CurveTween(curve: Curves.easeInOut)), // 곡선 변경
        weight: 20,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(1.0, -1.0),
          end: const Alignment(1.0, 1.0),
        ).chain(CurveTween(curve: Curves.linear)), // 곡선 변경
        weight: 30,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(1.0, 1.0),
          end: const Alignment(-1.0, 1.0),
        ).chain(CurveTween(curve: Curves.easeOut)), // 곡선 변경
        weight: 20,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(-1.0, 1.0),
          end: const Alignment(-1.0, -1.0),
        ).chain(CurveTween(curve: Curves.slowMiddle)), // 곡선 변경
        weight: 30,
      ),
    ]).animate(_shimmerAnimationController);
  }

  @override
  void dispose() {
    // 애니메이션 컨트롤러 dispose 등 필요한 해제 코드
    _controller.dispose();
    _shimmerAnimationController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    return '$hours시간 $minutes분';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final timerProvider = Provider.of<TimerProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildPomodoroMenu(timerProvider), // 뽀모도로 메뉴 추가
            const SizedBox(height: 40),
            _buildFriendsSection(),
            const SizedBox(height: 40),
            const ContentSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final List<Map<String, dynamic>> achievements = List.generate(30, (index) {
      return {
        'title': '업적 ${index + 1}',
        'description': '이것은 업적 ${index + 1}의 설명입니다.',
        'achieved': index % 3 == 0, // 3의 배수인 경우 달성된 업적으로 표시
      };
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            '업적',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return GestureDetector(
                onTap: () {
                  _showAchievementDialog(achievement);
                },
                child: Container(
                  decoration: BoxDecoration(
                    // 이미지 배경 설정
                    image: const DecorationImage(
                      image: AssetImage('assets/images/image_afternoon.webp'), // 배경 이미지 경로
                      fit: BoxFit.cover,
                    ),
                    color: achievement['achieved'] ? null : Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: achievement['achieved'] ? Icon(Icons.emoji_events, color: Colors.white) : Icon(Icons.lock, color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 업적 상세 설명 모달 창
  void _showAchievementDialog(Map<String, dynamic> achievement) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            children: [
              // 배경 이미지
              Container(
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/images/image_afternoon.webp'), // 큰 배경 이미지 경로
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 업적 제목
                    Text(
                      achievement['title'],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    // 업적 설명
                    Text(
                      achievement['description'],
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // 닫기 버튼
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
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
          return ActivityPicker(
            onSelectActivity:
                (String selectedActivityListId, String selectedActivity, String selectedActivityIcon, String selectedActivityColor) {
              timerProvider.setCurrentActivity(selectedActivityListId, selectedActivity, selectedActivityIcon, selectedActivityColor);
              Navigator.pop(context);
            },
            selectedActivity: timerProvider.currentActivityName ?? '전체',
          );
        },
      );
    }
  }

  Widget _buildPomodoroMenu(TimerProvider timerProvider) {
    final List<Map<String, dynamic>> pomodoroItems = [
      {
        'title': '30',
        'value': 30,
        'gradientColors': [Colors.greenAccent, Colors.yellow], // 30분 그라데이션 색상
      },
      {
        'title': '1',
        'value': 60,
        'gradientColors': [Colors.yellowAccent, Colors.pink], // 1시간 그라데이션 색상
      },
      {
        'title': '2',
        'value': 120,
        'gradientColors': [Colors.blueAccent, Colors.lime], // 2시간 그라데이션 색상
      },
      {
        'title': '4',
        'value': 240,
        'gradientColors': [Colors.amber, Colors.red], // 4시간 그라데이션 색상
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                '뽀모도로',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => _showActivityModal(timerProvider), // 버튼을 클릭하면 모달 실행
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            getIconData(timerProvider.currentActivityIcon ?? 'category_rounded'),
                            color: Colors.redAccent.shade200,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            (timerProvider.currentActivityName ?? '전체').length > 6
                                ? '${(timerProvider.currentActivityName ?? '전체').substring(0, 6)}...'
                                : timerProvider.currentActivityName ?? '전체',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent.shade200,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: Colors.red),
                  ],
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2x2 그리드
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5, // 카드의 가로 세로 비율
            ),
            itemCount: pomodoroItems.length,
            shrinkWrap: true, // 부모 Column 안에 포함되도록 설정
            physics: const NeverScrollableScrollPhysics(), // 스크롤 비활성화
            itemBuilder: (context, index) {
              final item = pomodoroItems[index];

              return GestureDetector(
                onTap: () {
                  // 선택 시 동작 정의
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item['title']} 선택됨')),
                  );
                },
                child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: item['gradientColors'], // 각 버튼에 정의된 그라데이션 색상 사용
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  item['title'],
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                    fontFamily: 'chab',
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  index == 0 ? '분' : '시간',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w200,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )),
                        index == pomodoroItems.length - 1
                            ? Positioned(
                                right: -30,
                                bottom: -30,
                                child: Image.asset(
                                  'assets/images/timer_6.png',
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container()
                      ],
                    )),
              );
            },
          ),
        ),
      ],
    );
  }

  // 친구의 대시보드 섹션 빌드 (멤버 페이지의 일부)
  Widget _buildFriendsSection() {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // 샘플 친구 데이터
    final List<Map<String, dynamic>> friends = [
      {"name": "친구1", "remaining_seconds": 28000, "is_running": true},
      {"name": "친구2", "remaining_seconds": 150000, "is_running": false},
      {"name": "친구3", "remaining_seconds": 120000, "is_running": true},
      {"name": "친구4", "remaining_seconds": 80000, "is_running": true},
      {"name": "친구5", "remaining_seconds": 60000, "is_running": false},
      {"name": "친구6", "remaining_seconds": 50000, "is_running": true},
      // 추가 친구 데이터...
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32.0, right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '활동중인 친구',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // 새로고침 클릭 시 친구 상태 업데이트
                },
                child: const Icon(
                  Icons.replay_outlined,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: min(friends.length, 5) + 1,
            itemBuilder: (context, index) {
              if (index < min(friends.length, 5)) {
                final friend = friends[index];
                return _buildFriendCard(friend, index, isDarkMode);
              } else {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MemberPage(),
                      ),
                    );
                  },
                  child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          const Positioned(
                            top: 10,
                            left: 10,
                            child: Text(
                              '더 보기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Positioned(
                              right: -20,
                              bottom: -20,
                              child: Image.asset(
                                'assets/images/sticker_group_7.png',
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ))
                        ],
                      )),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend, int index, bool isDarkMode) {
    final String formattedTime = _formatTime(friend['remaining_seconds']);
    final bool isRunning = friend['is_running'] as bool;

    return Container(
      width: 120,
      margin: EdgeInsets.only(left: index == 0 ? 16.0 : 0.0, right: 12.0, bottom: 8.0),
      decoration: BoxDecoration(
        color: isRunning ? null : Colors.grey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: isRunning
          ? AnimatedBuilder(
              animation: _shimmerAnimationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: const [Colors.pinkAccent, Colors.redAccent, Colors.deepOrange, Colors.orangeAccent],
                      begin: _shimmerAnimation.value, // 애니메이션 시작점
                      end: Alignment(-_shimmerAnimation.value.x, -_shimmerAnimation.value.y), // 애니메이션 끝점
                      tileMode: TileMode.mirror, // 경계에서 반복
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.5),
                        blurRadius: 8, // 그림자 흐림 정도
                        offset: const Offset(0, 4), // 그림자 위치
                      ),
                    ],
                  ),
                  child: _buildFriendCardContent(friend, formattedTime, isDarkMode),
                );
              },
            )
          : Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildFriendCardContent(friend, formattedTime, isDarkMode),
            ),
    );
  }

  Widget _buildFriendCardContent(Map<String, dynamic> friend, String formattedTime, bool isDarkMode) {
    // 진행률 계산 (예시로 임의의 진행률 사용)
    double percent = (360000 - (friend['remaining_seconds'] ?? 0)) / 360000; // 총 시간은 100시간(360000초) 기준

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 프로필 이미지를 감싸는 프로그레스바 추가
          Stack(
            alignment: Alignment.center,
            children: [
              CircularPercentIndicator(
                radius: 30,
                lineWidth: 12.0,
                percent: percent.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade300,
                progressColor: friend['is_running'] ? Colors.amber : Colors.grey,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              SvgPicture.network(
                'https://api.dicebear.com/9.x/thumbs/svg?seed=${friend['name']}&radius=50',
                width: 50,
                height: 50,
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            friend['name'],
            style: TextStyle(color: friend['is_running'] ? Colors.white : Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            '남은 시간',
            style: TextStyle(color: friend['is_running'] ? Colors.white : Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          Text(
            formattedTime,
            style: TextStyle(color: friend['is_running'] ? Colors.white : Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
