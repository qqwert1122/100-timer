import 'package:flutter/material.dart';
import 'package:project1/utils/prefs_service.dart';

class AppTextStyles {
  // 기본 폰트 크기 (고정값)
  static const double _timeDisplayBase = 40.0;
  static const double _headlineBase = 24.0;
  static const double _titleBase = 18.0;
  static const double _bodyBase = 16.0;
  static const double _captionBase = 14.0;

  // PrefsService 인스턴스 가져오기
  static double get _scaleFactor => PrefsService().textScaleFactor;

  static TextStyle getTimeDisplay(BuildContext context) {
    return TextStyle(
      fontSize: _timeDisplayBase * _scaleFactor,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle getHeadline(BuildContext context) {
    return TextStyle(
      fontSize: _headlineBase * _scaleFactor,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle getTitle(BuildContext context) {
    return TextStyle(
      fontSize: _titleBase * _scaleFactor,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle getBody(BuildContext context) {
    return TextStyle(
      fontSize: _bodyBase * _scaleFactor,
    );
  }

  static TextStyle getCaption(BuildContext context) {
    return TextStyle(
      fontSize: _captionBase * _scaleFactor,
      color: Colors.grey,
    );
  }
}
