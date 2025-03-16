import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/widgets/weekly_activity_chart.dart';

class StatsProvider extends ChangeNotifier {
  DatabaseService _dbService;

  StatsProvider({
    required DatabaseService dbService,
  }) : _dbService = dbService {
    // 초기 데이터 로드
    updateCurrentSessions();
  }

  late final Completer<void> _initializedCompleter = Completer();
  Future<void> get initialized => _initializedCompleter.future;

  void initializeWithDB(DatabaseService db) {
    _dbService = db;
    _initializedCompleter.complete();
    notifyListeners();
  }

  Map<String, DateTime> get weeklyRange => DateUtils.getWeeklyRange(weekOffset: _weekOffset);

  /*

    Offset

  */

  List<Map<String, dynamic>> _currentSessions = [];
  List<Map<String, dynamic>> get currentSessions => _currentSessions;

  int _weekOffset = 0;
  int get weekOffset => _weekOffset;

  Future<void> updateCurrentSessions() async {
    final weeklyRange = DateUtils.getWeeklyRange(weekOffset: _weekOffset);
    final startOfWeek = weeklyRange['startOfWeek']!;
    final endOfWeek = weeklyRange['endOfWeek']!;

    try {
      _currentSessions = await _dbService.getSessionsWithinDateRange(
        startDate: startOfWeek,
        endDate: endOfWeek,
      );
    } catch (e) {
      // 에러 발생 시 빈 리스트로 초기화
      _currentSessions = [];
    }
    notifyListeners();
  }

  Future<void> moveToPreviousWeek() async {
    _weekOffset -= 1;
    await updateCurrentSessions();
  }

  Future<void> moveToNextWeek() async {
    if (_weekOffset < 0) {
      _weekOffset += 1;
      await updateCurrentSessions();
    }
  }

  Future<void> resetToCurrentWeek() async {
    _weekOffset = 0;
    await updateCurrentSessions();
  }

  String getCurrentWeekLabel() {
    final range = DateUtils.getWeeklyRange(weekOffset: _weekOffset);
    final monday = range['startOfWeek']!;

    return DateUtils().formatToMonthWeek(monday);
  }

  /*

    Activity

  */

  Future<List<Map<String, dynamic>>> getActivities() async {
    try {
      final result = await _dbService.getActivities();

      return result;
    } catch (e) {
      // error log
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDefaultActivity() async {
    try {
      final activities = await _dbService.getActivities();
      final defaultActivity = activities.firstWhere(
        (activity) => activity['is_default'] == 1,
        orElse: () => <String, dynamic>{},
      );

      return defaultActivity.isNotEmpty ? defaultActivity : null;
    } catch (e) {
      // error log
      return null;
    }
  }

  Future<Map<String, dynamic>?> getActivityById(String activityId) async {
    try {
      final activities = await _dbService.getActivities();

      final activity = activities.firstWhere(
        (activity) => activity['activity_id'] == activityId,
        orElse: () => <String, dynamic>{},
      );

      return activity.isNotEmpty ? activity : null;
    } catch (e) {
      // error log
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklySessionStatByActivity() async {
    try {
      final results = _currentSessions;

      if (results.isNotEmpty) {
        results.sort((a, b) => (b['total_duration'] as int).compareTo(a['total_duration'] as int));
      }
      return results;
    } catch (e) {
      // error
      return [];
    }
  }

  Future<int> getWeeklyDurationByActivity(String activityId) async {
    try {
      int totalDuration = 0;
      final weeklyRange = DateUtils.getWeeklyRange(weekOffset: 0);
      final startOfWeek = weeklyRange['startOfWeek']!;
      final endOfWeek = weeklyRange['endOfWeek']!;

      final List<Map<String, dynamic>> weeklySessionsByActivityId = await _dbService.getSessionsWithinDateRangeAndActivityId(
        startDate: startOfWeek,
        endDate: endOfWeek,
        activityId: activityId,
      );

      for (var session in weeklySessionsByActivityId) {
        totalDuration += session['duration'] as int;
      }

      return totalDuration;
    } catch (e) {
      // error
      print('Error in getWeeklySessionStatByActivityId: $e');
      return 0; // 오류 발생 시 0 반환
    }
  }
  /*

    Sessions

  */

  Future<List<Map<String, dynamic>>> getSessionsForWeek(int weekOffset) async {
    try {
      // 주 단위 시작일과 종료일 계산 (DateUtils.getWeeklyRange가 로컬 타임을 반환하는 경우)
      final weeklyRange = DateUtils.getWeeklyRange(weekOffset: weekOffset);

      // 데이터베이스에 저장된 start_time이 UTC 기준이라면,
      // 범위를 UTC로 변환해서 비교하는 것이 안전합니다.
      DateTime startUtc = weeklyRange['startOfWeek']!.toUtc();
      DateTime endUtc = weeklyRange['endOfWeek']!.toUtc();

      final results = await _dbService.getSessionsWithinDateRange(
        startDate: startUtc,
        endDate: endUtc,
      );

      return results;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklySessionFlags() async {
    try {
      final results = _currentSessions;

      final sessionFlags = results.map((session) {
        DateTime sessionDate = DateTime.parse(session['start_time']);
        return {
          'start_time': session['start_time'],
          'long_session_flag': session['long_session_flag'],
          'weekday': sessionDate.weekday, // 1 (월) ~ 7 (일)
        };
      }).toList();

      return sessionFlags;
    } catch (e) {
      // error log
      return [];
    }
  }

  Future<int> getTotalDurationForWeek(String weekStart) async {
    try {
      final totalDuration = _currentSessions.fold<int>(
        0,
        (sum, session) => sum + (session['duration'] as int? ?? 0),
      );

      return totalDuration;
    } catch (e) {
      // error log
      return 0;
    }
  }

  Future<int> getSessionsOver1HourCount(String weekStart) async {
    try {
      final filteredSessions = _currentSessions.where((session) {
        final duration = session['duration'] as int? ?? 0;
        return duration >= 3600;
      }).toList();

      return filteredSessions.length; // 조건에 맞는 세션 수 반환
    } catch (e) {
      // error log
      return 0;
    }
  }

  Future<int> getCompletedFocusMode(int duration) async {
    try {
      final completedFocusModeCount = _currentSessions.where((session) {
        final targetDuration = session['target_duration'] as int? ?? 0;
        final sessionDuration = session['duration'] as int? ?? 0;
        return targetDuration == duration && sessionDuration == targetDuration;
      }).length;

      return completedFocusModeCount;
    } catch (e) {
      // error log
      return 0;
    }
  }

  Future<Map<String, dynamic>> getWeeklyReport() async {
    try {
      // 요일별 세션 데이터와 시간별 세션 데이터 집계
      final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
      final Map<String, int> dayTotals = {};
      final Map<String, int> hourTotals = {};

      for (final session in _currentSessions) {
        final startTime = DateTime.parse(session['start_time']);
        final dayName = dayNames[startTime.weekday % 7]; // 요일 이름
        final hour = startTime.hour.toString().padLeft(2, '0'); // 시간 (2자리)

        dayTotals[dayName] = (dayTotals[dayName] ?? 0) + (session['duration'] as int);
        hourTotals[hour] = (hourTotals[hour] ?? 0) + (session['duration'] as int);
      }

      // 가장 활동적인 요일과 시간 계산
      final mostActiveDay = dayTotals.entries.isNotEmpty ? dayTotals.entries.reduce((a, b) => a.value > b.value ? a : b) : null;

      final mostActiveHour = hourTotals.entries.isNotEmpty ? hourTotals.entries.reduce((a, b) => a.value > b.value ? a : b) : null;

      // 결과 데이터 생성
      return {
        'mostActiveDate': mostActiveDay != null ? {'dayName': mostActiveDay.key, 'total_duration': mostActiveDay.value} : null,
        'mostActiveHour': mostActiveHour != null ? {'hour': mostActiveHour.key, 'total_duration': mostActiveHour.value} : null,
      };
    } catch (e) {
      // error log

      print('Error fetching weekly report: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyLineChart() async {
    try {
      final sessions = _currentSessions;

      // 요일별, 활동별 데이터 집계
      final Map<String, Map<String, dynamic>> aggregatedData = {};

      for (final session in sessions) {
        final startTime = DateTime.parse(session['start_time']);
        final weekday = startTime.weekday; // 1 (월요일) ~ 7 (일요일)
        final activityName = session['activity_name'];
        final activityColor = session['activity_color'];
        final durationMinutes = (session['duration'] as int) / 60.0;

        final key = '$activityName-$activityColor-$weekday';

        if (!aggregatedData.containsKey(key)) {
          aggregatedData[key] = {
            'activity_name': activityName,
            'activity_color': activityColor,
            'weekday': weekday,
            'minutes': 0.0,
          };
        }

        aggregatedData[key]!['minutes'] += durationMinutes;
      }

      // 데이터 리스트로 변환
      final result = aggregatedData.values.toList();

      // 요일별 정렬
      result.sort((a, b) => (a['weekday'] as int).compareTo(b['weekday'] as int));

      return result;
    } catch (e) {
      // error log

      print('Error fetching weekly line chart data: $e');
      return [];
    }
  }
}

class DateUtils {
  static Map<String, DateTime> getWeeklyRange({int weekOffset = 0}) {
    DateTime nowLocal = DateTime.now();
    DateTime startOfWeek = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day - (nowLocal.weekday - 1) + (7 * weekOffset), // 7 * weekOffset을 빼줍니다.
    );
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));

    return {
      'startOfWeek': startOfWeek,
      'endOfWeek': endOfWeek,
    };
  }

  String formatToMonthWeek(DateTime date) {
    DateTime firstDayOfMonth = DateTime(date.year, date.month, 1);

    int weekOfMonth = ((date.day + firstDayOfMonth.weekday - 1) / 7).ceil();

    String month = DateFormat.MMMM('ko_KR').format(date);

    return "$month $weekOfMonth주차";
  }
}
