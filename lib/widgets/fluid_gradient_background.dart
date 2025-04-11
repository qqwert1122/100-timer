import 'dart:math';

import 'package:flutter/material.dart';

class FluidGradientBackground extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FluidGradientBackground({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 15),
  }) : super(key: key);

  @override
  State<FluidGradientBackground> createState() => _FluidGradientBackgroundState();
}

class _FluidGradientBackgroundState extends State<FluidGradientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            SizedBox.expand(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: FluidGradientPainter(
                    animation: curvedAnimation.value,
                  ),
                ),
              ),
            ),
            Positioned.fill(child: widget.child),
          ],
        );
      },
    );
  }
}

class FluidGradientPainter extends CustomPainter {
  final double animation;

  // 블롭 데이터를 저장하는 리스트
  final List<Map<String, dynamic>> blobs = [
    {
      'basePosition': Offset(0.2, 0.2),
      'radiusX': 0.6,
      'radiusY': 0.7,
      'colors': [Colors.redAccent.shade700, Colors.deepPurpleAccent.shade700],
      'blurSigma': 60.0,
      'speed': 1.0,
      'phaseOffset': 0.0,
    },
    {
      'basePosition': Offset(0.5, 0.5),
      'radiusX': 0.7,
      'radiusY': 0.6,
      'colors': [Colors.deepOrangeAccent.shade700, Colors.yellowAccent.shade700],
      'blurSigma': 50.0,
      'speed': 2.0,
      'phaseOffset': 0.3,
    },
    {
      'basePosition': Offset(0.8, 0.3),
      'radiusX': 0.5,
      'radiusY': 0.5,
      'colors': [Colors.blue.shade700, Colors.orangeAccent.shade700],
      'blurSigma': 60.0,
      'speed': 1.0,
      'phaseOffset': 0.1,
    },
  ];

  FluidGradientPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    // 배경 그라데이션
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.redAccent.shade700, // 진한 파란색 배경
    );

    // 각 블롭을 그립니다
    for (var blob in blobs) {
      drawBlurredBlob(
        canvas,
        size,
        animation,
        blob['basePosition'] as Offset,
        (blob['radiusX'] as double) * size.width,
        (blob['radiusY'] as double) * size.height,
        blob['colors'] as List<Color>,
        blob['blurSigma'] as double,
        BlendMode.screen,
        blob['speed'] as double,
        blob['phaseOffset'] as double,
      );
    }
  }

  void drawBlurredBlob(
    Canvas canvas,
    Size size,
    double animValue,
    Offset basePosition,
    double radiusX,
    double radiusY,
    List<Color> colors,
    double blurSigma,
    BlendMode blendMode,
    double speed,
    double phaseOffset,
  ) {
    // 2pi를 사용하여 애니메이션이 한 주기를 완료할 때 같은 위치로 돌아오도록 함
    double phase = (animValue * speed + phaseOffset) * 2 * pi;

    // 애니메이션에 따라 위치 변화 (sin/cos 함수로 완벽한 원형 경로)
    double xOffset = basePosition.dx * size.width + sin(phase) * (size.width * 0.05);
    double yOffset = basePosition.dy * size.height + cos(phase) * (size.height * 0.05);

    // 그라데이션 생성
    final rect = Rect.fromCenter(
      center: Offset(xOffset, yOffset),
      width: radiusX * 2,
      height: radiusY * 2,
    );

    // 타원형 그라데이션
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: colors,
      stops: [0.0, 1.0],
    ).createShader(rect);

    // 블러 처리된 블롭을 그리기 위한 Paint 객체
    Paint blobPaint = Paint()
      ..shader = gradient
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma)
      ..blendMode = blendMode;

    // 타원 그리기
    canvas.drawOval(rect, blobPaint);
  }

  @override
  bool shouldRepaint(FluidGradientPainter oldDelegate) => true;
}
