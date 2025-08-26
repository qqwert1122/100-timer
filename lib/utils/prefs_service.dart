import 'package:project1/utils/logger_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static final PrefsService _instance = PrefsService._internal();
  factory PrefsService() => _instance;
  PrefsService._internal();

  late final SharedPreferences _prefs;
  SharedPreferences get prefs => _prefs;

  Future<void> init() async {
    logger.d('[prefsService] SharedPreference init');
    _prefs = await SharedPreferences.getInstance();
    await _ensureDefaultValues();
  }

  Future<void> _ensureDefaultValues() async {
    final now = DateTime.now().toUtc();
    final installDateStr = now.toIso8601String();

    await _prefs.setInt('totalSeconds',
        _prefs.getInt('totalSeconds') ?? 360000); // 100 h = 360 000 sec
    await _prefs.setBool(
        'keepScreenOn', _prefs.getBool('keepScreenOn') ?? false);
    await _prefs.setBool('alarmFlag', _prefs.getBool('alarmFlag') ?? false);
    await _prefs.setBool('hasRequestedNotificationPermission',
        _prefs.getBool('hasRequestedNotificationPermission') ?? false);
    await _prefs.setString(
        'installDate', _prefs.getString('installDate') ?? installDateStr);
    await _prefs.setInt(
        'customDuration', _prefs.getInt('customDuration') ?? 3600);

    const pages = [
      'timer',
      'activityPicker',
      'timerRunning',
      'focusMode',
      'history'
    ];
    for (final p in pages) {
      final k = '${p}Onboarding';
      await _prefs.setBool(k, _prefs.getBool(k) ?? false);
    }
  }

  Future<void> reload() => _prefs.reload();

  int get totalSeconds => _prefs.getInt('totalSeconds')!;
  set totalSeconds(int v) => _prefs.setInt('totalSeconds', v);

  bool get keepScreenOn => _prefs.getBool('keepScreenOn')!;
  set keepScreenOn(bool v) => _prefs.setBool('keepScreenOn', v);

  bool get alarmFlag => _prefs.getBool('alarmFlag')!;
  set alarmFlag(bool v) => _prefs.setBool('alarmFlag', v);

  bool getOnboarding(String page) => _prefs.getBool('${page}Onboarding')!;
  Future<void> setOnboarding(String page, bool value) =>
      _prefs.setBool('${page}Onboarding', value);

  bool get hasRequestedNotificationPermission =>
      _prefs.getBool('hasRequestedNotificationPermission')!;
  set hasRequestedNotificationPermission(bool v) =>
      _prefs.setBool('hasRequestedNotificationPermission', v);

  String get installDate => _prefs.getString('installDate')!;
  set installDate(String date) => _prefs.setString('installDate', date);

  int get customDuration => _prefs.getInt('customDuration')!;
  set customDuration(int v) => _prefs.setInt('customDuration', v);
}
