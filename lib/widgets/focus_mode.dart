import 'dart:math'; // min 함수를 사용하기 위해 추가
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/screens/member_page.dart'; // MemberPage import 추가
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/responsive_size.dart';

class FocusMode extends StatefulWidget {
  const FocusMode({super.key});

  @override
  State<FocusMode> createState() => _FocusModeState();
}

class _FocusModeState extends State<FocusMode> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late final StatsProvider _statsProvider; // 주입받을 DatabaseService

  // 친구 카드의 그라데이션 애니메이션을 위한 컨트롤러와 애니메이션
  late AnimationController _shimmerAnimationController;
  late Animation<Alignment> _shimmerAnimation;
  List<Map<String, dynamic>> pomodoroItems = [
    {
      'title': '30',
      'value': 1800,
      'maxCount': 3,
      'currentCount': 0,
      'gradientColors': [Colors.greenAccent, Colors.yellow],
    },
    {
      'title': '1',
      'value': 3600,
      'maxCount': 3,
      'currentCount': 0,
      'gradientColors': [Colors.yellowAccent, Colors.pink],
    },
    {
      'title': '2',
      'value': 7200,
      'maxCount': 3,
      'currentCount': 0,
      'gradientColors': [Colors.blueAccent, Colors.lime],
    },
    {
      'title': '4',
      'value': 14400,
      'maxCount': 3,
      'currentCount': 0,
      'gradientColors': [Colors.amber, Colors.red],
    },
  ];

  @override
  void initState() {
    super.initState();
    _statsProvider = Provider.of<StatsProvider>(context, listen: false); // DatabaseService 주입
    _initPomodoroCounts();

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

  Future<void> _initPomodoroCounts() async {
    final updatedItems = List<Map<String, dynamic>>.from(pomodoroItems);

    for (var item in updatedItems) {
      final targetDuration = item['value'] as int;
      final count = await _statsProvider.getCompletedFocusMode(targetDuration);
      item['currentCount'] = count;
    }

    if (mounted) {
      // 위젯이 빌드 트리에 있는지 확인
      setState(() {
        pomodoroItems = updatedItems;
      });
    }
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
    final timerProvider = Provider.of<TimerProvider>(context);

    return SingleChildScrollView(
      child: Padding(
        padding: context.paddingSM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.hp(3)),
            Text(
              '집중 모드',
              style: AppTextStyles.getHeadline(context),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              '정해진 시간 동안 멈추지 않고 집중을 달성하세요',
              style: AppTextStyles.getCaption(context),
            ),
            _buildPomodoroMenu(timerProvider),
            SizedBox(height: context.hp(10)),
            // const SizedBox(height: 40),
            // _buildFriendsSection(),
            // const SizedBox(height: 40),
            // const ContentSection(),
            // const SizedBox(height: 100),
          ],
        ),
      ),
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
    Widget _buildCountIndicator(int maxCount, int currentCount) {
      return Row(
        children: List.generate(
          maxCount,
          (index) => Padding(
            padding: EdgeInsets.only(right: context.wp(1)),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < currentCount ? Colors.white : Colors.white.withOpacity(0.3),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.hp(3)),
        GestureDetector(
          onTap: () => _showActivityModal(timerProvider),
          child: Container(
            padding: context.paddingXS,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      getIconData(timerProvider.currentActivityIcon),
                    ),
                    SizedBox(width: context.wp(5)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '선택된 활동',
                          style: AppTextStyles.getCaption(
                            context,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          timerProvider.currentActivityName,
                          style: AppTextStyles.getBody(context).copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    )
                  ],
                ),
                SizedBox(width: context.wp(10)),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: context.xl,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: context.hp(3)),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
          ),
          itemCount: pomodoroItems.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final item = pomodoroItems[index];

            return GestureDetector(
              onTap: () async {
                await Future.delayed(const Duration(milliseconds: 100));
                timerProvider.setSessionModeAndTargetDuration(mode: 'SESIOPMDR', targetDuration: item['value']);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const TimerRunningPage(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: item['gradientColors'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: context.paddingSM,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                item['title'],
                                style: TextStyle(
                                  fontSize: context.lg * 2,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  fontFamily: 'chab',
                                ),
                              ),
                              SizedBox(width: context.wp(1)),
                              Text(
                                index == 0 ? '분' : '시간',
                                style: TextStyle(
                                  fontSize: context.sm,
                                  fontWeight: FontWeight.w200,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.hp(2)),
                          _buildCountIndicator(
                            item['maxCount'],
                            item['currentCount'],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            '현재 활동 중인 친구를 확인하세요',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 30),
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
                        color: Colors.lime,
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
                              right: -40,
                              bottom: -40,
                              child: Image.asset(
                                'assets/images/friend_2.png',
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
