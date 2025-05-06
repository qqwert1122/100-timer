import 'package:flutter/material.dart';
import '../utils/responsive_size.dart';
import 'dart:io';

class AppTextStyles {
  // 시뮬레이터 감지 함수
  static bool isSimulator() {
    bool result = false;
    if (Platform.isIOS) {
      try {
        // 시뮬레이터에만 존재하는 파일 확인
        File file = File('/Applications/Xcode.app');
        result = file.existsSync();
      } catch (e) {
        result = false;
      }
    }
    return result;
  }

  // 각 플랫폼별 폰트 크기 스케일 반환 함수
  static double getFontSizeScaleFactor() {
    if (Platform.isIOS) {
      if (isSimulator()) {
        return 0.8; // 아이폰 시뮬레이터
      } else {
        return 0.7; // 실제 아이폰
      }
    } else {
      return 1.0; // 안드로이드
    }
  }

  static TextStyle getTimeDisplay(BuildContext context) {
    final fontScale = Platform.isIOS ? 0.8 : 1.0;
    return TextStyle(
      fontSize: context.wp(10) * fontScale,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle getHeadline(BuildContext context) {
    final fontScale = Platform.isIOS ? 0.8 : 1.0;
    return TextStyle(
      fontSize: context.xl * fontScale,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle getTitle(BuildContext context) {
    final fontScale = Platform.isIOS ? 0.8 : 1.0;
    return TextStyle(
      fontSize: context.lg * fontScale,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle getBody(BuildContext context) {
    final fontScale = Platform.isIOS ? 0.8 : 1.0;
    return TextStyle(
      fontSize: context.md * fontScale,
    );
  }

  static TextStyle getCaption(BuildContext context) {
    final fontScale = Platform.isIOS ? 0.8 : 1.0;
    return TextStyle(
      fontSize: context.sm * fontScale,
      color: Colors.grey,
    );
  }
}
