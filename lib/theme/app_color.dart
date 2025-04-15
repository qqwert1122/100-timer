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
    return Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.grey;
  }

  // 배경 색상
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? const Color(0xff181C14) : Colors.white;
  }

  static Color backgroundSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? const Color(0xff2A2F25) : Color(0xffF5F5F5);
  }

  // 텍스트 on 배경 색상 (배경에 쓰이는 텍스트 색상)
  static Color textOnBackgroundSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;
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
