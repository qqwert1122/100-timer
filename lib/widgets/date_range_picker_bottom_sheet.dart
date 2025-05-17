import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';
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
  late DateTime? tempRangeStart;
  late DateTime? tempRangeEnd;
  late DateTime focusedDay;

  @override
  void initState() {
    super.initState();
    // 초기값 설정
    if (widget.initialDateRange != null) {
      tempRangeStart = widget.initialDateRange!.start;
      tempRangeEnd = widget.initialDateRange!.end;
    } else {
      tempRangeStart = DateTime.now().subtract(const Duration(days: 7));
      tempRangeEnd = DateTime.now();
    }
    focusedDay = DateTime.now();
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
          SizedBox(height: context.hp(2)),
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
            selectedDayPredicate: (day) {
              return isSameDay(focusedDay, day);
            },
            onDaySelected: (selectedDay, focusDay) {
              setState(() {
                focusedDay = focusDay;
              });
            },
            onRangeSelected: (start, end, focusDay) {
              setState(() {
                tempRangeStart = start;
                tempRangeEnd = end;
                focusedDay = focusDay;
              });
            },
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
