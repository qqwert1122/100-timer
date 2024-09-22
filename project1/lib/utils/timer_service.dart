import 'package:shared_preferences/shared_preferences.dart';

class TimerService {
  static const String timerIdKey = 'timer_id';
  static const String userIdKey = 'user_id';
  static const String weekStartKey = 'week_start';
  static const String totalHoursKey = 'total_hours';
  static const String remainingHoursKey = 'remaining_hours';
  static const String lastUpdatedAtKey = 'last_updated_at';
  static const String isResetKey = 'is_reset';

  // 1주일 동안의 총 시간: 100시간
  static const int weeklyTotalTimeInSeconds = 360000;

  // 타이머 데이터 저장
  Future<void> saveTimerData({
    required int timerId,
    required int userId,
    required DateTime weekStart,
    required int totalHours,
    required int remainingHours,
    required DateTime lastUpdatedAt,
    required bool isReset,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(timerIdKey, timerId);
    await prefs.setInt(userIdKey, userId);
    await prefs.setString(weekStartKey, weekStart.toIso8601String());
    await prefs.setInt(totalHoursKey, totalHours);
    await prefs.setInt(remainingHoursKey, remainingHours);
    await prefs.setString(lastUpdatedAtKey, lastUpdatedAt.toIso8601String());
    await prefs.setBool(isResetKey, isReset);
  }

  // 타이머 데이터 불러오기
  Future<Map<String, dynamic>?> loadTimerData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(timerIdKey)) {
      return null; // 데이터가 없으면 null 반환
    }
    return {
      'timer_id': prefs.getInt(timerIdKey),
      'user_id': prefs.getInt(userIdKey),
      'week_start': DateTime.parse(prefs.getString(weekStartKey) ?? ''),
      'total_hours': prefs.getInt(totalHoursKey),
      'remaining_hours': prefs.getInt(remainingHoursKey),
      'last_updated_at':
          DateTime.parse(prefs.getString(lastUpdatedAtKey) ?? ''),
      'is_reset': prefs.getBool(isResetKey),
    };
  }

  // 타이머 데이터 초기화
  Future<void> resetTimerData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(timerIdKey);
    await prefs.remove(userIdKey);
    await prefs.remove(weekStartKey);
    await prefs.remove(totalHoursKey);
    await prefs.remove(remainingHoursKey);
    await prefs.remove(lastUpdatedAtKey);
    await prefs.remove(isResetKey);
  }

  // 현재 주차의 타이머를 생성하거나 로드
  Future<void> createOrLoadCurrentWeekTimer(int userId) async {
    final prefs = await SharedPreferences.getInstance();

    DateTime now = DateTime.now();
    DateTime weekStart = _getWeekStart(now);

    // 타이머가 이미 존재하는지 확인
    if (prefs.containsKey(weekStartKey)) {
      DateTime savedWeekStart =
          DateTime.parse(prefs.getString(weekStartKey) ?? '');
      // 주차가 동일하면 기존 타이머 사용
      if (savedWeekStart == weekStart) {
        return; // 이미 주차별 타이머가 존재하면 새로 생성하지 않음
      }
    }

    // 주차별 타이머가 없거나 주차가 변경된 경우 새로 생성
    await saveTimerData(
      timerId: DateTime.now().millisecondsSinceEpoch,
      userId: userId,
      weekStart: weekStart,
      totalHours: weeklyTotalTimeInSeconds,
      remainingHours: weeklyTotalTimeInSeconds, // 100시간으로 초기화
      lastUpdatedAt: now,
      isReset: false,
    );
  }

  // 현재 날짜를 기반으로 해당 주차의 시작일(월요일)을 반환
  DateTime _getWeekStart(DateTime date) {
    int weekday = date.weekday;
    // 월요일을 기준으로 주 시작일을 계산 (월요일이 1, 일요일이 7)
    DateTime weekStart = date.subtract(Duration(days: weekday - 1));
    return DateTime(weekStart.year, weekStart.month, weekStart.day);
  }
}
