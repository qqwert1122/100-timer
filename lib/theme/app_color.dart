import 'package:flutter/material.dart';

class AppColors {
  // 기본 색상
  static Color primary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.redAccent;
  }

  // 텍스트 색상
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white;
  }

  // 배경 색상
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? const Color(0xff181C14) : Colors.white;
  }

  static Color backgroundSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade100;
  }

  // 버튼 색상
  static Color buttonPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.blue : Colors.red;
  }

  static Color buttonSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey;
  }

  // 버튼 색상
  static Color timerButton(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.redAccent;
  }

  // 아이콘 색상
  static Color icon(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.redAccent;
  }
}
