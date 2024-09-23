import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class TimerService {
  static const String timerIdKey = 'timer_id';
  static const String userIdKey = 'user_id';
  static const String weekStartKey = 'week_start';
  static const String totalHoursKey = 'total_hours';
  static const String remainingHoursKey = 'remaining_hours';
  static const String lastUpdatedAtKey = 'last_updated_at';
  static const String isResetKey = 'is_reset';

  // 1주일 동안의 총 시간: 100시간 (360,000초)
  static const int weeklyTotalTimeInSeconds = 360000;

  // 타이머 데이터 저장
  Future<void> saveTimerData({
    required String timerId,
    required int userId,
    required DateTime weekStart,
    required int totalHours,
    required int remainingHours,
    required DateTime lastUpdatedAt,
    required bool isReset,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(timerIdKey, timerId);
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

  // 현재 주차의 타이머를 생성하거나 로드
  Future<Map<String, dynamic>?> createOrLoadCurrentWeekTimer(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    // 현재 날짜를 기반으로 해당 주차의 시작일(월요일)을 반환
    DateTime getWeekStart(DateTime date) {
      int weekday = date.weekday;
      // 월요일을 기준으로 주 시작일을 계산 (월요일이 1, 일요일이 7)
      DateTime weekStart = date.subtract(Duration(days: weekday - 1));
      return DateTime(weekStart.year, weekStart.month, weekStart.day);
    }

    DateTime now = DateTime.now();
    DateTime weekStart = getWeekStart(now); // 예시 2024-09-23 00:00:00.000

    // 타이머가 이미 존재하는지 확인
    if (prefs.containsKey(weekStartKey)) {
      DateTime savedWeekStart =
          DateTime.parse(prefs.getString(weekStartKey) ?? '');
      if (savedWeekStart == weekStart) {}

      print("기존의 타이머 재사용!");
      // 주차가 동일하면 기존 타이머 사용
      return await loadTimerData();
    } else {
      // 주차별 타이머가 없거나 주차가 변경된 경우 새로 생성
      String timerId = Uuid().v4(); // 미리 타이머 ID 생성
      await saveTimerData(
        timerId: timerId,
        userId: userId,
        weekStart: weekStart,
        totalHours: weeklyTotalTimeInSeconds,
        remainingHours: weeklyTotalTimeInSeconds, // 100시간으로 초기화
        lastUpdatedAt: now,
        isReset: true, // 주차가 변경되었으므로 reset 플래그 설정
      );
      print("새로 생성!");
      // 생성한 데이터를 반환
      return {
        'timer_id': timerId, // 미리 생성한 타이머 ID 사용
        'user_id': userId,
        'week_start': weekStart,
        'total_hours': weeklyTotalTimeInSeconds,
        'remaining_hours': weeklyTotalTimeInSeconds,
        'last_updated_at': now,
        'is_reset': true,
      };
    }
  }
}
