import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/error_service.dart';

class StatsProvider extends ChangeNotifier {
  DatabaseService _dbService;
  final ErrorService _errorService;

  StatsProvider({
    required DatabaseService dbService,
    required ErrorService errorService,
  })  : _dbService = dbService,
        _errorService = errorService;

  late final Completer<void> _initializedCompleter = Completer();
  Future<void> get initialized => _initializedCompleter.future;

  void initializeWithDB(DatabaseService db) {
    _dbService = db;
    _initializedCompleter.complete();
    notifyListeners();
  }

  /*

    Offset

  */

  int _weekOffset = 0;
  int get weekOffset => _weekOffset;

  void moveToPreviousWeek() {
    _weekOffset -= 1;
    notifyListeners();
  }

  void moveToNextWeek() {
    _weekOffset += 1;
    notifyListeners();
  }

  void resetToCurrentWeek() {
    _weekOffset = 0;
    notifyListeners();
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
      DateTime now = DateTime.now().toLocal();

      DateTime monday =
          DateTime(now.year, now.month, now.day - (now.weekday - 1))
              .add(Duration(days: _weekOffset * 7));
      DateTime nextMonday = monday.add(const Duration(days: 7));

      final results = await _dbService.getSessionsWithinDateRange(
        startDate: monday.toUtc(),
        endDate: nextMonday.toUtc(),
      );
      if (results.isNotEmpty) {
        results.sort((a, b) =>
            (b['total_duration'] as int).compareTo(a['total_duration'] as int));
      }
      return results;
    } catch (e) {
      // error
      return [];
    }
  }

  /*

    Sessions

  */

  Future<List<Map<String, dynamic>>> getSessionsForWeek(int weekOffset) async {
    try {
      // 주 단위 시작일과 종료일 계산
      final weeklyRange = DateUtils.getWeeklyRange(weekOffset: weekOffset);

      // DatabaseService를 호출하여 데이터 가져오기
      final results = await _dbService.getSessionsWithinDateRange(
        startDate: weeklyRange['startOfWeek']!,
        endDate: weeklyRange['endOfWeek']!,
      );

      // 필요한 데이터 가공 또는 정렬
      results.sort((a, b) =>
          (b['total_duration'] as int).compareTo(a['total_duration'] as int));

      return results;
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'FETCH_SESSIONS_FOR_WEEK_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Fetching sessions for weekOffset: $weekOffset',
        severityLevel: 'high',
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklySessionFlags() async {
    try {
      final weeklyRange = DateUtils.getWeeklyRange();

      final results = await _dbService.getSessionsWithinDateRange(
        startDate: weeklyRange['startOfWeek']!,
        endDate: weeklyRange['endOfWeek']!,
      );

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
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'FETCH_WEEKLY_FLAGS_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Fetching weekly session flags',
        severityLevel: 'medium',
      );
      return [];
    }
  }

  Future<int> getTotalDurationForWeek(String weekStart) async {
    try {
      // 주차의 시작일과 종료일 계산
      DateTime weekStartDate = DateTime.parse(weekStart);
      DateTime weekEndDate = weekStartDate.add(const Duration(days: 7));

      // DatabaseService에서 주어진 날짜 범위의 세션 데이터 가져오기
      final sessions = await _dbService.getSessionsWithinDateRange(
        startDate: weekStartDate,
        endDate: weekEndDate,
      );

      // 세션 데이터의 `session_duration` 합계 계산
      final totalDuration = sessions.fold<int>(
        0,
        (sum, session) => sum + (session['total_duration'] as int? ?? 0),
      );

      return totalDuration;
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'SESSION_DURATION_CALCULATION_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Calculating Total Session Duration for Week',
        severityLevel: 'medium',
      );
      return 0;
    }
  }

  Future<int> getSessionsOver1HourCount(String weekStart) async {
    try {
      final weekEnd = DateTime.parse(weekStart).add(const Duration(days: 7));

      // DatabaseService에서 데이터를 가져옴
      final sessions = await _dbService.getSessionsWithinDateRange(
        startDate: DateTime.parse(weekStart),
        endDate: weekEnd,
      );

      // 조건에 맞는 데이터 필터링 (session_duration >= 3600)
      final filteredSessions = sessions.where((session) {
        final duration = session['session_duration'] as int? ?? 0;
        return duration >= 3600;
      }).toList();

      return filteredSessions.length; // 조건에 맞는 세션 수 반환
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'SESSION_OVER_1HOURS_COUNT_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Calculating sessions over 1 hour',
        severityLevel: 'medium',
      );
      return 0;
    }
  }

  Future<int> getCompletedFocusMode(int duration) async {
    try {
      DateTime now = DateTime.now();
      DateTime weekStart =
          now.subtract(Duration(days: now.weekday - 1 + _weekOffset * 7));
      DateTime weekEnd = weekStart.add(const Duration(days: 7));

      final sessions = await _dbService.getSessionsWithinDateRange(
        startDate: weekStart,
        endDate: weekEnd,
      );

      final completedFocusModeCount = sessions.where((session) {
        final targetDuration = session['target_duration'] as int? ?? 0;
        final sessionDuration = session['session_duration'] as int? ?? 0;

        return targetDuration == duration && sessionDuration == targetDuration;
      }).length;

      return completedFocusModeCount;
    } catch (e) {
      Map<String, dynamic> errorData = await _errorService.createError(
        errorCode: 'FETCH_COMPLETED_FOCUS_MODE_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Fetching completed focus mode sessions',
        severityLevel: 'high',
      );
      return 0;
    }
  }

  Future<Map<String, dynamic>> getWeeklyReport() async {
    try {
      // DateUtils를 사용해 주차 범위 계산
      final weekRange = DateUtils.getWeeklyRange(weekOffset: _weekOffset);
      final startOfWeek = weekRange['startOfWeek']!;
      final endOfWeek = weekRange['endOfWeek']!;

      // getSessionsWithinDateRange 호출
      final sessions = await _dbService.getSessionsWithinDateRange(
        startDate: startOfWeek,
        endDate: endOfWeek,
      );

      // 요일별 세션 데이터와 시간별 세션 데이터 집계
      final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
      final Map<String, int> dayTotals = {};
      final Map<String, int> hourTotals = {};

      for (final session in sessions) {
        final startTime = DateTime.parse(session['start_time']);
        final dayName = dayNames[startTime.weekday % 7]; // 요일 이름
        final hour = startTime.hour.toString().padLeft(2, '0'); // 시간 (2자리)

        dayTotals[dayName] =
            (dayTotals[dayName] ?? 0) + (session['session_duration'] as int);
        hourTotals[hour] =
            (hourTotals[hour] ?? 0) + (session['session_duration'] as int);
      }

      // 가장 활동적인 요일과 시간 계산
      final mostActiveDay = dayTotals.entries.isNotEmpty
          ? dayTotals.entries.reduce((a, b) => a.value > b.value ? a : b)
          : null;

      final mostActiveHour = hourTotals.entries.isNotEmpty
          ? hourTotals.entries.reduce((a, b) => a.value > b.value ? a : b)
          : null;

      // 결과 데이터 생성
      return {
        'mostActiveDate': mostActiveDay != null
            ? {
                'dayName': mostActiveDay.key,
                'total_duration': mostActiveDay.value
              }
            : null,
        'mostActiveHour': mostActiveHour != null
            ? {
                'hour': mostActiveHour.key,
                'total_duration': mostActiveHour.value
              }
            : null,
      };
    } catch (e) {
      await _errorService.createError(
        errorCode: 'FETCH_WEEKLY_REPORT_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Fetching weekly report',
        severityLevel: 'high',
      );

      print('Error fetching weekly report: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyLineChart() async {
    try {
      // 주간 범위 가져오기
      final weekRange = DateUtils.getWeeklyRange(weekOffset: _weekOffset);
      final startOfWeek = weekRange['startOfWeek']!;
      final endOfWeek = weekRange['endOfWeek']!;

      // 주간 세션 데이터 가져오기
      final sessions = await _dbService.getSessionsWithinDateRange(
        startDate: startOfWeek,
        endDate: endOfWeek,
      );

      // 요일별, 활동별 데이터 집계
      final Map<String, Map<String, dynamic>> aggregatedData = {};

      for (final session in sessions) {
        final startTime = DateTime.parse(session['start_time']);
        final weekday = startTime.weekday; // 1 (월요일) ~ 7 (일요일)
        final activityName = session['activity_name'];
        final activityColor = session['activity_color'];
        final durationMinutes = (session['session_duration'] as int) / 60.0;

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
      result
          .sort((a, b) => (a['weekday'] as int).compareTo(b['weekday'] as int));

      return result;
    } catch (e) {
      await _errorService.createError(
        errorCode: 'FETCH_WEEKLY_LINE_CHART_FAILED',
        errorMessage: e.toString(),
        errorAction: 'Fetching weekly line chart data',
        severityLevel: 'high',
      );

      print('Error fetching weekly line chart data: $e');
      return [];
    }
  }
}

class DateUtils {
  /// 이번 주의 월요일과 다음 주의 월요일을 반환
  static Map<String, DateTime> getWeeklyRange({int weekOffset = 0}) {
    DateTime nowLocal = DateTime.now();
    DateTime startOfWeek = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day - (nowLocal.weekday - 1) + (7 * weekOffset),
    );
    DateTime endOfWeek = startOfWeek
        .add(const Duration(days: 7))
        .subtract(const Duration(seconds: 1));

    return {
      'startOfWeek': startOfWeek,
      'endOfWeek': endOfWeek,
    };
  }
}
