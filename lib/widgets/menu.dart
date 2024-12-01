import 'dart:math'; // min 함수를 사용하기 위해 추가
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:project1/screens/member_page.dart'; // MemberPage import 추가
import 'package:project1/utils/auth_provider.dart';
import 'package:project1/utils/timer_provider.dart';
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

  // 팁 데이터를 관리하기 위해 상태 변수로 선언
  List<Map<String, dynamic>> tips = [
    {'title': '효율적인 시간 관리', 'content': '목표를 세우고 시간을 효율적으로 사용하세요.'},
    {'title': '꾸준함의 중요성', 'content': '매일 조금씩이라도 활동을 이어가세요.'},
    {'title': '휴식의 필요성', 'content': '적절한 휴식을 통해 효율을 높이세요.'},
    {'title': '팁4', 'content': '팁 내용4'},
    {'title': '팁5', 'content': '팁 내용5'},
    {'title': '팁6', 'content': '팁 내용6'},
    // 추가 팁 데이터...
  ];

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
            Container(
              height: 150,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.deepPurple,
                    Colors.blueAccent,
                  ],
                ),
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: FutureBuilder<Map<String, dynamic>?>(
                future: authProvider.getUserData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // 데이터를 로드하는 동안 로딩 표시를 보여줍니다.
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    // 에러가 발생한 경우 에러 메시지를 보여줍니다.
                    return const Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.'));
                  }

                  if (!snapshot.hasData || snapshot.data == null) {
                    // 데이터가 없을 경우 메시지를 보여줍니다.
                    return const Center(child: Text('데이터가 없습니다.'));
                  }

                  Map<String, dynamic> data = snapshot.data!;
                  final String userName = data['user_name'] ?? 'userName';
                  final String profileImageUrl = data['profile_image'] ?? '';
                  print(profileImageUrl);
                  final String subscriptionStatus = data['subscription_status'] ?? '무료 회원';
                  // 남은 시간을 timerProvider에서 가져옴
                  final int remainingSeconds = timerProvider.remainingSeconds;
                  final String formattedRemainingTime = timerProvider.formattedTime;

                  return Row(
                    children: [
                      // 프로필 사진
                      if (profileImageUrl.isNotEmpty)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(2, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.grey[300],
                          ),
                          child: SvgPicture.network(
                            profileImageUrl,
                            width: 80,
                            height: 80,
                          ),
                        )
                      else
                        CircleAvatar(
                          radius: 40,
                          child: SvgPicture.network(
                            'https://api.dicebear.com/9.x/thumbs/svg?seed=$userName&radius=50',
                            width: 80,
                            height: 80,
                          ),
                        ),
                      const SizedBox(width: 16),
                      // 사용자 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 인사말
                            Text(
                              '안녕하세요 $userName 님,',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 남은 시간
                            Text(
                              '남은 시간: $formattedRemainingTime',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // 구독 상태
                            Text(
                              '구독 상태: $subscriptionStatus',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildFriendsSection(),
            const SizedBox(height: 24),
            _buildAchievementsSection(),
            const SizedBox(height: 24),
            _buildTipsSection(),
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
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: const Text(
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
                    image: DecorationImage(
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
                  image: DecorationImage(
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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    // 업적 설명
                    Text(
                      achievement['description'],
                      style: TextStyle(fontSize: 16, color: Colors.white),
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
                  icon: Icon(Icons.close, color: Colors.white),
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

  Widget _buildTipsSection() {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목과 아이콘
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            '팁',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: min(tips.length, 5) + 2, // 팁 컨테이너 앞뒤로 추가
            itemBuilder: (context, index) {
              if (index == 0) {
                // 맨 앞의 팁 컨테이너
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(left: 16, right: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 16,
                        top: 16,
                        child: Text(
                          '팁',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -15,
                        bottom: 0,
                        child: Image.asset(
                          'assets/images/sticker_tip_4.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (index == min(tips.length, 5) + 1) {
                // 맨 뒤의 새로고침 컨테이너
                return GestureDetector(
                  onTap: () {
                    // 팁 새로고침 로직 구현
                    setState(() {
                      tips.shuffle();
                    });
                  },
                  child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '새로고침',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Icon(
                            Icons.replay_rounded,
                            size: 28,
                            color: Colors.white,
                          )
                        ],
                      )),
                );
              } else {
                final tip = tips[index - 1]; // 인덱스 보정
                return _buildTipCard(tip, isDarkMode);
              }
            },
          ),
        ),
      ],
    );
  }

  // 팁 카드 빌드 함수
  Widget _buildTipCard(Map<String, dynamic> tip, bool isDarkMode) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tip['title'],
              style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 8),
            Text(
              tip['content'],
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
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
