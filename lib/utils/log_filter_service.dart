import 'package:flutter/material.dart';
import 'package:project1/models/log_filter_type.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/stats_provider.dart';

class LogFilterService {
  final StatsProvider statsProvider;
  final DatabaseService databaseService;

  LogFilterService(this.statsProvider, this.databaseService);

  Future<List<Map<String, dynamic>>> getLogsForFilter(ActivityLogFilter filter, int weekOffset) async {
    logger.d('필터 적용: ${filter.type}, weekOffset: $weekOffset');

    switch (filter.type) {
      case LogFilterType.all:
        return await statsProvider.getSessionsForWeek(weekOffset);

      case LogFilterType.dateRange:
        return await databaseService.getSessionsWithinDateRange(
          startDate: filter.dateRange!.start.toUtc(),
          endDate: filter.dateRange!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)).toUtc(),
        );

      case LogFilterType.activity:
        return await statsProvider.getFilteredSessionsForWeek(
          activityName: filter.activityName,
          weekOffset: weekOffset,
        );

      case LogFilterType.combined:
        return await databaseService.getSessionsWithinDateRangeAndActivityName(
          startDate: filter.dateRange!.start.toUtc(),
          endDate: filter.dateRange!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)).toUtc(),
          activityName: filter.activityName!,
        );
    }
  }
}
