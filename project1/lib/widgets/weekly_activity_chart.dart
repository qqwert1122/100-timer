import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/timer_provider.dart';

class WeeklyActivityChart extends StatelessWidget {
  const WeeklyActivityChart({super.key});

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final activityData = timerProvider.weeklyActivityData;

    // 최대 활동 시간을 계산하여 스케일 조정
    final maxHours =
        activityData.isNotEmpty ? activityData.map((data) => data['hours'] + (data['minutes'] / 60)).reduce((a, b) => a > b ? a : b) : 0;

    const double minBarHeight = 20.0; // 최소 막대 높이
    const double maxBarHeight = 150.0; // 최대 막대 높이로 화면 넘침 방지

    return Container(
      height: 300, // 차트의 전체 높이
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end, // 모든 막대를 하단 정렬
        children: List.generate(activityData.length, (index) {
          final day = activityData[index]['day']; // 요일
          final hours = activityData[index]['hours']; // 활동 시간 (시간 단위)
          final minutes = (activityData[index]['minutes'] % 60).toInt(); // 소수점 제거 후 int로 변환
          final totalActivityTime = hours + (minutes / 60); // 총 활동 시간

          // 막대 높이 계산 (시간 단위로 비율 설정) + 최소 높이 보장
          final barHeight = maxHours > 0 ? totalActivityTime / maxHours * maxBarHeight : minBarHeight;

          // 상단에 표시할 텍스트 정의
          String displayTimeText = _formatTime(totalActivityTime);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 시간이 0이 아닌 경우에만 텍스트와 막대 그래프 표시
              if (totalActivityTime > 0) ...[
                // 막대 상단에 시간 텍스트 표시
                Text(
                  displayTimeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                // 막대 그래프
                Container(
                  width: 30, // 막대 너비 조정
                  height: barHeight < minBarHeight ? minBarHeight : barHeight,
                  decoration: BoxDecoration(
                    color: _getColorForActivity(totalActivityTime), // 활동 시간에 따라 색상 변경
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              // 요일 라벨 (막대와 무관하게 항상 동일한 높이에 표시)
              Padding(
                padding: const EdgeInsets.only(top: 4.0), // 막대와의 간격 유지
                child: Text(
                  day,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // 활동 시간에 따라 색상을 반환하는 함수
  Color _getColorForActivity(double hours) {
    if (hours < 1) {
      return Colors.red.shade200; // 1시간 미만
    } else if (hours >= 1 && hours < 3) {
      return Colors.red.shade300; // 1시간 이상 3시간 미만
    } else if (hours >= 3 && hours < 5) {
      return Colors.red.shade400; // 3시간 이상 5시간 미만
    } else {
      return Colors.red.shade600; // 5시간 이상
    }
  }

  // 시간을 포맷팅하는 함수 (0시간 30분, 2시간 0분 등)
  String _formatTime(double hours) {
    int h = hours.toInt();
    int minutes = ((hours - h) * 60).toInt();
    if (h == 0) {
      return minutes == 0 ? '' : '$minutes분'; // 0시간일 때는 분만 표시, 0분일 때는 빈 텍스트
    } else if (minutes == 0) {
      return '$h시간';
    } else {
      return '$h시간 $minutes분';
    }
  }
}
