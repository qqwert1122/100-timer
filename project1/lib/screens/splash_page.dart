import 'package:flutter/material.dart';
import 'timer_page.dart'; // 메인 화면 파일

class SplashScreen extends StatefulWidget {
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

    // 1초 후에 메인 화면으로 전환
    Future.delayed(const Duration(milliseconds: 1300), () {
      _controller.forward();
      Future.delayed(Duration(milliseconds: 700), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const TimerPage()), // 메인 화면으로 전환
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
