import 'package:flutter/material.dart';
import 'package:project1/utils/database_service.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'timer_page.dart'; // 메인 화면 파일

class SplashScreen extends StatefulWidget {
  final String userId;

  const SplashScreen({super.key, required this.userId});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final String userId = 'v3_4';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // 1초간 서서히 사라짐
      vsync: this,
    );

    // 투명도 애니메이션 (1 -> 0으로 서서히 사라짐)
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

    _initializeApp(); // 비동기 작업을 호출
  }

  Future<void> _initializeApp() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final db = await dbService.database;

    DateTime now = DateTime.now();
    String weekStart = getWeekStart(now); // 예시 2024-09-23

    // 타이머가 있는지 확인
    Map<String, dynamic>? timer = await dbService.getTimer(userId, weekStart);

    // 타이머가 없으면 생성
    if (timer == null) {
      try {
        timer = _createDefaultTimer(userId);
        await dbService.createTimer(userId, timer);
        print('새로운 타이머가 생성되었습니다.');
      } on DatabaseException catch (e) {
        if (e.isUniqueConstraintError()) {
          // UNIQUE 제약 조건 위반 시 기존 타이머를 다시 가져옴
          timer = await dbService.getTimer(userId, weekStart);
          print('타이머가 이미 존재하여 기존 타이머를 불러왔습니다.');
        } else {
          // 기타 데이터베이스 예외 처리
          print('데이터베이스 오류 발생: $e');
          // 필요 시 에러 처리 로직 추가
        }
      }
    }
    print('타이머가 데이터베이스에서 불러와졌습니다: $timer');

    // activity
    await dbService.initializeActivityList(db, userId);

    // 1초 후에 메인 화면으로 전환
    Future.delayed(const Duration(milliseconds: 1000), () {
      _controller.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
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
      'user_id': userId,
      'week_start': getWeekStart(now),
      'total_seconds': 100 * 3600,
      'remaining_seconds': 100 * 3600,
      'last_activity_log_id': null,
      'is_running': 0,
      'created_at': now.toIso8601String(),
      'last_started_at': null,
      'last_updated_at': now.toIso8601String(),
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
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset(
            'assets/images/logo_1.png',
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }
}
