import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/activity_logs/utils/time_picker_validator.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/time_formatter.dart';
import 'package:provider/provider.dart';

class TimePickerModal extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic>? beforeItem;
  final Map<String, dynamic>? afterItem;
  final Function(
    DateTime endDateTime,
    int endHours,
    int endMinutes, [
    DateTime? startDateTime,
    int? startHours,
    int? startMinutes,
  ]) onTimeSelected;

  const TimePickerModal({
    super.key,
    required this.item,
    required this.beforeItem,
    required this.afterItem,
    required this.onTimeSelected,
  });

  @override
  State<TimePickerModal> createState() => _TimePickerModalState();
}

class _TimePickerModalState extends State<TimePickerModal> {
  late DatabaseService _dbService;

  String title = '활동 종료';
  String type = 'activity_end';

  late DateTime selectedStartDate;
  late DateTime selectedEndDate;

  // 시작 시간 (break, activity_end 둘다)
  int? startHours;
  int? startMinutes;
  int? startSeconds;

  // 종료 시간 (break만)
  late int endHours;
  late int endMinutes;
  late int endSeconds;

  // controller
  bool _isInitialized = false; // 초기화 상태 추가
  late FixedExtentScrollController _startDateController;
  late FixedExtentScrollController _startHoursController;
  late FixedExtentScrollController _startMinutesController;
  late FixedExtentScrollController _endDateController;
  late FixedExtentScrollController _endHoursController;
  late FixedExtentScrollController _endMinutesController;

  // validator
  late TimePickerValidator _validator;

  bool get isBreakType => widget.item['type'] == 'break';

  Future<bool> get _canConfirm async {
    bool endTimeValid = await _isCurrentTimeValid(true);
    bool startTimeValid = !isBreakType || await _isCurrentTimeValid(false);

    return endTimeValid && startTimeValid;
  }

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false);

    _initializeItem();
    _initializeAsync();
  }

  void _initializeItem() {
    title = widget.item['title'] ?? '';
    type = widget.item['type'] ?? '';

    if (isBreakType) {
      final _startDate = DateTime.parse(widget.item['start_time']).toLocal();
      selectedStartDate =
          DateTime(_startDate.year, _startDate.month, _startDate.day);
      startHours = _startDate.hour;
      startMinutes = _startDate.minute;
      startSeconds = _startDate.second;
      if (widget.item['end_time'] != null) {
        final _endDate = DateTime.parse(widget.item['end_time']).toLocal();
        selectedEndDate = DateTime(_endDate.year, _endDate.month, _endDate.day);
        endHours = _endDate.hour;
        endMinutes = _endDate.minute;
        endSeconds = _endDate.second;
      } else {
        // 진행중인 휴식: 시작시간 + 1시간을 기본값으로
        final defaultEnd = _startDate.add(Duration(hours: 1));
        selectedEndDate =
            DateTime(defaultEnd.year, defaultEnd.month, defaultEnd.day);
        endHours = defaultEnd.hour;
        endMinutes = defaultEnd.minute;
        endSeconds = 0;
      }
    } else if (type == 'activity_start') {
      final startDate = DateTime.parse(widget.item['time']).toLocal();
      selectedEndDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      endHours = startDate.hour;
      endMinutes = startDate.minute;
    } else {
      if (widget.item['time'] != null) {
        final timeDate = DateTime.parse(widget.item['time']).toLocal();
        selectedEndDate = DateTime(timeDate.year, timeDate.month, timeDate.day);
        endHours = timeDate.hour;
        endMinutes = timeDate.minute;
      } else {
        final now = DateTime.now();
        selectedEndDate = DateTime(now.year, now.month, now.day);
        endHours = now.hour;
        endMinutes = now.minute;
      }
    }
  }

  Future<void> _initializeAsync() async {
    DateTime? cachedMaxDateTime;
    DateTime? cachedMinDateTime;

    if (!isBreakType) {
      String? sessionId = widget.item['session_id'];
      if (sessionId != null) {
        if (widget.item['type'] == 'activity_end') {
          final nextSession = await _dbService.getNextSession(sessionId);
          cachedMaxDateTime = nextSession != null
              ? DateTime.parse(nextSession['start_time']).toLocal()
              : DateTime.now().add(const Duration(days: 2));
        }
        // activity_start인 경우 추가
        else if (widget.item['type'] == 'activity_start') {
          final previousSession =
              await _dbService.getPreviousSession(sessionId);
          cachedMinDateTime = previousSession != null
              ? DateTime.parse(previousSession['end_time']).toLocal()
              : null;
        }
      }
    }

    _validator = TimePickerValidator(
      item: widget.item,
      beforeItem: widget.beforeItem,
      afterItem: widget.afterItem,
      cachedMaxDateTime: cachedMaxDateTime,
      cachedMinDateTime: cachedMinDateTime,
    );

    // 이제 빠르게 초기화
    await _initializeControllersSafe();
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _initializeControllersSafe() async {
    if (isBreakType) {
      // 시작 시간 컨트롤러들
      List<DateTime> validStartDates = await _validator.getValidDates(false);
      List<int> validStartHours = await _getValidHours(false);
      List<int> validStartMinutes = await _getValidMinutes(false);

      _startDateController = FixedExtentScrollController(
          initialItem: _getSafeDateIndex(validStartDates, selectedStartDate));
      _startHoursController = FixedExtentScrollController(
          initialItem: _getSafeIndex(validStartHours, startHours ?? 0));
      _startMinutesController = FixedExtentScrollController(
          initialItem: _getSafeIndex(validStartMinutes, startMinutes ?? 0));
    }

    // 종료 시간 컨트롤러들 (모든 타입)
    List<DateTime> validEndDates = await _validator.getValidDates(true);

    List<int> validEndHours = await _getValidHours(true);
    List<int> validEndMinutes = await _getValidMinutes(true);

    _endDateController = FixedExtentScrollController(
        initialItem: _getSafeDateIndex(validEndDates, selectedEndDate));
    _endHoursController = FixedExtentScrollController(
        initialItem: _getSafeIndex(validEndHours, endHours));
    _endMinutesController = FixedExtentScrollController(
        initialItem: _getSafeIndex(validEndMinutes, endMinutes));
  }

  int _getSafeDateIndex(List<DateTime> validDates, DateTime targetDate) {
    if (validDates.isEmpty) return 0;

    for (int i = 0; i < validDates.length; i++) {
      if (validDates[i].year == targetDate.year &&
          validDates[i].month == targetDate.month &&
          validDates[i].day == targetDate.day) {
        return i;
      }
    }

    // 찾지 못하면 가장 가까운 날짜 반환
    DateTime closest = validDates.reduce((prev, curr) {
      return (curr.difference(targetDate).inDays.abs() <
              prev.difference(targetDate).inDays.abs())
          ? curr
          : prev;
    });

    return validDates.indexWhere((date) =>
        date.year == closest.year &&
        date.month == closest.month &&
        date.day == closest.day);
  }

  int _getSafeIndex(List<int> validList, int targetValue) {
    if (validList.isEmpty) return 0; // 빈 리스트 처리

    int index = validList.indexOf(targetValue);
    // 만약 현재 값이 유효하지 않다면 가장 가까운 유효한 값의 인덱스 반환
    if (index == -1) {
      // 가장 가까운 값 찾기
      int closestValue = validList.reduce((prev, curr) {
        return (curr - targetValue).abs() < (prev - targetValue).abs()
            ? curr
            : prev;
      });
      return validList.indexOf(closestValue);
    }
    return index;
  }

  // 날짜 변경 후 시간/분 업데이트
  Future<void> _updateValidTimesAfterDateChange(bool isEndTime) async {
    List<int> newValidHours = await _getValidHoursForCurrentDate(isEndTime);
    int currentHour = isEndTime ? endHours : (startHours ?? 0);

    // 현재 시간이 유효하지 않으면 조정
    if (newValidHours.isNotEmpty && !newValidHours.contains(currentHour)) {
      int newHour = isEndTime ? newValidHours.last : newValidHours.first;
      if (isEndTime) {
        endHours = newHour;
      } else {
        startHours = newHour;
      }

      // 시간 Controller 업데이트
      int hourIndex = newValidHours.indexOf(newHour);
      if (isEndTime) {
        _endHoursController.animateToItem(hourIndex,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      } else {
        _startHoursController.animateToItem(hourIndex,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }

    // 업데이트된 시간으로 분 재계산
    List<int> newValidMinutes =
        await _getValidMinutesForCurrentDateTime(isEndTime);

    int currentMinute = isEndTime ? endMinutes : (startMinutes ?? 0);

    if (newValidMinutes.isNotEmpty &&
        !newValidMinutes.contains(currentMinute)) {
      int newMinute = isEndTime ? newValidMinutes.last : newValidMinutes.first;

      if (isEndTime) {
        endMinutes = newMinute;
      } else {
        startMinutes = newMinute;
      }

      // 분 Controller 업데이트
      int minuteIndex = newValidMinutes.indexOf(newMinute);
      if (isEndTime) {
        _endMinutesController.animateToItem(minuteIndex,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      } else {
        _startMinutesController.animateToItem(minuteIndex,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

// 시간 변경 후 분 업데이트
  Future<void> _updateValidMinutesAfterHourChange(bool isEndTime) async {
    List<int> newValidMinutes =
        await _getValidMinutesForCurrentDateTime(isEndTime);
    int currentMinute = isEndTime ? endMinutes : (startMinutes ?? 0);

    if (newValidMinutes.isNotEmpty &&
        !newValidMinutes.contains(currentMinute)) {
      int newMinute;
      if (isEndTime) {
        newMinute = newValidMinutes.last; // 가능한 늦은 분
        endMinutes = newMinute;
      } else {
        newMinute = newValidMinutes.first; // 가능한 이른 분
        startMinutes = newMinute;
      }

      // Controller 위치도 업데이트!
      int newIndex = newValidMinutes.indexOf(newMinute);
      if (isEndTime) {
        _endMinutesController.animateToItem(
          newIndex,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _startMinutesController.animateToItem(
          newIndex,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  /// 유효한 시간 리스트 가져오기 (wrapper 함수들)
  Future<List<DateTime>> _getValidDates(bool isEndTime) async {
    return await _validator.getValidDates(isEndTime);
  }

  Future<List<int>> _getValidHours(bool isEndTime) async {
    return await _validator.getValidHours(isEndTime, _getCurrentDateTime);
  }

  Future<List<int>> _getValidMinutes(bool isEndTime) async {
    return await _validator.getValidMinutes(isEndTime, _getCurrentDateTime);
  }

  // 현재 선택된 DateTime 반환 (초는 항상 0)
  DateTime _getCurrentDateTime(bool isEndTime) {
    if (isEndTime) {
      return DateTime(selectedEndDate.year, selectedEndDate.month,
          selectedEndDate.day, endHours, endMinutes, 0 // 초는 항상 0
          );
    } else {
      return DateTime(selectedStartDate.year, selectedStartDate.month,
          selectedStartDate.day, startHours!, startMinutes!, 0 // 초는 항상 0
          );
    }
  }

  Future<bool> _isCurrentTimeValid(bool isEndTime) async {
    final currentTime = _getCurrentDateTime(isEndTime);
    return await _validator.isValidDateTime(
        currentTime, isEndTime, _getCurrentDateTime);
  }

  Future<List<int>> _getValidHoursForCurrentDate(bool isEndTime) async {
    DateTime currentDate = isEndTime ? selectedEndDate : selectedStartDate;
    return await _validator.getValidHoursIncludingCurrent(
        currentDate, isEndTime, _getCurrentDateTime);
  }

  Future<List<int>> _getValidMinutesForCurrentDateTime(bool isEndTime) async {
    DateTime currentDate = isEndTime ? selectedEndDate : selectedStartDate;
    int currentHour = isEndTime ? endHours : (startHours ?? 0);
    return await _validator.getValidMinutesIncludingCurrent(
        currentDate, currentHour, isEndTime, _getCurrentDateTime);
  }

  Future<bool> _isValidHour(int hour, bool isEndTime) async {
    DateTime currentDate = isEndTime ? selectedEndDate : selectedStartDate;
    DateTime testTime = DateTime(
        currentDate.year, currentDate.month, currentDate.day, hour, 0, 0);
    return await _validator.isValidDateTime(
        testTime, isEndTime, _getCurrentDateTime);
  }

  int? _getDuration() {
    if (!isBreakType) return null;
    if (startHours == null || startMinutes == null) return null;

    final startDateTime = _getCurrentDateTime(false);
    final endDateTime = _getCurrentDateTime(true);

    return endDateTime.difference(startDateTime).inSeconds;
  }

  Widget _buildTimePicker({required bool isEndTime}) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _getValidDates(isEndTime),
        _getValidHoursForCurrentDate(isEndTime),
        _getValidMinutesForCurrentDateTime(isEndTime),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.grey));
        }

        List<DateTime> validDates = snapshot.data![0];
        List<int> validHours = snapshot.data![1];
        List<int> validMinutes = snapshot.data![2];

        return Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      scrollController:
                          isEndTime ? _endDateController : _startDateController,
                      itemExtent: 40,
                      onSelectedItemChanged: (int index) {
                        if (validDates.isNotEmpty &&
                            index < validDates.length) {
                          DateTime selectedDate = validDates[index];
                          if (mounted) {
                            setState(() {
                              if (isEndTime) {
                                selectedEndDate = selectedDate;
                                _updateValidTimesAfterDateChange(true);
                              } else {
                                selectedStartDate = selectedDate;
                                _updateValidTimesAfterDateChange(false);
                              }
                            });
                          }
                        }
                      },
                      children: validDates.map((date) {
                        bool isSelected = isEndTime
                            ? (selectedEndDate.year == date.year &&
                                selectedEndDate.month == date.month &&
                                selectedEndDate.day == date.day)
                            : (selectedStartDate.year == date.year &&
                                selectedStartDate.month == date.month &&
                                selectedStartDate.day == date.day);

                        return Center(
                          child: Text(
                            '${date.month}/${date.day}',
                            style: AppTextStyles.getBody(context).copyWith(
                              color: isSelected
                                  ? AppColors.textPrimary(context)
                                  : AppColors.textSecondary(context),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: isEndTime
                          ? _endHoursController
                          : (isBreakType
                              ? _startHoursController
                              : _endHoursController),
                      itemExtent: 40,
                      onSelectedItemChanged: (int index) {
                        if (validHours.isNotEmpty &&
                            index < validHours.length) {
                          int selectedHour = validHours[index];
                          if (mounted) {
                            setState(() {
                              if (isEndTime) {
                                endHours = selectedHour;
                                _updateValidMinutesAfterHourChange(true);
                              } else {
                                startHours = selectedHour;
                                _updateValidMinutesAfterHourChange(false);
                              }
                            });
                          }
                        }
                      },
                      children: validHours.map((hour) {
                        bool isSelected =
                            (isEndTime ? endHours : (startHours ?? 0)) == hour;

                        return FutureBuilder<bool>(
                          future: _isValidHour(hour, isEndTime),
                          builder: (context, validSnapshot) {
                            bool isValid = validSnapshot.data ?? false;
                            return Center(
                              child: Text(
                                '${hour}시',
                                style: AppTextStyles.getBody(context).copyWith(
                                  color: isSelected
                                      ? AppColors.textPrimary(context)
                                      : isValid
                                          ? AppColors.textSecondary(context)
                                          : AppColors.textSecondary(context)
                                              .withValues(
                                                  alpha: 0.5), // 무효하면 흐리게
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: isEndTime
                          ? _endMinutesController
                          : (isBreakType ? _startMinutesController : null),
                      itemExtent: 40,
                      onSelectedItemChanged: (int index) {
                        if (validMinutes.isNotEmpty &&
                            index < validMinutes.length) {
                          int selectedMinute = validMinutes[index];
                          if (mounted) {
                            setState(() {
                              if (isEndTime) {
                                endMinutes = selectedMinute;
                              } else {
                                startMinutes = selectedMinute;
                              }
                            });
                          }
                        }
                      },
                      children: validMinutes.map((minute) {
                        bool isSelected =
                            (isEndTime ? endMinutes : (startMinutes ?? 0)) ==
                                minute;

                        return Center(
                          child: Text(
                            '${minute}분',
                            style: AppTextStyles.getBody(context).copyWith(
                              color: isSelected
                                  ? AppColors.textPrimary(context)
                                  : AppColors.textSecondary(context),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
          height: context.hp(70),
          padding: context.paddingSM,
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16.0),
            ),
          ),
          child: const Center(
              child: CircularProgressIndicator(color: Colors.grey)));
    }

    return Container(
      height: context.hp(70),
      padding: context.paddingSM,
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: context.hp(1)),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 60,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary(context),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: context.hp(2)),
          Text(
            title,
            style: AppTextStyles.getTitle(context),
          ),
          SizedBox(height: context.hp(2)),
          Text(
            formatTime(_getDuration()),
            style: AppTextStyles.getBody(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
          SizedBox(height: context.hp(4)),
          Expanded(
            child: isBreakType
                ? Column(
                    children: [
                      Text('시작 시간',
                          style: AppTextStyles.getBody(context)
                              .copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: context.hp(1)),
                      Text(formatDate(_getCurrentDateTime(false).toString())),
                      SizedBox(height: context.hp(1)),
                      Expanded(child: _buildTimePicker(isEndTime: false)),
                      SizedBox(height: context.hp(2)),
                      Text('종료 시간',
                          style: AppTextStyles.getBody(context)
                              .copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: context.hp(1)),
                      Text(formatDate(_getCurrentDateTime(true).toString())),
                      SizedBox(height: context.hp(1)),
                      Expanded(child: _buildTimePicker(isEndTime: true)),
                    ],
                  )
                : Column(
                    children: [
                      Text('종료 시간',
                          style: AppTextStyles.getBody(context)
                              .copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: context.hp(1)),
                      Text(formatDate(_getCurrentDateTime(true).toString())),
                      SizedBox(height: context.hp(1)),
                      Expanded(child: _buildTimePicker(isEndTime: true)),
                    ],
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context); // 취소시 콜백 호출하지 않음
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '취소',
                    style: AppTextStyles.getBody(context).copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.wp(2)),
              Expanded(
                child: FutureBuilder<bool>(
                  future: _canConfirm,
                  builder: (context, snapshot) {
                    bool canConfirm = snapshot.data ?? false;

                    return ElevatedButton(
                      onPressed: canConfirm
                          ? () async {
                              try {
                                widget.onTimeSelected(
                                  _getCurrentDateTime(true),
                                  endHours,
                                  endMinutes,
                                  isBreakType
                                      ? _getCurrentDateTime(false)
                                      : null,
                                  isBreakType ? startHours : null,
                                  isBreakType ? startMinutes : null,
                                );
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              } catch (e) {
                                logger.e('Error updating activity time: $e');
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            canConfirm ? Colors.blueAccent : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '확인',
                        style: AppTextStyles.getBody(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: context.hp(2)),
        ],
      ),
    );
  }
}
