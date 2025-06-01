import 'package:intl/intl.dart';
import 'package:project1/utils/logger_config.dart';

/// ISO 8601 형식의 날짜 문자열을 "n분 전", "n시간 전", "n일 전", "n개월 전" 형식으로 변환합니다.
String getTimeAgo(String? isoDateString) {
  if (isoDateString == null || isoDateString.isEmpty) {
    return '';
  }

  try {
    // ISO 8601 문자열을 DateTime 객체로 변환
    final dateTime = DateTime.parse(isoDateString);
    final now = DateTime.now().toUtc(); // UTC 시간으로 통일
    final difference = now.difference(dateTime);

    // 1분 미만
    if (difference.inMinutes < 1) {
      return '방금 전';
    }
    // 1시간 미만
    else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    }
    // 1일 미만
    else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    }
    // 30일 미만
    else if (difference.inDays < 30) {
      return '${difference.inDays}일 전';
    }
    // 365일 미만
    else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}개월 전';
    }
    // 1년 이상
    else {
      return '${(difference.inDays / 365).floor()}년 전';
    }
  } catch (e) {
    logger.e('날짜 변환 오류: $e');
    return '';
  }
}

String formatDate(String dateTimeString) {
  final dateTime = DateTime.parse(dateTimeString).toLocal();
  final now = DateTime.now();
  final isSameYear = dateTime.year == now.year;
  final timeFormatter = DateFormat('a h시 mm분');
  final dateFormatter = isSameYear ? DateFormat('M월 d일') : DateFormat('yyyy년 M월 d일');
  String formattedTime = timeFormatter.format(dateTime).replaceAll('AM', '오전').replaceAll('PM', '오후');

  final result = '${dateFormatter.format(dateTime)} $formattedTime';

  return result;
}

String formatDateOnly(String dateTimeString) {
  final dateTime = DateTime.parse(dateTimeString).toLocal();
  final now = DateTime.now();
  final isSameYear = dateTime.year == now.year;
  final dateFormatter = isSameYear ? DateFormat('M월 d일') : DateFormat('yyyy년 M월 d일');

  return dateFormatter.format(dateTime);
}

String formatTimeOnly(String dateTimeString) {
  final dateTime = DateTime.parse(dateTimeString).toLocal();
  final timeFormatter = DateFormat('a h시 mm분');
  String formattedTime = timeFormatter.format(dateTime).replaceAll('AM', '오전').replaceAll('PM', '오후');

  return formattedTime;
}

String formatTime(int? seconds) {
  if (seconds == null || seconds == 0) return '-';
  final int hours = seconds ~/ 3600;
  final int minutes = (seconds % 3600) ~/ 60;
  final int remainingSeconds = seconds % 60;
  String formattedTime = '';
  if (hours > 0) formattedTime += '$hours시간';
  if (minutes > 0) formattedTime += ' $minutes분';
  if (remainingSeconds > 0) formattedTime += ' $remainingSeconds초';
  return formattedTime.trim();
}
