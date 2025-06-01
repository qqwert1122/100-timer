import 'package:project1/utils/database_service.dart';

class DailyStatsUtils {
  static final DatabaseService _databaseService = DatabaseService();
  // 휴식시간을 빼고 실제 활동시간 계산
  static Future<int> _getActualActivityTime(List<Map<String, dynamic>> sessions) async {
    int totalActivitySeconds = 0;

    for (var session in sessions) {
      if (session['end_time'] != null) {
        // 세션 전체 시간
        final start = DateTime.parse(session['start_time']);
        final end = DateTime.parse(session['end_time']);
        int sessionTotalSeconds = end.difference(start).inSeconds;

        // 해당 세션의 휴식시간 조회
        final breaks = await _databaseService.getBreaks(sessionId: session['session_id']);
        int breakSeconds = 0;

        for (var breakItem in breaks) {
          if (breakItem['end_time'] != null) {
            final breakStart = DateTime.parse(breakItem['start_time']);
            final breakEnd = DateTime.parse(breakItem['end_time']);
            breakSeconds += breakEnd.difference(breakStart).inSeconds;
          }
        }

        // 실제 활동시간 = 세션시간 - 휴식시간
        totalActivitySeconds += (sessionTotalSeconds - breakSeconds);
      }
    }

    return totalActivitySeconds;
  }

  static Future<DailyStatsResult> getDailyStats(DateTime selectedDate) async {
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    // 세션 데이터 조회
    final sessions = await _databaseService.getSessionsWithinDateRange(
      startDate: selected,
      endDate: selected.add(Duration(days: 1)),
    );
    // 휴식시간 제외한 실제 활동시간 계산
    final totalSeconds = await _getActualActivityTime(sessions);

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

    return await _getActualActivityTime(sessions);
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
        // 활동시간
        final activityName = session['activity_name'] as String;
        final start = DateTime.parse(session['start_time']);
        final end = DateTime.parse(session['end_time']);
        int sessionTotalSeconds = end.difference(start).inSeconds;

        // 휴식시간
        final breaks = await _databaseService.getBreaks(sessionId: session['session_id']);
        int breakSeconds = 0;

        for (var breakItem in breaks) {
          if (breakItem['end_time'] != null) {
            final breakStart = DateTime.parse(breakItem['start_time']);
            final breakEnd = DateTime.parse(breakItem['end_time']);
            breakSeconds += breakEnd.difference(breakStart).inSeconds;
          }
        }

        // 실제 활동시간
        final actualDuration = sessionTotalSeconds - breakSeconds;

        if (activityTimes.containsKey(activityName)) {
          activityTimes[activityName]!['duration'] += actualDuration;
        } else {
          activityTimes[activityName] = {
            'activity_name': session['activity_name'],
            'activity_icon': session['activity_icon'],
            'activity_color': session['activity_color'],
            'duration': actualDuration,
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

        // 해당 세션의 휴식시간들 조회
        final breaks = await _databaseService.getBreaks(sessionId: session['session_id']);

        // 시간대별로 분배
        DateTime currentHour = DateTime(start.year, start.month, start.day, start.hour);
        DateTime sessionEnd = end;

        while (currentHour.isBefore(sessionEnd)) {
          DateTime nextHour = currentHour.add(Duration(hours: 1));
          DateTime segmentEnd = nextHour.isAfter(sessionEnd) ? sessionEnd : nextHour;
          DateTime segmentStart = currentHour.isBefore(start) ? start : currentHour;
          double totalSegmentMinutes = segmentEnd.difference(segmentStart).inMinutes.toDouble();

          double breakMinutesInSegment = 0;
          for (var breakItem in breaks) {
            if (breakItem['end_time'] != null) {
              final breakStart = DateTime.parse(breakItem['start_time']);
              final breakEnd = DateTime.parse(breakItem['end_time']);

              // 휴식시간이 현재 시간대와 겹치는지 확인
              if (breakStart.isBefore(segmentEnd) && breakEnd.isAfter(segmentStart)) {
                final overlapStart = breakStart.isAfter(segmentStart) ? breakStart : segmentStart;
                final overlapEnd = breakEnd.isBefore(segmentEnd) ? breakEnd : segmentEnd;
                breakMinutesInSegment += overlapEnd.difference(overlapStart).inMinutes.toDouble();
              }
            }
          }

          // 실제 활동시간 = 총 시간 - 휴식시간
          double actualActivityMinutes = totalSegmentMinutes - breakMinutesInSegment;

          if (actualActivityMinutes > 0) {
            if (currentHour.year == selected.year && currentHour.month == selected.month && currentHour.day == selected.day) {
              hourlyData.add({
                'hour': currentHour.hour,
                'activity_name': session['activity_name'],
                'activity_color': session['activity_color'],
                'activity_icon': session['activity_icon'],
                'minutes': actualActivityMinutes,
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
