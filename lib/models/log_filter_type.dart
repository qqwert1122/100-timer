// lib/models/log_filter_model.dart 파일 생성
import 'package:flutter/material.dart';

enum LogFilterType {
  all, // 필터 없음, 전체 로그
  dateRange, // 날짜 범위로 필터링
  activity, // 활동 이름으로 필터링
  combined // 날짜 범위와 활동 이름 모두 필터링
}

class ActivityLogFilter {
  final LogFilterType type;
  final String? activityName;
  final DateTimeRange? dateRange;

  ActivityLogFilter({
    required this.type,
    this.activityName,
    this.dateRange,
  });

  factory ActivityLogFilter.all() {
    return ActivityLogFilter(type: LogFilterType.all);
  }

  factory ActivityLogFilter.dateRange(DateTimeRange range) {
    return ActivityLogFilter(
      type: LogFilterType.dateRange,
      dateRange: range,
    );
  }

  factory ActivityLogFilter.activity(String name) {
    return ActivityLogFilter(
      type: LogFilterType.activity,
      activityName: name,
    );
  }

  factory ActivityLogFilter.combined(String name, DateTimeRange range) {
    return ActivityLogFilter(
      type: LogFilterType.combined,
      activityName: name,
      dateRange: range,
    );
  }

  static ActivityLogFilter fromCurrentState(String? activityName, DateTimeRange? dateRange) {
    if (activityName != null && dateRange != null) {
      return ActivityLogFilter.combined(activityName, dateRange);
    } else if (activityName != null) {
      return ActivityLogFilter.activity(activityName);
    } else if (dateRange != null) {
      return ActivityLogFilter.dateRange(dateRange);
    } else {
      return ActivityLogFilter.all();
    }
  }

  bool get isFilterApplied => type != LogFilterType.all;
  bool get isActivityFiltered => activityName != null;
  bool get isDateFiltered => dateRange != null;
}
