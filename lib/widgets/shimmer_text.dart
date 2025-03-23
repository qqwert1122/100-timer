import 'package:flutter/material.dart';

class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const ShimmerText({
    Key? key,
    required this.text,
    required this.style,
  }) : super(key: key);

  @override
  _ShimmerTextState createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white,
                Colors.white.withOpacity(0.2),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(1 + 2 * _controller.value, 0),
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
          },
          blendMode: BlendMode.srcATop,
          child: Text(
            widget.text,
            style: widget.style,
          ),
        );
      },
    );
  }
}
