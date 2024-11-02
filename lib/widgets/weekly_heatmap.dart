import 'package:flutter/material.dart';
import 'package:project1/utils/color_service.dart';
// 햅틱 피드백을 위해 추가
import 'package:project1/utils/database_service.dart';

class WeeklyHeatmap extends StatefulWidget {
  final String userId;
  final bool showAllHours;

  const WeeklyHeatmap({super.key, required this.userId, required this.showAllHours});

  @override
  State<WeeklyHeatmap> createState() => _WeeklyHeatmapState();
}

class _WeeklyHeatmapState extends State<WeeklyHeatmap> {
  final DatabaseService _dbService = DatabaseService(); // DatabaseService 초기화

  // 히트맵 데이터
  Map<String, Map<String, Map<String, int>>> heatmapData = {};

  // 요일 및 시간대 키
  final List<String> dayKeys = ['월', '화', '수', '목', '금', '토', '일'];
  List<String> allHourKeys = List.generate(24, (index) => '${index.toString().padLeft(2, '0')}:00');
  List<String> activeHourKeys = [];

  // 활동별 색상 및 이름 매핑
  final Map<String, Color> activityColorMap = {};
  final Map<String, String> activityNames = {};

  // 로딩 및 에러 상태 관리
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    generateWeeklyHeatmap();
  }

  // 활동별 색상 초기화
  Future<void> initializeActivityColors() async {
    List<Map<String, dynamic>> activities = await _dbService.getActivityList(widget.userId);
    for (int i = 0; i < activities.length; i++) {
      String activityId = activities[i]['activity_list_id'];
      Color color = ColorService.hexToColor(activities[i]['activity_color']); // 색상 반복 사용
      activityColorMap[activityId] = color;
    }
  }

  // 활동 이름 초기화
  Future<void> initializeActivityNames() async {
    List<Map<String, dynamic>> activities = await _dbService.getActivityList(widget.userId);
    for (var activity in activities) {
      String activityId = activity['activity_list_id'];
      String activityName = activity['activity_name'];
      activityNames[activityId] = activityName;
    }
  }

  // 주간 히트맵 데이터 생성
  Future<void> generateWeeklyHeatmap() async {
    try {
      // 활동별 색상 및 이름 초기화
      await initializeActivityColors();
      await initializeActivityNames();

      // 이번 주의 활동 로그 가져오기
      List<Map<String, dynamic>> activityLogs = await _dbService.getActivityLogsForCurrentWeek(widget.userId);

      // 활동이 있는 시간대를 추출하기 위한 집합(Set)
      Set<String> activeHourSet = {};

      // 임시 히트맵 데이터 초기화
      Map<String, Map<String, Map<String, int>>> tempHeatmapData = {};

      for (var log in activityLogs) {
        String activityId = log['activity_id'];

        DateTime startTime = DateTime.parse(log['start_time']).toLocal();
        DateTime endTime = log['end_time'] != null ? DateTime.parse(log['end_time']).toLocal() : DateTime.now();

        DateTime current = startTime;
        while (current.isBefore(endTime)) {
          DateTime nextHour = DateTime(current.year, current.month, current.day, current.hour + 1);
          DateTime segmentEnd = endTime.isBefore(nextHour) ? endTime : nextHour;

          int minutes = segmentEnd.difference(current).inMinutes;

          String hourKey = '${current.hour.toString().padLeft(2, '0')}:00';
          String dayKey = dayKeys[current.weekday - 1];

          // 활동이 있는 시간대를 저장
          activeHourSet.add(hourKey);

          // 히트맵 데이터에 시간대와 요일에 해당하는 활동 시간을 누적
          tempHeatmapData.putIfAbsent(hourKey, () => {});
          tempHeatmapData[hourKey]!.putIfAbsent(dayKey, () => {});
          tempHeatmapData[hourKey]![dayKey]!.update(
            activityId,
            (value) => value + minutes,
            ifAbsent: () => minutes,
          );
          current = segmentEnd;
        }
      }

      // 활동이 있는 시간대를 리스트로 변환하고 정렬
      activeHourKeys = tempHeatmapData.keys.toList();
      activeHourKeys.sort();

      // 상태 업데이트
      setState(() {
        heatmapData = tempHeatmapData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // 주간 히트맵 위젯 생성
  Widget buildWeeklyHeatmapWidget() {
    List<String> displayHourKeys = widget.showAllHours ? allHourKeys : activeHourKeys;

    // 만약 토글이 활성화된 상태에서 모든 시간대를 표시하고, 표시할 시간대가 없을 때는 메시지 표시
    if (!isLoading && displayHourKeys.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('이번 주에 활동이 없습니다.'),
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 요일 표시
          Row(
            children: [
              Container(
                width: 70,
                height: 40,
                alignment: Alignment.center,
                child: const Text(''),
              ),
              ...dayKeys.map((dayKey) {
                return Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    dayKey,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ],
          ),
          // 시간대별 행 구성
          ...displayHourKeys.map((hourKey) {
            return Row(
              children: [
                // 시간대 표시
                Container(
                  width: 60,
                  height: 20,
                  alignment: Alignment.center,
                  child: Text(
                    hourKey,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                // 각 요일에 대한 셀 생성
                ...dayKeys.map((dayKey) {
                  Map<String, int>? activityTimes = heatmapData[hourKey]?[dayKey];

                  if (activityTimes == null || activityTimes.isEmpty) {
                    // 해당 시간대와 요일에 활동이 없으면 빈 셀
                    return Container(
                      width: 40,
                      height: 20,
                      margin: const EdgeInsets.all(1),
                    );
                  } else {
                    // 가장 많은 시간을 차지한 활동 찾기
                    String dominantActivityId = activityTimes.entries
                        .reduce(
                          (a, b) => a.value >= b.value ? a : b,
                        )
                        .key;
                    int dominantMinutes = activityTimes[dominantActivityId]!;

                    // 해당 활동의 색상 가져오기
                    Color baseColor = activityColorMap[dominantActivityId] ?? Colors.blue;

                    // 활동 강도에 따라 색상의 명도 조절 (0.2 ~ 1.0)
                    double intensity = (dominantMinutes / 60.0).clamp(0.2, 1.0);

                    // 색상의 밝기를 조절
                    Color color = baseColor.withOpacity(intensity);

                    // Tooltip에 활동 이름과 시간 표시
                    String activityName = activityNames[dominantActivityId] ?? 'Unknown Activity';

                    return Container(
                      width: 40,
                      height: 20,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.all(Radius.circular(6))),
                      margin: const EdgeInsets.all(1),
                      child: Tooltip(
                        message: '$dayKey $hourKey\n$activityName\n$dominantMinutes분',
                        child: Center(
                          child: Text(
                            dominantMinutes > 0 ? '$dominantMinutes' : '',
                            style: const TextStyle(fontSize: 8, color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  }
                }).toList(),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  // 범례 위젯 생성
  Widget buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 4.0,
        children: activityColorMap.entries.map((entry) {
          String activityId = entry.key;
          Color color = entry.value;
          String activityName = activityNames[activityId] ?? 'Unknown';

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color, // 배경 색상 설정
                  shape: BoxShape.circle, // 원형으로 설정
                ),
              ),
              const SizedBox(width: 4),
              Text(
                activityName,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      return Center(child: Text('에러: $errorMessage'));
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 히트맵 위젯
          buildWeeklyHeatmapWidget(),
          const SizedBox(height: 16),
          // 범례 추가
          buildLegend(),
        ],
      );
    }
  }
}
