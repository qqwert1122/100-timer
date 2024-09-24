import 'package:flutter/material.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'timer_page.dart'; // 메인 화면 파일

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 애니메이션 컨트롤러 설정 (2초간 지속되는 애니메이션)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700), // 1초간 서서히 사라짐
      vsync: this,
    );

    // 투명도 애니메이션 (1 -> 0으로 서서히 사라짐)
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

    _initializeTimer(); // 비동기 작업을 호출
  }

  Future<void> _initializeTimer() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    const String userId = 'v3_2';
    DateTime now = DateTime.now();
    String weekStart = getWeekStart(now); // 예시 2024-09-23 00:00:00.000

    // 타이머가 있는지 확인
    Map<String, dynamic>? timer = await dbService.getTimer(userId, weekStart);

    // 타이머가 없으면 생성
    if (timer == null) {
      timer = _createDefaultTimer(userId);
      await dbService.createTimer(timer);
      print('새로운 타이머가 생성되었습니다.');
    }
    print('타이머가 데이터베이스에서 불러와졌습니다: $timer');

    // 1초 후에 메인 화면으로 전환
    Future.delayed(const Duration(milliseconds: 1300), () {
      _controller.forward();
      Future.delayed(const Duration(milliseconds: 700), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TimerPage(timerData: timer!), // null이 아님을 보장
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 기본 타이머 생성 메서드
  Map<String, dynamic> _createDefaultTimer(String userId) {
    final now = DateTime.now();
    final timerId = const Uuid().v4();

    return {
      'timer_id': timerId,
      'user_id': userId, // 기본 사용자 ID (예시)
      'week_start': getWeekStart(now), // 현재 주 시작 시간
      'total_seconds': 100 * 3600, // 100시간(초 단위)
      'remaining_seconds': 100 * 3600, // 초기 남은 시간은 100시간
      'last_activity_id': null, // 아직 활동 없음
      'created_at': now.toIso8601String(), // 생성시간을 문자열로 저장
      'last_updated_at': now.toIso8601String(), // 마지막 업데이트 = 생성
      'last_started_at': null, // 아직 시작하지 않음
      'is_running': 0, // 아직 시작하지 않음
    };
  }

  String getWeekStart(DateTime date) {
    int weekday = date.weekday;
    // 월요일을 기준으로 주 시작일을 계산 (월요일이 1, 일요일이 7)
    DateTime weekStart = date.subtract(Duration(days: weekday - 1));
    return weekStart.toIso8601String().split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 흰색 배경
      body: Center(
        child: FadeTransition(
          opacity: _animation, // 애니메이션 연결
          child: Image.asset(
            'assets/images/logo_1.png', // 로고 이미지 경로
            width: 150, // 로고 너비
            height: 150, // 로고 높이
          ),
        ),
      ),
    );
  }
}
