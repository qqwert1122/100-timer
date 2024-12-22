import 'package:flutter/material.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/utils/database_service.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'timer_page.dart';

class SplashScreen extends StatefulWidget {
  final String userId;

  const SplashScreen({super.key, required this.userId});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late DatabaseService _dbService;
  Map<String, dynamic>? _timerData;

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    _initializeApp(); // 비동기 작업을 호출
  }

  Future<void> _initializeApp() async {
    DateTime startTime = DateTime.now(); // 로딩 시작 시간 기록

    DateTime now = DateTime.now();
    String weekStart = getWeekStart(now); // 예시 2024-09-23

    // 사용자 데이터 가져오기
    await _dbService.fetchOrDownloadUser();

    // **사용자 데이터가 완전히 로드된 후에 활동 데이터를 가져옵니다.**
    List<Map<String, dynamic>> activities = await _dbService.getActivities();

    if (activities.isEmpty) {
      // 활동 데이터가 없으면 서버에서 다운로드
      await _dbService.downloadDataFromServer();

      // 활동 데이터를 다시 로드
      activities = await _dbService.getActivities();

      // 여전히 activities가 비어있다면 기본 활동을 생성하거나 오류 처리
      if (activities.isEmpty) {
        print('활동 데이터를 가져올 수 없습니다.');
        // 기본 활동 생성 로직 또는 오류 처리 로직 추가
      }
    }

    // 타이머가 있는지 확인
    Map<String, dynamic>? timer = await _dbService.getTimer(weekStart);

    if (timer == null) {
      timer = await _createDefaultTimer(widget.userId);
      await _dbService.createTimer(timer);
    }

    _timerData = timer;

    Widget destinationPage;

    if (_timerData!['is_running'] == 1) {
      destinationPage = const TimerRunningPage();
    } else {
      destinationPage = TimerPage(timerData: _timerData!);
    }

    // 최소 로딩 시간 설정 (1초)
    Duration minimumLoadingTime = const Duration(seconds: 1);
    Duration elapsedTime = DateTime.now().difference(startTime);
    Duration remainingTime = minimumLoadingTime - elapsedTime;

    if (remainingTime > Duration.zero) {
      // 로딩이 너무 빨리 끝났으므로, 남은 시간만큼 대기
      await Future.delayed(remainingTime);
    }

    // 메인 화면으로 전환
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => destinationPage, // null이 아님을 보장
      ),
    );
  }

  // 기본 타이머 생성 메서드
  Future<Map<String, dynamic>> _createDefaultTimer(String userId) async {
    final now = DateTime.now();
    final timerId = const Uuid().v4();
    Map<String, dynamic>? userData = await _dbService.getUser();
    int userTotalSeconds = userData?['total_seconds'] ?? 360000; // 기본값은 100시간

    return {
      'uid': userId,
      'timer_id': timerId,
      'week_start': getWeekStart(now),
      'total_seconds': userTotalSeconds,
      'last_session_id': null,
      'is_running': 0,
      'created_at': now.toUtc().toIso8601String(), // toUtc로 변경
      'deleted_at': null,
      'last_started_at': null,
      'last_ended_at': null,
      'last_updated_at': now.toUtc().toIso8601String(),
      'last_notified_at': null,
      'is_deleted': 0,
      'sessions_over_1hour': 0,
      'timezone': DateTime.now().timeZoneName,
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
    // 로딩 중에도 항상 로고 이미지를 표시
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}
