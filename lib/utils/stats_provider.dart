import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/logger_config.dart';

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
    logger.d('[statsProvider] statsProvider init');
    _dbService = db;
    _initializedCompleter.complete();
    notifyListeners();
  }

  bool _disposed = false; // dispose 여부를 추적

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
    final startOfWeek = weeklyRange['startOfWeek']!.toUtc();
    final endOfWeek = weeklyRange['endOfWeek']!.toUtc();

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
    final range = DateUtils.getWeeklyRange(weekOffset: 0);
    final monday = range['startOfWeek']!;

    return DateUtils().formatToMonthWeek(monday);
  }

  String getSelectedWeekLabel() {
    final range = DateUtils.getWeeklyRange(weekOffset: _weekOffset);
    final monday = range['startOfWeek']!;

    return DateUtils().formatToMonthWeek(monday);
  }

  /*

    Activity

  */

  Future<Map<String, dynamic>?> getDefaultActivity() async {
    try {
      logger.d('[statsProvider] get DefaultActivity');
      final activities = await _dbService.getActivities();
      final defaultActivity = activities.firstWhere(
        (activity) => activity['is_default'] == 1,
        orElse: () => <String, dynamic>{},
      );

      return defaultActivity.isNotEmpty ? defaultActivity : null;
    } catch (e) {
      logger.e('''
        [statsProvider]
        - 위치 : getDefaultActivity
        - 오류 유형: ${e.runtimeType}
        - 메시지: ${e.toString()}
      ''');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getActivities() async {
    try {
      final result = await _dbService.getActivities();

      final sortedResult = List<Map<String, dynamic>>.from(result);
      sortedResult.sort((a, b) {
        final orderA = a['sort_order'] ?? 0;
        final orderB = b['sort_order'] ?? 0;
        return orderA.compareTo(orderB);
      });

      return sortedResult;
    } catch (e) {
      // 에러 로깅 처리
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteActivities() async {
    try {
      // 모든 활동을 가져온 다음 즐겨찾기 필드로 필터링
      final allActivities = await _dbService.getActivities();

      final favoriteActivities = allActivities.where((activity) => activity['is_favorite'] == 1).toList();

      // favorite_order 필드를 기준으로 오름차순 정렬
      favoriteActivities.sort((a, b) {
        final orderA = a['favorite_order'] ?? 0;
        final orderB = b['favorite_order'] ?? 0;
        return orderA.compareTo(orderB);
      });

      return favoriteActivities;
    } catch (e) {
      // 에러 로깅 처리
      return [];
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
      final weeklyRange = DateUtils.getWeeklyRange(weekOffset: 0);
      final startOfWeek = weeklyRange['startOfWeek']!;
      final endOfWeek = weeklyRange['endOfWeek']!;

      final List<Map<String, dynamic>> weeklySessionsByActivityId = await _dbService.getSessionsWithinDateRangeAndActivityId(
        startDate: startOfWeek,
        endDate: endOfWeek,
        activityId: activityId,
      );

      // 해당 활동의 휴식시간 제외한 실제 활동시간 계산
      return await _getActualActivityDuration(weeklySessionsByActivityId);
    } catch (e) {
      logger.e('Error in getWeeklyDurationByActivity: $e');
      return 0;
    }
  }

  /*

    Sessions

  */

  Future<int> getTotalDurationForDate(DateTime date) async {
    try {
      final startOfDayLocal = DateTime(date.year, date.month, date.day);
      final endOfDayLocal = startOfDayLocal.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

      final startUtc = startOfDayLocal.toUtc();
      final endUtc = endOfDayLocal.toUtc();

      final sessions = await _dbService.getSessionsWithinDateRange(
        startDate: startUtc,
        endDate: endUtc,
      );

      // 휴식시간 제외한 실제 활동시간 계산
      return await _getActualActivityDuration(sessions);
    } catch (e) {
      logger.e('Error in getTotalDurationForDate: $e');
      return 0;
    }
  }

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

  Future<List<Map<String, dynamic>>> getFilteredSessionsForWeek({
    String? activityName,
    DateTimeRange? dateRange,
    int weekOffset = 0,
  }) async {
    try {
      // 필터가 적용되지 않은 경우 일반 주차 데이터 반환
      if (activityName == null && dateRange == null) {
        logger.d('필터 없음: 지정된 주차($weekOffset) 데이터 반환');
        return await getSessionsForWeek(weekOffset);
      }

      // 날짜 범위 계산
      DateTime? startDate;
      DateTime? endDate;
      logger.d('dateRange: $dateRange');
      if (dateRange != null) {
        // 사용자가 지정한 날짜 범위 사용

        logger.d('사용자가 지정한 날짜 범위 사용');
        startDate = dateRange.start;
        endDate = dateRange.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
      } else {
        // 주차 기반 날짜 범위 계산

        logger.d('주차 기반 날짜 범위 계산');
        final weeklyRange = DateUtils.getWeeklyRange(weekOffset: weekOffset);
        startDate = weeklyRange['startOfWeek'];
        endDate = weeklyRange['endOfWeek'];
      }

      // null 체크 추가
      if (startDate == null || endDate == null) {
        logger.e('날짜 범위가 null입니다. 현재 주차 사용');
        final weeklyRange = DateUtils.getWeeklyRange(weekOffset: weekOffset);
        startDate = weeklyRange['startOfWeek']!;
        endDate = weeklyRange['endOfWeek']!;
      }

      // 필터링된 세션 데이터 가져오기
      List<Map<String, dynamic>> results = [];

      if (activityName != null && activityName.isNotEmpty) {
        logger.d('활동명($activityName)과 날짜 범위로 필터링');
        results = await _dbService.getSessionsWithinDateRangeAndActivityName(
          startDate: startDate.toUtc(),
          endDate: endDate.toUtc(),
          activityName: activityName,
        );
      } else {
        logger.d('날짜 범위만으로 필터링');
        results = await _dbService.getSessionsWithinDateRange(
          startDate: startDate.toUtc(),
          endDate: endDate.toUtc(),
        );
      }

      logger.d('필터링 결과: ${results.length}개 항목');
      return results;
    } catch (e) {
      logger.e('getFilteredSessionsForWeek 오류: $e');
      // 오류 복구 로직
      try {
        logger.d('오류 복구: 주차 $weekOffset 데이터 반환 시도');
        return await getSessionsForWeek(weekOffset);
      } catch (recoverError) {
        logger.e('복구 시도 중 추가 오류: $recoverError');
        return [];
      }
    }
  }

  Future<List<Map<String, dynamic>>> summarizeMonthlySessions(DateTime startDate, DateTime endDate) async {
    Map<String, Set<dynamic>> activitySetMap = {}; // 월별 고유 활동 모음
    Map<String, int> durationMap = {}; // 월별 총 duration

    final sessions = await _dbService.getSessionsWithinDateRange(startDate: startDate, endDate: endDate);
    for (final session in sessions) {
      final startTime = DateTime.parse(session['start_time']).toLocal();
      final dayKey = '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';

      final activityId = session['activity_id'];
      final duration = (session['duration'] ?? 0) as int;

      // 고유 활동 ID 집계
      activitySetMap.putIfAbsent(dayKey, () => <dynamic>{});
      if (activityId != null) {
        activitySetMap[dayKey]!.add(activityId);
      }

      // duration 누적
      durationMap[dayKey] = (durationMap[dayKey] ?? 0) + duration;
    }

    // 날짜 순 정렬
    final sortedKeys = activitySetMap.keys.toList()..sort();
    return sortedKeys.map((day) {
      return {
        'date': day,
        'activity_count': activitySetMap[day]!.length,
        'tot_duration': durationMap[day] ?? 0,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getWeeklyStreak() async {
    try {
      final results = _currentSessions;

      final sessionFlags = results.map((session) {
        DateTime sessionDate = DateTime.parse(session['start_time']);
        return {
          'start_time': session['start_time'],
          'duration': session['duration'],
          'weekday': sessionDate.weekday,
        };
      }).toList();

      return sessionFlags;
    } catch (e) {
      // error log
      return [];
    }
  }

  Future<int> getTotalDurationForWeek() async {
    try {
      // 휴식시간 제외한 실제 활동시간 계산
      return await _getActualActivityDuration(_currentSessions);
    } catch (e) {
      return 0;
    }
  }

  Future<int> getTotalDurationForCurrentWeek() async {
    try {
      logger.d('[statsProvider] get Total Duration For Current Week');

      final weeklyRange = DateUtils.getWeeklyRange(weekOffset: 0);
      DateTime startUtc = weeklyRange['startOfWeek']!.toUtc();
      DateTime endUtc = weeklyRange['endOfWeek']!.toUtc();

      final sessions = await _dbService.getSessionsWithinDateRange(
        startDate: startUtc,
        endDate: endUtc,
      );

      // 휴식시간 제외한 실제 활동시간 계산
      return await _getActualActivityDuration(sessions);
    } catch (e) {
      logger.e('Error in getTotalDurationForCurrentWeek: $e');
      return 0;
    }
  }

  Future<int> getTotalSecondsForWeek() async {
    try {
      final weeklyRange = DateUtils.getWeeklyRange(weekOffset: _weekOffset);
      String weekStart = weeklyRange['startOfWeek']!.toIso8601String().split('T').first;
      final timerData = await _dbService.getTimer(weekStart);
      return timerData!['total_seconds'];
    } catch (e) {
      return 360000;
    }
  }

  Future<int> getTotalSecondsForCurrnetWeek() async {
    try {
      final weeklyRange = DateUtils.getWeeklyRange(weekOffset: 0);
      String weekStart = weeklyRange['startOfWeek']!.toIso8601String().split('T').first;
      final timerData = await _dbService.getTimer(weekStart);
      return timerData!['total_seconds'];
    } catch (e) {
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
      final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
      final Map<String, int> dayTotals = {};
      final Map<String, int> hourTotals = {};

      for (final session in _currentSessions) {
        final startTime = DateTime.parse(session['start_time']);
        final dayName = dayNames[startTime.weekday % 7];
        final hour = startTime.hour.toString().padLeft(2, '0');

        // 휴식시간 제외한 실제 활동시간 계산
        int actualDuration = await _getActualActivityDuration([session]);

        dayTotals[dayName] = (dayTotals[dayName] ?? 0) + actualDuration;
        hourTotals[hour] = (hourTotals[hour] ?? 0) + actualDuration;
      }

      final mostActiveDay = dayTotals.entries.isNotEmpty ? dayTotals.entries.reduce((a, b) => a.value > b.value ? a : b) : null;
      final mostActiveHour = hourTotals.entries.isNotEmpty ? hourTotals.entries.reduce((a, b) => a.value > b.value ? a : b) : null;

      return {
        'mostActiveDate': mostActiveDay != null ? {'dayName': mostActiveDay.key, 'total_duration': mostActiveDay.value} : null,
        'mostActiveHour': mostActiveHour != null ? {'hour': mostActiveHour.key, 'total_duration': mostActiveHour.value} : null,
      };
    } catch (e) {
      logger.e('Error fetching weekly report: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivityChart() async {
    try {
      final sessions = _currentSessions;
      final Map<String, Map<String, dynamic>> aggregatedData = {};

      for (final session in sessions) {
        final startTime = DateTime.parse(session['start_time']).toLocal();
        final weekday = startTime.weekday;
        final activityName = session['activity_name'];
        final activityColor = session['activity_color'];
        final activityIcon = session['activity_icon'];

        // 휴식시간 제외한 실제 활동시간 계산
        final sessionDuration = await _getActualActivityDuration([session]);
        final durationMinutes = sessionDuration / 60.0;

        final key = '$activityName-$activityColor-$weekday';

        if (!aggregatedData.containsKey(key)) {
          aggregatedData[key] = {
            'activity_name': activityName,
            'activity_color': activityColor,
            'activity_icon': activityIcon,
            'weekday': weekday,
            'minutes': 0.0,
          };
        }

        aggregatedData[key]!['minutes'] += durationMinutes;
      }

      final result = aggregatedData.values.toList();
      result.sort((a, b) => (a['weekday'] as int).compareTo(b['weekday'] as int));

      return result;
    } catch (e) {
      logger.e('Error fetching weekly line chart data: $e');
      return [];
    }
  }

  // 활동 데이터를 저장할 맵
  Map<DateTime, int> _heatMapDataSet = {};

  // heatMapDataSet의 getter
  Map<DateTime, int> get heatMapDataSet => _heatMapDataSet;
  Future<void> initializeHeatMapData({int? year, int? month}) async {
    try {
      DateTime now = DateTime.now();
      int selectedYear = year ?? now.year;
      int selectedMonth = month ?? now.month;

      DateTime monthStart = DateTime(selectedYear, selectedMonth, 1);
      DateTime monthEnd;
      if (selectedMonth == 12) {
        monthEnd = DateTime(selectedYear + 1, 1, 1);
      } else {
        monthEnd = DateTime(selectedYear, selectedMonth + 1, 1);
      }

      List<Map<String, dynamic>> logs = await _dbService.getSessionsWithinDateRange(
        startDate: monthStart,
        endDate: monthEnd,
      );
      _heatMapDataSet = {};

      for (var log in logs) {
        try {
          String? startTimeString = log['start_time'];
          if (startTimeString != null && startTimeString.isNotEmpty) {
            DateTime date = DateTime.parse(startTimeString).toLocal();
            DateTime dateOnly = DateTime(date.year, date.month, date.day);

            // 휴식시간 제외한 실제 활동시간 계산
            int actualDuration = await _getActualActivityDuration([log]);
            int effectiveDuration = max(0, actualDuration);

            _heatMapDataSet.update(
              dateOnly,
              (existing) => existing + effectiveDuration,
              ifAbsent: () => effectiveDuration,
            );
          }
        } catch (e) {}
      }

      notifyListeners();
    } catch (e) {}
  }

  // 주간 진행률 데이터 관리를 위한 속성 추가
  int _totalDuration = 0;
  int get totalDuration => _totalDuration;

  int _totalSeconds = 1;
  int get totalSeconds => _totalSeconds;

  List<int> _dailyDurations = List.filled(7, 0);
  List<double> _dailyPercents = List.filled(7, 0.0);

  List<int> get dailyDurations => _dailyDurations;
  List<double> get dailyPercents => _dailyPercents;

  Future<void> getWeeklyProgressCircle() async {
    try {
      int duration = await getTotalDurationForCurrentWeek();
      int total = await getTotalSecondsForCurrnetWeek();

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

      List<int> dailyDurations = [];
      for (var date in weekDays) {
        final d = await getTotalDurationForDate(date);
        dailyDurations.add(d);
      }

      int remaining = total;
      List<double> percents = [];
      for (int i = 0; i < 7; i++) {
        final daysLeft = 7 - i;
        final target = remaining / daysLeft; // 남은 일수로 균등 분배
        final actual = dailyDurations[i].toDouble();
        final pct = (actual / (target > 0 ? target : 1)).clamp(0.0, 1.0);
        percents.add(pct);
        remaining -= actual.toInt(); // 다음 요일 목표 계산을 위해 차감
      }

      _totalDuration = duration;
      _totalSeconds = total != 0 ? total : 1; // 0이면 퍼센트 계산 에러 방지
      _dailyDurations = dailyDurations;
      _dailyPercents = percents;

      notifyListeners(); // 상태가 변경되었음을 알림
      logger.d('[statsProvider] Weekly stats loaded successfully');
    } catch (e) {
      logger.e('''
        [statsProvider]
        - 위치: loadWeeklyStats
        - 오류 유형: ${e.runtimeType}
        - 메시지: ${e.toString()}
      ''');
    }
  }

  // timerProvider의 updateTotalSeconds 메서드에서 호출할 메서드
  Future<void> refreshWeeklyStats() async {
    await getWeeklyProgressCircle();
  }

  final Map<String, double> _weeklyActivityData = {
    '월': 0.0,
    '화': 0.0,
    '수': 0.0,
    '목': 0.0,
    '금': 0.0,
    '토': 0.0,
    '일': 0.0,
  };

  Future<List<Map<String, dynamic>>> get activityLogs async {
    try {
      DateTime now = DateTime.now();
      // _statsProvider.weekOffset을 사용하여 원하는 주(예: -1: 지난 주, 0: 이번 주, 1: 다음 주)를 계산
      int offset = weekOffset;
      DateTime weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1)).add(Duration(days: offset * 7));
      DateTime weekEnd = weekStart.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));

      // 해당 주 범위의 활동 로그를 DB에서 가져오기
      List<Map<String, dynamic>> allLogs = await _dbService.getSessionsWithinDateRange(
        startDate: weekStart,
        endDate: weekEnd,
      );

      // 주간 활동 로그만 필터링
      List<Map<String, dynamic>> weeklyLogs = allLogs.where((log) {
        try {
          String? startTimeString = log['start_time'];
          if (startTimeString != null && startTimeString.isNotEmpty) {
            DateTime startTime = DateTime.parse(startTimeString).toLocal();
            return !startTime.isBefore(weekStart) && startTime.isBefore(weekEnd);
          }
        } catch (e) {
          // 에러 발생 시 해당 로그는 제외
        }
        return false;
      }).toList();

      return weeklyLogs;
    } catch (e) {
      // 에러 발생 시 빈 리스트 반환
      return [];
    }
  }

  List<Map<String, dynamic>> get weeklyActivityData {
    return _weeklyActivityData.entries.map((entry) {
      int hours = entry.value ~/ 60;
      int minutes = (entry.value % 60).toInt(); // double을 int로 변환
      return {'day': entry.key, 'hours': hours, 'minutes': minutes};
    }).toList();
  }

  // 주간 활동 데이터 초기화 메서드
  void initializeWeeklyActivityData() async {
    try {
      List<Map<String, dynamic>> logs = await activityLogs;
      _weeklyActivityData.updateAll((key, value) => 0.0);

      for (var log in logs) {
        try {
          if (log['start_time'] == null || log['start_time'] is! String) {
            throw Exception('Invalid or missing start_time in log: $log');
          }

          String startTimeString = log['start_time'];
          if (startTimeString.isNotEmpty) {
            DateTime startTime = DateTime.parse(startTimeString).toLocal();
            String dayOfWeek = DateFormat.E('ko_KR').format(startTime);

            // 휴식시간 제외한 실제 활동시간 계산
            int actualDuration = await _getActualActivityDuration([log]);
            double actualDurationMinutes = actualDuration / 60.0;

            _weeklyActivityData[dayOfWeek] = (_weeklyActivityData[dayOfWeek] ?? 0) + actualDurationMinutes;
          }
        } catch (e) {
          continue;
        }
      }

      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<int> _getActualActivityDuration(List<Map<String, dynamic>> sessions) async {
    int totalActivityDuration = 0;

    for (var session in sessions) {
      if (session['end_time'] != null) {
        // 세션 전체 시간
        final start = DateTime.parse(session['start_time']);
        final end = DateTime.parse(session['end_time']);
        int sessionTotalDuration = end.difference(start).inSeconds;

        // 해당 세션의 휴식시간 조회
        final breaks = await _dbService.getBreaks(sessionId: session['session_id']);
        int totalBreakDuration = 0;

        for (var breakItem in breaks) {
          if (breakItem['end_time'] != null) {
            final breakStart = DateTime.parse(breakItem['start_time']);
            final breakEnd = DateTime.parse(breakItem['end_time']);
            totalBreakDuration += breakEnd.difference(breakStart).inSeconds;
          }
        }

        // 실제 활동시간 = 세션시간 - 휴식시간
        totalActivityDuration += (sessionTotalDuration - totalBreakDuration);
      }
    }

    return totalActivityDuration;
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
