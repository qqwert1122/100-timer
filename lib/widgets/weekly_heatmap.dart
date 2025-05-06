import 'package:flutter/material.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class WeeklyHeatmap extends StatefulWidget {
  final bool showAllHours;

  const WeeklyHeatmap({super.key, required this.showAllHours});

  @override
  State<WeeklyHeatmap> createState() => _WeeklyHeatmapState();
}

class _WeeklyHeatmapState extends State<WeeklyHeatmap> {
  late StatsProvider _statsProvider;

  // heatmapData 구조: { hourKey: { dayKey: { activityId: minutes } } }
  Map<String, Map<String, Map<String, int>>> heatmapData = {};

  final List<String> dayKeys = ['월', '화', '수', '목', '금', '토', '일'];
  List<String> allHourKeys =
      List.generate(24, (index) => '${index.toString().padLeft(2, '0')}:00');
  List<String> activeHourKeys = [];

  final Map<String, Color> activityColorMap = {};
  final Map<String, String> activityNames = {};

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _statsProvider = Provider.of<StatsProvider>(context, listen: false);
    // 리스너 추가: weekOffset 변경 시 heatmap 재생성
    _statsProvider.addListener(_onStatsProviderChanged);
    generateWeeklyHeatmap();
  }

  @override
  void dispose() {
    _statsProvider.removeListener(_onStatsProviderChanged);
    super.dispose();
  }

  void _onStatsProviderChanged() {
    // weekOffset가 변경되면 heatmap 데이터를 다시 생성
    generateWeeklyHeatmap();
  }

  Future<void> generateWeeklyHeatmap() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // 과거 legend 값이 있었다면 초기화
      activityColorMap.clear();
      activityNames.clear();

      // offset를 반영하여 해당 주의 세션 데이터 로드
      List<Map<String, dynamic>> sessions =
          await _statsProvider.getSessionsForWeek(_statsProvider.weekOffset);

      Set<String> activeHourSet = {};

      Map<String, Map<String, Map<String, int>>> tempHeatmapData = {};

      for (var session in sessions) {
        String activityId = session['activity_id'];
        DateTime startTime = DateTime.parse(session['start_time']).toLocal();
        DateTime endTime = session['end_time'] != null
            ? DateTime.parse(session['end_time']).toLocal()
            : DateTime.now();
        Color color = ColorService.hexToColor(session['activity_color']);
        activityColorMap[session['activity_id']] = color;
        activityNames[session['activity_id']] = session['activity_name'];
        // session_duration 활용 (초 단위)
        int sessionDuration = session['duration'] ?? 0;
        int totalSeconds = endTime.difference(startTime).inSeconds;
        if (totalSeconds == 0) totalSeconds = 1;
        double ratio = sessionDuration / totalSeconds;

        DateTime current = startTime;
        while (current.isBefore(endTime)) {
          DateTime nextHour = DateTime(
              current.year, current.month, current.day, current.hour + 1);
          DateTime segmentEnd = endTime.isBefore(nextHour) ? endTime : nextHour;

          int rawMinutes = segmentEnd.difference(current).inMinutes;
          int activeMinutes = (rawMinutes * ratio).round(); // 휴식 제외 비율 반영

          String hourKey = '${current.hour.toString().padLeft(2, '0')}:00';
          String dayKey = dayKeys[current.weekday - 1];

          activeHourSet.add(hourKey);

          tempHeatmapData.putIfAbsent(hourKey, () => {});
          tempHeatmapData[hourKey]!.putIfAbsent(dayKey, () => {});
          tempHeatmapData[hourKey]![dayKey]!.update(
            activityId,
            (value) => value + activeMinutes,
            ifAbsent: () => activeMinutes,
          );
          current = segmentEnd;
        }
      }

      activeHourKeys = tempHeatmapData.keys.toList();
      activeHourKeys.sort();

      if (!mounted) return;
      setState(() {
        heatmapData = tempHeatmapData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = '데이터를 불러오는 중 오류가 발생했습니다.';
        isLoading = false;
      });
    }
  }

  Widget buildWeeklyHeatmapWidget() {
    List<String> displayHourKeys =
        widget.showAllHours ? allHourKeys : activeHourKeys;

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
                    style: AppTextStyles.getBody(context).copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }),
            ],
          ),
          ...displayHourKeys.map((hourKey) {
            return Row(
              children: [
                Container(
                  width: 60,
                  height: 15,
                  alignment: Alignment.center,
                  child: Text(
                    hourKey,
                    style: AppTextStyles.getCaption(context),
                  ),
                ),
                ...dayKeys.map((dayKey) {
                  Map<String, int>? activityTimes =
                      heatmapData[hourKey]?[dayKey];

                  if (activityTimes == null || activityTimes.isEmpty) {
                    return Container(
                      width: 40,
                      height: 15,
                      margin: const EdgeInsets.all(1),
                    );
                  } else {
                    String dominantActivityId = activityTimes.entries
                        .reduce((a, b) => a.value >= b.value ? a : b)
                        .key;
                    int dominantMinutes = activityTimes[dominantActivityId]!;

                    Color baseColor =
                        activityColorMap[dominantActivityId] ?? Colors.blue;
                    double intensity = (dominantMinutes / 60.0).clamp(0.2, 1.0);
                    Color color = baseColor.withOpacity(intensity);

                    String activityName =
                        activityNames[dominantActivityId] ?? '알 수 없는 활동';

                    return Container(
                      width: 40,
                      height: 15,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(6))),
                      margin: const EdgeInsets.all(1),
                      child: Tooltip(
                        message:
                            '$dayKey $hourKey\n$activityName\n$dominantMinutes분',
                        child: Center(
                          child: Text(
                              dominantMinutes > 0 ? '$dominantMinutes' : '',
                              style: AppTextStyles.getCaption(context).copyWith(
                                fontSize: 8,
                              )),
                        ),
                      ),
                    );
                  }
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

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
                style: AppTextStyles.getCaption(context).copyWith(
                  color: AppColors.textPrimary(context),
                ),
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
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300.withOpacity(0.2),
        highlightColor: Colors.grey.shade100.withOpacity(0.2),
        child: Container(
          width: context.wp(90),
          height: context.hp(68),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.background(context),
          ),
        ),
      );
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
