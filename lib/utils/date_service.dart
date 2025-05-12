// date_service.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateService {
  DateService._();

  static String getWeekStart(DateTime date) {
    int weekday = date.weekday;
    DateTime weekStart = date.subtract(Duration(days: weekday - 1));
    return weekStart.toIso8601String().split('T').first;
  }

  static String getCurrentWeekStart() {
    return getWeekStart(DateTime.now());
  }
}
