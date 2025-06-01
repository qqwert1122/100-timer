class TimelineTimeFormatter {
  static String formatTime(DateTime time, bool use24Hour) {
    if (use24Hour) {
      return '${time.hour.toString().padLeft(2, '0')}시 ${time.minute.toString().padLeft(2, '0')}분';
    } else {
      String period = time.hour < 12 ? '오전' : '오후';
      int displayHour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
      return '$period ${displayHour.toString().padLeft(2, '0')}시 ${time.minute.toString().padLeft(2, '0')}분';
    }
  }

  static String formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  static bool shouldUse24Hour(int totalDuration) {
    return totalDuration >= 3600; // 1시간 이상
  }
}
