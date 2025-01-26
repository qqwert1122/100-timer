import 'package:flutter/material.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:project1/utils/responsive_size.dart';
import 'timer_page.dart';

class SplashScreen extends StatefulWidget {
  final String userId;

  const SplashScreen({super.key, required this.userId});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late DatabaseService _dbService;
  Map<String, dynamic>? _timerData;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializationFuture = _initializeProviders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_animationController);

    _animationController.forward();
  }

  Future<void> _initializeProviders() async {
    _dbService = Provider.of<DatabaseService>(context, listen: false);

    await Future.wait([
      context.read<StatsProvider>().initialized,
      context.read<TimerProvider>().initialized,
      _initializeApp(),
    ]);
  }

  Future<void> _initializeApp() async {
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

    await _animationController.forward();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              _timerData!['state'] != 'STOP' ? TimerRunningPage(timerData: _timerData!) : TimerPage(timerData: _timerData!),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
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
      'state': 'STOP',
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToNextScreen();
            });
          }

          return AnimatedBuilder(
            animation: _opacityAnimation,
            builder: (_, __) => _buildSplashContent(),
          );
        },
      ),
    );
  }

  Widget _buildSplashContent() {
    return Opacity(
      opacity: _opacityAnimation.value,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_3.png',
              width: context.wp(50),
              height: context.hp(30),
            ),
            SizedBox(height: context.spacing_md),
            Text('100 - Timer', style: AppTextStyles.getTitle(context)),
          ],
        ),
      ),
    );
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            _timerData!['state'] != 'STOP' ? TimerRunningPage(timerData: _timerData!) : TimerPage(timerData: _timerData!),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}
