import 'package:flutter/material.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';

class WeeklyHeatmap extends StatefulWidget {
  final String userId;
  final bool showAllHours;

  const WeeklyHeatmap({super.key, required this.userId, required this.showAllHours});

  @override
  State<WeeklyHeatmap> createState() => _WeeklyHeatmapState();
}

class _WeeklyHeatmapState extends State<WeeklyHeatmap> {
  final DatabaseService _dbService = DatabaseService();

  Map<String, Map<String, Map<String, int>>> heatmapData = {};

  final List<String> dayKeys = ['월', '화', '수', '목', '금', '토', '일'];
  List<String> allHourKeys = List.generate(24, (index) => '${index.toString().padLeft(2, '0')}:00');
  List<String> activeHourKeys = [];

  final Map<String, Color> activityColorMap = {};
  final Map<String, String> activityNames = {};

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    generateWeeklyHeatmap();
  }

  // 활동 색상 초기화
  Future<void> initializeActivityColors() async {
    List<Map<String, dynamic>> activities = await _dbService.getActivities(widget.userId);
    for (var activity in activities) {
      String activityId = activity['activity_id'];
      Color color = ColorService.hexToColor(activity['activity_color']);
      activityColorMap[activityId] = color;
      activityNames[activityId] = activity['activity_name'];
    }
  }

  // 주간 히트맵 데이터 생성
  Future<void> generateWeeklyHeatmap() async {
    try {
      await initializeActivityColors();

      List<Map<String, dynamic>> sessions = await _dbService.getSessionsForCurrentWeek(widget.userId);

      Set<String> activeHourSet = {};

      Map<String, Map<String, Map<String, int>>> tempHeatmapData = {};

      for (var session in sessions) {
        String activityId = session['activity_id'];
        DateTime startTime = DateTime.parse(session['start_time']).toLocal();
        DateTime endTime = session['end_time'] != null ? DateTime.parse(session['end_time']).toLocal() : DateTime.now();

        DateTime current = startTime;
        while (current.isBefore(endTime)) {
          DateTime nextHour = DateTime(current.year, current.month, current.day, current.hour + 1);
          DateTime segmentEnd = endTime.isBefore(nextHour) ? endTime : nextHour;

          int minutes = segmentEnd.difference(current).inMinutes;

          String hourKey = '${current.hour.toString().padLeft(2, '0')}:00';
          String dayKey = dayKeys[current.weekday - 1];

          activeHourSet.add(hourKey);

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

      activeHourKeys = tempHeatmapData.keys.toList();
      activeHourKeys.sort();

      if (!mounted) return; // 위젯이 활성화된 상태인지 확인
      setState(() {
        heatmapData = tempHeatmapData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // 위젯이 활성화된 상태인지 확인
      setState(() {
        errorMessage = '데이터를 불러오는 중 오류가 발생했습니다.';
        isLoading = false;
      });
    }
  }

  // 주간 히트맵 위젯 생성
  Widget buildWeeklyHeatmapWidget() {
    List<String> displayHourKeys = widget.showAllHours ? allHourKeys : activeHourKeys;

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
          // 요일 헤더
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

                    // 활동 강도에 따라 색상의 명도 조절
                    double intensity = (dominantMinutes / 60.0).clamp(0.2, 1.0);

                    // 색상의 밝기를 조절
                    Color color = baseColor.withOpacity(intensity);

                    // Tooltip에 활동 이름과 시간 표시
                    String activityName = activityNames[dominantActivityId] ?? '알 수 없는 활동';

                    return Container(
                      width: 40,
                      height: 20,
                      decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.all(Radius.circular(6))),
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

  // 활동 범례 위젯 생성
  Widget buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 4.0,
        children: activityColorMap.entries.map((entry) {
          String activityId = entry.key;
          Color color = entry.value;
          String activityName = activityNames[activityId] ?? '알 수 없는 활동';

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
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
      return Center(child: Text(errorMessage!));
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildWeeklyHeatmapWidget(),
          const SizedBox(height: 16),
          buildLegend(),
        ],
      );
    }
  }
}
