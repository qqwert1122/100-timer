import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class DateRangePickerBottomSheet extends StatefulWidget {
  final DateTimeRange? initialDateRange;

  const DateRangePickerBottomSheet({
    Key? key,
    this.initialDateRange,
  }) : super(key: key);

  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTimeRange? initialDateRange,
  }) async {
    return await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DateRangePickerBottomSheet(
          initialDateRange: initialDateRange,
        );
      },
    );
  }

  @override
  State<DateRangePickerBottomSheet> createState() => _DateRangePickerBottomSheetState();
}

class _DateRangePickerBottomSheetState extends State<DateRangePickerBottomSheet> {
  late StatsProvider _statsProvider;

  late DateTime? tempRangeStart;
  late DateTime? tempRangeEnd;
  late DateTime focusedDay;

  List<Map<String, dynamic>> _sessionSummaries = [];
  bool _isInitialized = false; // 초기화 여부 추적
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _statsProvider = Provider.of<StatsProvider>(context, listen: false);

    // 초기값 설정
    tempRangeStart = widget.initialDateRange?.start ?? DateTime.now().subtract(const Duration(days: 7));
    tempRangeEnd = widget.initialDateRange?.end ?? DateTime.now();
    focusedDay = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMonthData(focusedDay);
    });
  }

  Future<void> _loadMonthData(DateTime month) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 해당 월의 첫날과 마지막날 계산
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      // 세션 요약 데이터 가져오기
      final data = await _statsProvider.summarizeMonthlySessions(firstDay, lastDay);

      if (!mounted) return;

      setState(() {
        _sessionSummaries = data;
        _isLoading = false;
        _isInitialized = true;
      });
    } catch (e) {
      logger.e('월별 데이터 로딩 오류: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
    }
  }

  Map<String, dynamic> _getSummaryForDate(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // 해당 날짜의 요약 정보 찾기
    for (final summary in _sessionSummaries) {
      if (summary['date'] == dateStr) {
        return summary;
      }
    }

    // 일치하는 항목이 없을 경우 기본값 반환
    return {'date': dateStr, 'activity_count': 0, 'tot_duration': 0};
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString();
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(75),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          _buildTitle(),
          const SizedBox(height: 16),
          _buildCalendar(),
          const SizedBox(height: 16),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: context.wp(20),
      height: context.hp(0.8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.textSecondary(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      '날짜 선택',
      style: AppTextStyles.getTitle(context),
    );
  }

  Widget _buildCalendar() {
    return StatefulBuilder(
      builder: (context, setState) {
        return SizedBox(
          height: context.hp(50),
          child: TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime.now().add(const Duration(days: 1)),
            focusedDay: focusedDay,
            rangeStartDay: tempRangeStart,
            rangeEndDay: tempRangeEnd,
            rangeSelectionMode: RangeSelectionMode.enforced,
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTextStyles.getBody(context).copyWith(
                letterSpacing: -0.3,
                fontWeight: FontWeight.w900,
              ),
            ),
            calendarStyle: CalendarStyle(
              cellMargin: const EdgeInsets.all(10), // 셀 주변 여백 추가
              cellPadding: const EdgeInsets.all(0), // 셀 내부 패딩 줄이기
              rangeHighlightColor: AppColors.primary(context).withValues(alpha: 0.2),
              rangeStartDecoration: BoxDecoration(
                color: AppColors.primary(context),
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: BoxDecoration(
                color: AppColors.primary(context),
                shape: BoxShape.circle,
              ),
              todayDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w900,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary(context),
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selectedDay, focusDay) {
              setState(() {
                focusedDay = focusDay;
              });
            },
            onRangeSelected: (start, end, focusDay) {
              final localStart = start != null
                  ? DateTime(start.year, start.month, start.day) // 이렇게 하면 isUtc가 false인 로컬 시간 객체가 생성됩니다
                  : null;

              final localEnd = end != null ? DateTime(end.year, end.month, end.day) : localStart; // start와 동일하게 설정

              setState(() {
                tempRangeStart = localStart;
                tempRangeEnd = localEnd ?? localStart; // null이면 start와 동일하게 설정
                focusedDay = focusDay;
              });
            },
            onPageChanged: (focusDay) {
              this.setState(() {
                focusedDay = focusDay;
              });
              _loadMonthData(focusDay);
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (!_isInitialized) return null;

                if (_isLoading) {
                  return Positioned(
                    bottom: 1,
                    child: SizedBox(
                      width: 35,
                      height: 15,
                      child: Center(
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final summary = _getSummaryForDate(date);
                final activityCount = summary['activity_count'] ?? 0;
                final totDuration = summary['tot_duration'] ?? 0;

                // 활동이 없으면 마커 표시 안함
                if (activityCount == 0) return null;

                // 활동 요약 정보 표시
                return Positioned(
                  bottom: 1,
                  child: Center(
                    child: Text(
                      _formatTime(totDuration),
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              // 데이터가 없는 날짜는 회색 처리
              defaultBuilder: (context, day, focusedDay) {
                if (!_isInitialized) return null;

                if (_isLoading) {
                  return Center(
                    child: SizedBox(
                      width: 35,
                      height: 15,
                      child: Center(
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final summary = _getSummaryForDate(day);
                final activityCount = summary['activity_count'] ?? 0;

                // 데이터가 없는 날짜는 회색으로 표시
                if (activityCount == 0) {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
            locale: 'ko_KR',
          ),
        );
      },
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _onCancel,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '취소',
              style: AppTextStyles.getBody(context).copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _onConfirm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '확인',
              style: AppTextStyles.getBody(context).copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onCancel() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  void _onConfirm() {
    HapticFeedback.lightImpact();
    if (tempRangeStart != null && tempRangeEnd != null) {
      if (tempRangeStart!.isAfter(tempRangeEnd!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('유효하지 않은 날짜 범위입니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      Navigator.of(context).pop(
        DateTimeRange(
          start: tempRangeStart!,
          end: tempRangeEnd!,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('시작일과 종료일을 모두 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
