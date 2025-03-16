import 'package:flutter/material.dart';
import 'package:project1/screens/timer_page.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/responsive_size.dart';

class TimerResultPage extends StatelessWidget {
  final Map<String, dynamic> timerData;
  final int sessionDuration;
  final bool isExceeded;

  const TimerResultPage({
    super.key,
    required this.timerData,
    required this.sessionDuration,
    required this.isExceeded,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: context.hp(2)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black54,
                      size: context.md,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            right: -context.wp(2.5),
                            top: -context.hp(1.5),
                            child: Transform.rotate(
                              angle: 0.05,
                              child: _buildCard(context, Colors.blue.shade100, 0.5),
                            ),
                          ),
                          Positioned(
                            left: -context.wp(2.5),
                            top: -context.hp(1.5),
                            child: Transform.rotate(
                              angle: -0.05,
                              child: _buildCard(context, Colors.orange.shade100, 0.5),
                            ),
                          ),
                          _buildMainCard(context),
                        ],
                      ),
                      SizedBox(height: context.hp(15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: context.spacing_sm,
                right: context.spacing_sm,
                bottom: context.spacing_sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: context.wp(2),
                    offset: Offset(0, -context.hp(0.5)),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: context.hp(7),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TimerPage(timerData: timerData),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.wp(3)),
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(
                        fontSize: context.md,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Color color, double opacity) {
    return Container(
      width: context.wp(90),
      height: context.hp(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.wp(5)),
        color: color.withOpacity(opacity),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final activityColor = ColorService.hexToColor(timerProvider.currentActivityColor);

    String formatDuration(int seconds) {
      final Duration duration = Duration(seconds: seconds);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final remainingSeconds = duration.inSeconds.remainder(60);

      return '$hours시간 $minutes분 $remainingSeconds초';
    }

    String formatTargetDuration() {
      return formatDuration(timerProvider.currentSessionTargetDuration!);
    }

    return Container(
      width: context.wp(90),
      height: context.hp(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.wp(5)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            activityColor.withOpacity(0.8),
            activityColor.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: context.wp(0.5),
            blurRadius: context.wp(2.5),
            offset: Offset(0, context.hp(0.4)),
          ),
        ],
      ),
      padding: context.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '활동을 완료했습니다',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.md,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.hp(2)),
          Text(
            formatDuration(sessionDuration),
            style: TextStyle(
              color: Colors.white,
              fontSize: context.xl,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Center(
            child: Icon(
              isExceeded ? Icons.emoji_events_rounded : Icons.check_circle_outline,
              size: context.xxl,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
