import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class TimerService {
  static const String timerIdKey = 'timer_id';
  static const String userIdKey = 'user_id';
  static const String weekStartKey = 'week_start';
  static const String totalHoursKey = 'total_seconds';
  static const String remainingHoursKey = 'remaining_seconds';
  static const String lastUpdatedAtKey = 'last_updated_at';
  static const String isResetKey = 'is_reset';

  // 1주일 동안의 총 시간: 100시간 (360,000초)
  static const int weeklyTotalTimeInSeconds = 360000;

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
      'total_seconds': prefs.getInt(totalHoursKey),
      'remaining_seconds': prefs.getInt(remainingHoursKey),
      'last_updated_at':
          DateTime.parse(prefs.getString(lastUpdatedAtKey) ?? ''),
      'is_reset': prefs.getBool(isResetKey),
    };
  }
}
