import 'package:project1/models/log_filter_type.dart';

enum PagingMode { byWeek, byCount }

PagingMode getPagingMode(LogFilterType type) {
  switch (type) {
    case LogFilterType.all:
    case LogFilterType.activity:
      return PagingMode.byWeek; // ① 주차(offset) 기반
    case LogFilterType.dateRange:
    case LogFilterType.combined:
      return PagingMode.byCount; // ② 개수(limit) 기반
  }
}
