class TimelineDragHandler {
  static bool isValidActivityStart(DateTime newStartTime, int newDuration) {
    return newDuration > 0;
  }

  static bool isValidActivityEnd(int newDuration) {
    return newDuration > 0;
  }

  static bool isValidBreakStart(DateTime newStartTime, DateTime sessionStartTime, DateTime breakEndTime) {
    return newStartTime.isAfter(sessionStartTime) && newStartTime.isBefore(breakEndTime);
  }

  static bool isValidBreakEnd(DateTime newEndTime, DateTime breakStartTime, DateTime sessionEndTime) {
    return newEndTime.isAfter(breakStartTime) && newEndTime.isBefore(sessionEndTime);
  }
}
