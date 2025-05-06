import 'package:flutter/material.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class FocusModeCard extends StatefulWidget {
  const FocusModeCard({Key? key}) : super(key: key);

  @override
  State<FocusModeCard> createState() => _FocusModeCardState();
}

class _FocusModeCardState extends State<FocusModeCard> {
  // 슬라이더로 선택한 시간을 분 단위로 저장 (0 ~ 240)
  double _selectedMinutes = 60.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.paddingSM,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.sm,
              vertical: context.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.background(context),
              borderRadius: const BorderRadius.all(
                Radius.circular(32.0),
              ),
            ),
            child: Column(
              children: [
                SlidingTimer(
                  hours: _selectedMinutes.toInt() ~/ 60,
                  minutes: _selectedMinutes.toInt() % 60,
                  seconds: 0,
                  style: AppTextStyles.getTimeDisplay(context).copyWith(
                    fontFamily: 'chab',
                  ),
                ),
                SizedBox(
                  width: context.wp(60),
                  child: Slider(
                    value: _selectedMinutes,
                    min: 5.0,
                    max: 240.0,
                    divisions: 47, //5분씩 47단계
                    thumbColor: AppColors.textPrimary(context),
                    activeColor: AppColors.textPrimary(context),
                    label: _formatTime(_selectedMinutes.toInt()),
                    onChanged: (value) {
                      setState(() {
                        _selectedMinutes = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int minutes) {
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    return '${hours.toString()}h ${remainingMinutes.toString()}m';
  }
}

/// SlidingTimer는 각 자리수를 AnimatedNumber로 표시하여 변경 시 애니메이션 효과를 줍니다.
class SlidingTimer extends StatelessWidget {
  final int hours;
  final int minutes;
  final int seconds;
  final TextStyle? style;
  const SlidingTimer({
    Key? key,
    required this.hours,
    required this.minutes,
    required this.seconds,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hours
        AnimatedNumber(number: hours ~/ 10, style: style),
        AnimatedNumber(number: hours % 10, style: style),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('h', style: style),
        ),
        SizedBox(width: context.wp(2)),
        // Minutes
        AnimatedNumber(number: minutes ~/ 10, style: style),
        AnimatedNumber(number: minutes % 10, style: style),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('m', style: style),
        ),
      ],
    );
  }
}

class AnimatedNumber extends StatelessWidget {
  final int number;
  final TextStyle? style;

  const AnimatedNumber({
    super.key,
    required this.number,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 60,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        switchInCurve:
            const Interval(0.5, 1.0, curve: Curves.easeInOut), // 새 숫자는 후반부에
        switchOutCurve:
            const Interval(0.0, 0.5, curve: Curves.easeInOut), // 이전 숫자는 전반부에
        transitionBuilder: (Widget child, Animation<double> animation) {
          // 나가는 숫자의 애니메이션
          if (child.key != ValueKey<int>(number)) {
            return FadeTransition(
              opacity: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
              )),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
                )),
                child: child,
              ),
            );
          }

          return FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
            )),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
              )),
              child: child,
            ),
          );
        },
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          List<Widget> children = previousChildren;
          if (currentChild != null) {
            children = children.toList()..add(currentChild);
          }
          return Stack(
            alignment: Alignment.center,
            children: children,
          );
        },
        child: Text(
          number.toString().padLeft(1, '0'),
          key: ValueKey<int>(number),
          style: style,
        ),
      ),
    );
  }
}
