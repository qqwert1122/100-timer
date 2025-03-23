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

  // 배경색에 따라 적절한 텍스트 색상을 반환하는 함수
  static Color getTextColorForBackground(Color backgroundColor) {
    // 색상의 밝기 계산 (YIQ 공식 사용)
    // YIQ 공식: Y = 0.299*R + 0.587*G + 0.114*B
    // 이 공식은 인간의 눈이 색상을 인식하는 방식에 기반한 공식으로,
    // 녹색에 더 민감하고 파란색에 덜 민감하다는 특성을 반영합니다.

    double yiq = ((backgroundColor.red * 299) + (backgroundColor.green * 587) + (backgroundColor.blue * 114)) / 1000;

    // YIQ 값이 128보다 크면 배경이 밝은 것으로 간주
    // 밝은 배경에는 어두운 텍스트(검정색)
    // 어두운 배경에는 밝은 텍스트(흰색)
    if (yiq >= 128) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }

  // 헥스 문자열 배경색에 따라 적절한 텍스트 색상을 반환하는 함수
  static Color getTextColorForBackgroundHex(String? hexString) {
    // 헥스 문자열을 Color로 변환
    Color backgroundColor = hexToColor(hexString);

    // 위에서 정의한 함수 사용
    return getTextColorForBackground(backgroundColor);
  }
}
