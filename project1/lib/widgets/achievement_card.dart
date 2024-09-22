import 'package:flutter/material.dart';
import 'package:project1/models/achievement.dart';

class AchievementCard extends StatefulWidget {
  final Achievement achievement;

  const AchievementCard({required this.achievement, super.key});

  @override
  _AchievementCardState createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void _toggleCard() {
    setState(() {
      _isFlipped = !_isFlipped;
      if (_isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.14; // 180도 회전

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(angle),
            child: _isFlipped ? _buildBackCard(angle) : _buildFrontCard(),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 400,
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 가로로 꽉 차도록 설정
          children: [
            Expanded(
              // 이미지가 남은 공간을 차지하도록 설정
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8.0)), // 위쪽 모서리만 둥글게
                child: Image.asset(
                  widget.achievement.imageUrl,
                  fit: BoxFit.cover, // 이미지를 꽉 채움
                  cacheHeight: 400, // 리사이즈하여 메모리 최적화
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.achievement.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 36,
                  fontFamily: 'Wiro',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(angle) {
    return FadeTransition(
      opacity: _controller.drive(Tween<double>(begin: 0, end: 1)),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 400,
          width: 300,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(angle), // 뒷면은 회전하지 않음
                  child: Text(
                    widget.achievement.content,
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Wiro',
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
