import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/logger_config.dart';

class TimePickerValidator {
  final Map<String, dynamic> item;
  final Map<String, dynamic>? beforeItem;
  final Map<String, dynamic>? afterItem;
  final DateTime? _cachedMaxDateTime;

  TimePickerValidator({
    required this.item,
    this.beforeItem,
    this.afterItem,
    DateTime? cachedMaxDateTime,
  }) : _cachedMaxDateTime = cachedMaxDateTime;

  bool get isBreakType => item['type'] == 'break';

  /// beforeItem에서 최소 허용 시간을 가져옴
  DateTime? getMinDateTime() {
    if (beforeItem == null || beforeItem!.isEmpty) return null;

    // beforeItem이 break 타입인 경우 end_time 사용, 아니면 time 사용
    String? timeString = beforeItem!['end_time'] ?? beforeItem!['time'];
    if (timeString == null) return null;

    return DateTime.parse(timeString).add(const Duration(minutes: 1)).toLocal();
  }

  /// afterItem에서 최대 허용 시간을 가져옴
  DateTime? getMaxDateTime() {
    if (isBreakType) {
      if (afterItem == null || afterItem!.isEmpty) return null;
      String? timeString = afterItem!['start_time'] ?? afterItem!['time'];
      if (timeString == null) return null;
      return DateTime.parse(timeString).toLocal();
    }

    // 캐시된 값 사용 (DB 조회 없음)
    return _cachedMaxDateTime;
  }

  /// 선택된 시간이 유효한지 검증
  bool isValidDateTime(DateTime selectedTime, bool isEndTime, DateTime Function(bool) getCurrentDateTime) {
    final minTime = getMinDateTime();
    if (minTime != null && selectedTime.isBefore(minTime)) {
      return false;
    }

    final maxTime = getMaxDateTime(); // await 제거
    if (maxTime != null && selectedTime.isAfter(maxTime)) {
      return false;
    }

    // break 제약 확인 (기존 로직)
    if (isBreakType) {
      if (isEndTime) {
        final startTime = getCurrentDateTime(false);
        if (selectedTime.isBefore(startTime) || selectedTime.isAtSameMomentAs(startTime)) {
          return false;
        }
      } else {
        final endTime = getCurrentDateTime(true);
        if (selectedTime.isAfter(endTime) || selectedTime.isAtSameMomentAs(endTime)) {
          return false;
        }
      }
    }

    return true;
  }

  List<DateTime> getValidDates(bool isEndTime) {
    List<DateTime> validDates = [];

    DateTime? minTime = getMinDateTime();
    DateTime? maxTime = getMaxDateTime();

    // 기본 범위 (3일)
    DateTime startDate = DateTime.now().subtract(Duration(days: 1));
    DateTime endDate = DateTime.now().add(Duration(days: 1));

    // beforeItem/afterItem이 있으면 범위 조정
    if (minTime != null) {
      startDate = DateTime(minTime.year, minTime.month, minTime.day);
    }
    if (maxTime != null) {
      endDate = DateTime(maxTime.year, maxTime.month, maxTime.day);
    }

    // 날짜 범위 내의 모든 날짜 추가
    DateTime current = startDate;
    while (current.isBefore(endDate.add(Duration(days: 1)))) {
      validDates.add(DateTime(current.year, current.month, current.day));
      current = current.add(Duration(days: 1));
    }

    return validDates;
  }

  List<int> getValidHoursForDate(DateTime date, bool isEndTime, DateTime Function(bool) getCurrentDateTime) {
    List<int> validHours = [];

    for (int hour = 0; hour < 24; hour++) {
      bool hasValidMinute = false;
      for (int minute = 0; minute < 60; minute++) {
        DateTime testTime = DateTime(date.year, date.month, date.day, hour, minute, 0);
        if (isValidDateTime(testTime, isEndTime, getCurrentDateTime)) {
          hasValidMinute = true;
          break;
        }
      }
      if (hasValidMinute) {
        validHours.add(hour);
      }
    }
    return validHours;
  }

  /// 특정 날짜와 시간에서 유효한 분들 반환
  List<int> getValidMinutesForDateTime(
    DateTime date,
    int hour,
    bool isEndTime,
    DateTime Function(bool) getCurrentDateTime,
  ) {
    List<int> validMinutes = [];

    for (int minute = 0; minute < 60; minute++) {
      DateTime testTime = DateTime(date.year, date.month, date.day, hour, minute, 0);
      if (isValidDateTime(testTime, isEndTime, getCurrentDateTime)) {
        validMinutes.add(minute);
      }
    }

    return validMinutes;
  }

  List<int> getValidHoursIncludingCurrent(
    DateTime date,
    bool isEndTime,
    DateTime Function(bool) getCurrentDateTime,
  ) {
    List<int> validHours = getValidHoursForDate(date, isEndTime, getCurrentDateTime);

    return validHours;
  }

  List<int> getValidMinutesIncludingCurrent(
    DateTime date,
    int hour,
    bool isEndTime,
    DateTime Function(bool) getCurrentDateTime,
  ) {
    List<int> validMinutes = getValidMinutesForDateTime(date, hour, isEndTime, getCurrentDateTime);

    validMinutes.sort();

    return validMinutes;
  }

  List<int> getValidHours(
    bool isEndTime,
    DateTime Function(bool) getCurrentDateTime,
  ) {
    final currentDateTime = getCurrentDateTime(isEndTime);
    final currentDate = DateTime(currentDateTime.year, currentDateTime.month, currentDateTime.day);

    return getValidHoursForDate(currentDate, isEndTime, getCurrentDateTime);
  }

  List<int> getValidMinutes(
    bool isEndTime,
    DateTime Function(bool) getCurrentDateTime,
  ) {
    final currentDateTime = getCurrentDateTime(isEndTime);
    final currentDate = DateTime(currentDateTime.year, currentDateTime.month, currentDateTime.day);

    return getValidMinutesForDateTime(currentDate, currentDateTime.hour, isEndTime, getCurrentDateTime);
  }
}
