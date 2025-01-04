// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    fontFamily: 'NanumHuman',
    brightness: Brightness.light,
    primarySwatch: Colors.red,
    scaffoldBackgroundColor: Colors.white,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0.2,
    ),
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    fontFamily: 'NanumHuman', // 폰트패밀리 추가
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xff181C14),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      shadowColor: Colors.black,
      elevation: 0.2,
    ),
    useMaterial3: true, // Material3 설정 추가
  );
}
