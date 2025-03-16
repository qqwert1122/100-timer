import 'package:flutter/material.dart';

class ColorService {
  // HEX 문자열을 Color로 변환하는 함수
  static Color hexToColor(String? hexString) {
    // 입력값 검증
    if (hexString == null || hexString.isEmpty || hexString == 'null') {
      // 기본 색상 반환 (예: 투명색)
      return Colors.grey.shade400;
    }

    // '#' 문자 제거
    hexString = hexString.replaceFirst('#', '');

    // 길이 검증 및 보정
    if (hexString.length == 6) {
      hexString = 'FF$hexString'; // 불투명도 추가
    } else if (hexString.length != 8) {
      // 길이가 6자리나 8자리가 아닌 경우 기본 색상 반환
      return Colors.grey.shade400;
    }

    try {
      // HEX 문자열을 Color 객체로 변환
      return Color(int.parse(hexString, radix: 16));
    } catch (e) {
      // 파싱 실패 시 기본 색상 반환
      return Colors.grey.shade400;
    }
  }
}
