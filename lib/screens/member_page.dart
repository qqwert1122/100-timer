import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MemberPage extends StatefulWidget {
  const MemberPage({super.key});

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? selectedUser;
  Map<String, dynamic>? targetUser;

  late AnimationController _controller;
  late Animation<double> _animation;

  List<Map<String, dynamic>> userList = [
    {"name": "조서은", "total_seconds": 360000, "remaining_seconds": 1100, "is_running": true},
    {"name": "양조현", "total_seconds": 360000, "remaining_seconds": 28035, "is_running": true},
    {"name": "Alice", "total_seconds": 360000, "remaining_seconds": 288440, "is_running": true},
    {"name": "Bob", "total_seconds": 360000, "remaining_seconds": 84159, "is_running": true},
    {"name": "Charlie", "total_seconds": 360000, "remaining_seconds": 187662, "is_running": false},
    {"name": "Diana", "total_seconds": 360000, "remaining_seconds": 166945, "is_running": true},
    {"name": "Ethan", "total_seconds": 360000, "remaining_seconds": 238012, "is_running": false},
    {"name": "Fiona", "total_seconds": 360000, "remaining_seconds": 42382, "is_running": false},
    {"name": "George", "total_seconds": 360000, "remaining_seconds": 290661, "is_running": false},
    {"name": "Hannah", "total_seconds": 360000, "remaining_seconds": 156370, "is_running": false},
    {"name": "Ian", "total_seconds": 360000, "remaining_seconds": 38744, "is_running": true},
    {"name": "Julia", "total_seconds": 360000, "remaining_seconds": 305169, "is_running": false}
  ];

  @override
  void initState() {
    super.initState();

    selectedUser = userList.first; // 초기 멤버 설정

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          // 애니메이션이 완료되면 멤버 교체
          selectedUser = targetUser;
          targetUser = null;
          _controller.reset();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation(Map<String, dynamic> user) {
    if (_controller.isAnimating) return; // 애니메이션 중에는 무시
    if (user != selectedUser) {
      setState(() {
        targetUser = user;
        _controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18)),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 16,
              left: 32,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                '친구의 대시보드',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          selectedUser != null
              ? Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  alignment: Alignment.center,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      double angle = _animation.value * 2 * pi; // 0에서 360도(2π 라디안)까지 회전
                      Widget displayedWidget;

                      if (_animation.value < 0.5) {
                        // 애니메이션의 전반부: 기존 멤버 표시
                        displayedWidget = MemberWidget(
                          user: selectedUser!,
                          size: MediaQuery.of(context).size.width * 0.5,
                          onTap: () {},
                          rotationAngle: angle,
                          animateProgress: true,
                          isTop: true,
                        );
                      } else {
                        // 애니메이션의 후반부: 새로운 멤버 표시
                        displayedWidget = MemberWidget(
                          user: targetUser ?? selectedUser!,
                          size: MediaQuery.of(context).size.width * 0.5,
                          onTap: () {},
                          rotationAngle: angle,
                          animateProgress: true,
                          isTop: true,
                        );
                      }

                      return displayedWidget;
                    },
                  ),
                )
              : Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: const Center(
                    child: Text("친구를 추가하세요"),
                  ),
                ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: userList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 한 줄에 3개씩
                childAspectRatio: 1, // 가로세로 비율 조정
              ),
              itemBuilder: (context, index) {
                final user = userList[index];
                return MemberWidget(
                  user: user,
                  onTap: () {
                    _startAnimation(user);
                    HapticFeedback.lightImpact();
                  },
                  rotationAngle: 0.0,
                  animateProgress: false,
                  isTop: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MemberWidget extends StatelessWidget {
  final Map<String, dynamic> user;
  final double size;
  final VoidCallback onTap;
  final double rotationAngle;
  final bool animateProgress;
  final bool isTop;

  const MemberWidget({
    Key? key,
    required this.user,
    required this.onTap,
    this.size = 80.0,
    this.rotationAngle = 0.0,
    this.animateProgress = false,
    this.isTop = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double percentage = (user['total_seconds'] - user['remaining_seconds']) / user['total_seconds']; // 진행률 계산
    final bool isRunning = user['is_running'];

    String formattedTime(int remainingSeconds) {
      final hours = (remainingSeconds ~/ 3600).toString().padLeft(2, '0');
      final minutes = ((remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
      return '$hours시간 $minutes분';
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        // height 값을 조정하여 충분한 공간을 확보
        height: isTop ? size : size * 1.2, // 하단 멤버의 높이를 약간 늘림
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress Circle은 회전하지 않도록 분리
            Positioned(
              bottom: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: percentage),
                duration: Duration(milliseconds: animateProgress ? 300 : 0),
                builder: (context, value, child) {
                  return CustomPaint(
                    size: Size(size, size / 2),
                    painter: HalfCirclePainter(
                      value,
                      isTop: isTop,
                      isRunning: isRunning,
                    ),
                  );
                },
              ),
            ),
            // 회전하는 부분: 아바타와 이름
            Positioned(
              bottom: 0, // 하단 멤버의 bottom 값을 양수로 조정
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(rotationAngle),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.network(
                      'https://api.dicebear.com/9.x/thumbs/svg?seed=${user['name']}&radius=50',
                      width: size / 2,
                      height: size / 2,
                    ),
                    SizedBox(height: 5), // 간격 조정
                    Row(
                      children: [
                        Text(
                          user['name'],
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isRunning ? null : Colors.grey[300]),
                        ),
                        isTop && isRunning
                            ? Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
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
                                  child: Text(
                                    '활동중',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              )
                            : SizedBox(),
                      ],
                    ),
                    isTop
                        ? Text(
                            '${formattedTime(user['remaining_seconds'])} 남았어요',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          )
                        : SizedBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HalfCirclePainter extends CustomPainter {
  final double percentage;
  final bool isTop;
  final bool isRunning;

  HalfCirclePainter(this.percentage, {this.isTop = false, this.isRunning = false});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;

    final Paint backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = isTop ? 36 : 12 // 상단은 더 두껍게
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // 선 끝을 둥글게

    final Paint progressPaint = Paint()
      ..color = isRunning ? Colors.redAccent : Colors.blue // 필요에 따라 색상 변경 가능
      ..strokeWidth = isTop ? 36 : 12 // 상단은 더 두껍게
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // 선 끝을 둥글게

    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, 0), // 위쪽 반원 중심
      radius: radius,
    );

    final double startAngle = -pi; // 왼쪽부터 시작
    final double sweepAngle = pi; // 180도 (반원)

    // 배경 반원 그리기
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // 진행 반원 그리기
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * percentage,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
