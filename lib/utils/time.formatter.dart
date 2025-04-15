// time_formatter.dart 파일에 추가

import 'package:intl/intl.dart';

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
    print('날짜 변환 오류: $e');
    return '';
  }
}
