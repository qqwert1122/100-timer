import 'package:flutter/material.dart';

class ToggleTotalViewSwtich extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleTotalViewSwtich({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  _ToggleTotalViewSwtich createState() => _ToggleTotalViewSwtich();
}

class _ToggleTotalViewSwtich extends State<ToggleTotalViewSwtich> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    if (widget.value) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ToggleTotalViewSwtich oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 45,
        height: 25,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: widget.value ? Colors.blueAccent : Colors.grey,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 스위치 썸
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              left: widget.value ? 20.0 : 0.0,
              top: 2.0,
              child: Container(
                width: 25,
                height: 21,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: FadeTransition(
                  opacity: _iconOpacity,
                  child: widget.value
                      ? const Icon(
                          Icons.bar_chart,
                          color: Colors.blueAccent,
                          size: 20,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
