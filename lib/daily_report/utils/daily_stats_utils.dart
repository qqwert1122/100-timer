import 'package:project1/utils/database_service.dart';

class DailyStatsUtils {
  static final DatabaseService _databaseService = DatabaseService();

  static Future<DailyStatsResult> getDailyStats(DateTime selectedDate) async {
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    // 세션 데이터 조회
    final sessions = await _databaseService.getSessionsWithinDateRange(
      startDate: selected,
      endDate: selected.add(Duration(days: 1)),
    );

    // 총 활동시간 계산 (초 단위)
    int totalSeconds = 0;
    for (var session in sessions) {
      if (session['end_time'] != null) {
        final start = DateTime.parse(session['start_time']);
        final end = DateTime.parse(session['end_time']);
        totalSeconds += end.difference(start).inSeconds;
      }
    }

    // 1시간(3600초) 미만이면 DataInsufficient
    final isDataInsufficient = totalSeconds < 3600;

    return DailyStatsResult(isDataInsufficient: isDataInsufficient);
  }

  // 총 활동시간 반환 (초 단위)
  static Future<int> getTotalActivityTime(DateTime selectedDate) async {
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final sessions = await _databaseService.getSessionsWithinDateRange(
      startDate: selected,
      endDate: selected.add(Duration(days: 1)),
    );

    int totalSeconds = 0;
    for (var session in sessions) {
      if (session['end_time'] != null) {
        final start = DateTime.parse(session['start_time']);
        final end = DateTime.parse(session['end_time']);
        totalSeconds += end.difference(start).inSeconds;
      }
    }
    return totalSeconds;
  }

// 활동별 시간 반환 (Map<활동명, 초>)
  static Future<Map<String, Map<String, dynamic>>> getActivityTimes(DateTime selectedDate) async {
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final sessions = await _databaseService.getSessionsWithinDateRange(
      startDate: selected,
      endDate: selected.add(Duration(days: 1)),
    );

    Map<String, Map<String, dynamic>> activityTimes = {};
    for (var session in sessions) {
      if (session['end_time'] != null) {
        final activityName = session['activity_name'] as String;
        final start = DateTime.parse(session['start_time']);
        final end = DateTime.parse(session['end_time']);
        final duration = end.difference(start).inSeconds;

        if (activityTimes.containsKey(activityName)) {
          activityTimes[activityName]!['duration'] += duration;
        } else {
          activityTimes[activityName] = {
            'activity_name': session['activity_name'],
            'activity_icon': session['activity_icon'],
            'activity_color': session['activity_color'],
            'duration': duration,
          };
        }
      }
    }
    return activityTimes;
  }

  static Future<List<Map<String, dynamic>>> getHourlyActivityChart(DateTime selectedDate) async {
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final sessions = await _databaseService.getSessionsWithinDateRange(
      startDate: selected.subtract(Duration(days: 1)),
      endDate: selected.add(Duration(days: 1)),
    );

    List<Map<String, dynamic>> hourlyData = [];
    for (var session in sessions) {
      if (session['end_time'] != null) {
        final start = DateTime.parse(session['start_time']);
        final end = DateTime.parse(session['end_time']);

        // 시간대별로 분배
        DateTime currentHour = DateTime(start.year, start.month, start.day, start.hour);
        DateTime sessionEnd = end;

        while (currentHour.isBefore(sessionEnd)) {
          DateTime nextHour = currentHour.add(Duration(hours: 1));
          DateTime segmentEnd = nextHour.isAfter(sessionEnd) ? sessionEnd : nextHour;

          // 현재 시간대에서 실제 시작/종료 시간 계산
          DateTime segmentStart = currentHour.isBefore(start) ? start : currentHour;
          double segmentMinutes = segmentEnd.difference(segmentStart).inMinutes.toDouble();

          if (segmentMinutes > 0) {
            if (currentHour.year == selected.year && currentHour.month == selected.month && currentHour.day == selected.day) {
              hourlyData.add({
                'hour': currentHour.hour,
                'activity_name': session['activity_name'],
                'activity_color': session['activity_color'],
                'activity_icon': session['activity_icon'],
                'minutes': segmentMinutes,
              });
            }
          }

          currentHour = nextHour;
        }
      }
    }
    return hourlyData;
  }

  static Future<int> calculateCurrentStreak(DateTime selectedDate) async {
    final earliestDate = await _databaseService.getEarliestSessionDate();
    if (earliestDate == null) return 0;

    int streak = 0;
    DateTime checkDate = selectedDate;

    while (checkDate.isAfter(earliestDate.subtract(Duration(days: 1)))) {
      final dayTotal = await getTotalActivityTime(checkDate);
      if (dayTotal >= 3600) {
        streak++;
        checkDate = checkDate.subtract(Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  static Future<Map<String, dynamic>> compareWithYesterday(DateTime selectedDate) async {
    final today = await getTotalActivityTime(selectedDate);
    final yesterday = await getTotalActivityTime(selectedDate.subtract(Duration(days: 1)));

    final difference = today - yesterday;
    final isIncrease = difference > 0;
    final diffHours = difference.abs() ~/ 3600;
    final diffMinutes = (difference.abs() % 3600) ~/ 60;

    String displayText;
    if (diffHours > 0) {
      displayText = '어제보다\n$diffHours시간 $diffMinutes분 ${isIncrease ? '증가' : '감소'}';
    } else {
      displayText = '어제보다\n$diffMinutes분 ${isIncrease ? '증가' : '감소'}';
    }

    String oneLineText;
    if (diffHours > 0) {
      oneLineText = '어제보다 $diffHours시간 $diffMinutes분 ${isIncrease ? '증가' : '감소'}';
    } else {
      oneLineText = '어제보다 $diffMinutes분 ${isIncrease ? '증가' : '감소'}';
    }

    return {
      'difference': difference,
      'isIncrease': isIncrease,
      'displayText': displayText,
      'oneLineText': oneLineText,
      'percentage': yesterday > 0 ? (difference / yesterday * 100).round() : 0,
    };
  }
}

class DailyStatsResult {
  final bool isDataInsufficient;

  DailyStatsResult({
    required this.isDataInsufficient,
  });
}
