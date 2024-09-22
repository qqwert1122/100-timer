import 'package:shared_preferences/shared_preferences.dart';

class ActivityService {
  Future<void> saveActivityData({
    required int activityId,
    required int userId,
    required int timerId,
    required String activityName,
    required int activityDuration,
    required bool isModified,
    required int? originalDuration,
    required DateTime timestamp,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setInt('activity_id', activityId);
    prefs.setInt('user_id', userId);
    prefs.setInt('timer_id', timerId);
    prefs.setString('activity_name', activityName);
    prefs.setInt('activity_duration', activityDuration);
    prefs.setBool('is_modified', isModified);
    if (originalDuration != null) {
      prefs.setInt('original_duration', originalDuration);
    }
    prefs.setString('timestamp', timestamp.toIso8601String());
  }

  Future<void> updateActivityData({
    required int activityId,
    required int activityDuration,
    required bool isModified,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setInt('activity_duration', activityDuration);
    prefs.setBool('is_modified', isModified);
  }
}
