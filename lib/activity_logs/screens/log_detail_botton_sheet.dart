import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/activity_logs/widgets/activity_picker_modal.dart';
import 'package:project1/activity_logs/widgets/time_picker_modal.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/time_formatter.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:timeline_tile/timeline_tile.dart';

class LogDetailBottonSheet extends StatefulWidget {
  final Map<String, dynamic> log;
  final bool editMode;

  const LogDetailBottonSheet({
    super.key,
    required this.log,
    this.editMode = false,
  });

  @override
  State<LogDetailBottonSheet> createState() => _LogDetailBottonSheetState();
}

class _LogDetailBottonSheetState extends State<LogDetailBottonSheet> {
  late final DatabaseService _dbService;
  late final StatsProvider _statsProvider;
  late final TimerProvider _timerProvider;

  // 전체 활동 list
  late Future<List<Map<String, dynamic>>> futureActivityList;

  // 활동 temp
  String activityName = '활동이름';
  String activityIcon = 'category';
  String activityId = '';
  String activityColor = '';

  bool editMode = false;

  // 상태 변수들
  List<Map<String, dynamic>> _breaks = [];
  Map<String, dynamic> _sessionData = {};
  bool _isLoading = true;
  bool _hasTimeChanges = false;

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    _statsProvider = Provider.of<StatsProvider>(context, listen: false);
    _timerProvider = Provider.of<TimerProvider>(context, listen: false);

    _sessionData = Map.from(widget.log);
    _loadBreaks();

    activityId = widget.log['activity_id'] ?? '';
    activityName = widget.log['activity_name'] ?? '활동이름';
    activityIcon = widget.log['activity_icon'] ?? 'category';
    activityColor = widget.log['activity_color'] ?? '#000000';
    editMode = widget.editMode;

    futureActivityList = _statsProvider.getActivities(); // 활동 불러오기
  }

  Future<void> _loadBreaks() async {
    try {
      final breaks = await _dbService.getBreaks(sessionId: widget.log['session_id']);
      setState(() {
        _breaks = breaks.map((b) => Map<String, dynamic>.from(b)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showActivityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FutureBuilder(
          future: futureActivityList,
          builder: (context, snapshot) {
            List<Map<String, dynamic>> activities = snapshot.data ?? [];
            return ActivityPickerModal(
              activities: activities,
              selectedActivityName: activityName,
              onActivitySelected: (id, name, icon, color) {
                setState(() {
                  activityId = id;
                  activityName = name;
                  activityIcon = icon;
                  activityColor = color;
                });
              },
            );
          },
        );
      },
    );
  }

  void _showTimePicker({
    required BuildContext context,
    required Map<String, dynamic> item,
    required Map<String, dynamic>? beforeItem,
    required Map<String, dynamic>? afterItem,
  }) {
    if (item['type'] == 'break') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return TimePickerModal(
            item: item,
            beforeItem: beforeItem ?? {},
            afterItem: afterItem ?? {},
            onTimeSelected: (
              DateTime endDateTime,
              int endHours,
              int endMinutes, [
              DateTime? startDateTime,
              int? startHours,
              int? startMinutes,
            ]) {
              setState(() {
                _hasTimeChanges = true;
                final index = _breaks.indexWhere((b) => b['break_id'] == item['break_id']);
                if (index >= 0) {
                  _breaks[index]['start_time'] = startDateTime!.toUtc().toIso8601String();
                  _breaks[index]['end_time'] = endDateTime.toUtc().toIso8601String();
                }
                if (_sessionData['end_time'] != null) {
                  final sessionStart = DateTime.parse(_sessionData['start_time']);
                  final sessionEnd = DateTime.parse(_sessionData['end_time']);
                  int totalSessionSeconds = sessionEnd.difference(sessionStart).inSeconds;

                  int totalBreakSeconds = 0;
                  for (var breakItem in _breaks) {
                    if (breakItem['end_time'] != null) {
                      final breakStart = DateTime.parse(breakItem['start_time']);
                      final breakEnd = DateTime.parse(breakItem['end_time']);
                      totalBreakSeconds += breakEnd.difference(breakStart).inSeconds;
                    }
                  }

                  _sessionData['duration'] = totalSessionSeconds - totalBreakSeconds;
                }
              });
            },
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return TimePickerModal(
            item: item,
            beforeItem: beforeItem ?? {},
            afterItem: afterItem ?? {},
            onTimeSelected: (
              DateTime endDateTime,
              int endHours,
              int endMinutes, [
              DateTime? startDateTime,
              int? startHours,
              int? startMinutes,
            ]) {
              setState(() {
                _hasTimeChanges = true;

                _sessionData['end_time'] = endDateTime.toUtc().toIso8601String();

                if (_breaks.isNotEmpty && _breaks.last['end_time'] == null) {
                  final lastBreakStart = DateTime.parse(_breaks.last['start_time']);
                  if (endDateTime.isAfter(lastBreakStart)) {
                    _breaks.last['end_time'] = endDateTime.toUtc().toIso8601String();
                  }
                }

                final sessionStart = DateTime.parse(_sessionData['start_time']);
                int totalSessionSeconds = endDateTime.difference(sessionStart).inSeconds;

                int totalBreakSeconds = 0;
                for (var breakItem in _breaks) {
                  if (breakItem['end_time'] != null) {
                    final breakStart = DateTime.parse(breakItem['start_time']);
                    final breakEnd = DateTime.parse(breakItem['end_time']);
                    totalBreakSeconds += breakEnd.difference(breakStart).inSeconds;
                  }
                }

                _sessionData['duration'] = totalSessionSeconds - totalBreakSeconds;
              });
            },
          );
        },
      );
    }
  }

  void _saveChanges() async {
    Map<String, dynamic> updatedLog = Map.from(widget.log);

    // 활동 정보 업데이트
    updatedLog['activity_id'] = activityId;
    updatedLog['activity_name'] = activityName;
    updatedLog['activity_icon'] = activityIcon;
    updatedLog['activity_color'] = activityColor;

    if (_hasTimeChanges) {
      // 이미 계산된 값 사용 (중복 계산 제거)
      updatedLog['duration'] = _sessionData['duration'];
      updatedLog['end_time'] = _sessionData['end_time'];

      // break들 업데이트
      for (var breakItem in _breaks) {
        await _dbService.updateBreak(
          breakId: breakItem['break_id'],
          startTime: breakItem['start_time'],
          endTime: breakItem['end_time'],
        );
      }

      // 세션 업데이트
      await _dbService.modifySession(
        sessionId: widget.log['session_id'],
        newDuration: _sessionData['duration'], // calculatedDuration -> _sessionData['duration']
        activityId: activityId,
        activityName: activityName,
        activityIcon: activityIcon,
        activityColor: activityColor,
        endTime: _sessionData['end_time'],
      );
    } else {
      // 기존 코드 유지
      await _dbService.modifySession(
        sessionId: widget.log['session_id'],
        newDuration: updatedLog['duration'],
        activityId: activityId,
        activityName: activityName,
        activityIcon: activityIcon,
        activityColor: activityColor,
      );
    }
    await FacebookAppEvents().logEvent(
      name: 'update_log',
      valueToSum: 2,
    );

    _statsProvider.updateCurrentSessions();
    _timerProvider.refreshRemainingSeconds();

    Navigator.of(context).pop(updatedLog); // _sessionData -> updatedLog
  }

  Widget _buildTitleRow({required String label, required String color, required String icon, int? duration}) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: ColorService.hexToColor(color).withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              getIconImage(icon),
              width: 40,
              height: 40,
            ),
          ),
        ),
        SizedBox(width: context.wp(4)),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: editMode
                      ? () {
                          HapticFeedback.lightImpact();
                          _showActivityPicker(context);
                        }
                      : null,
                  child: Text(
                    label,
                    style: AppTextStyles.getTitle(context).copyWith(
                      wordSpacing: -0.3,
                      decoration: editMode ? TextDecoration.underline : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (editMode)
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showActivityPicker(context);
                  },
                  icon: Icon(
                    LucideIcons.edit,
                    size: context.lg,
                    color: AppColors.textSecondary(context),
                  ),
                ),
            ],
          ),
        ),
        Text(
          formatTime(duration ?? 0),
          style: AppTextStyles.getTitle(context).copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  String _getTimelineDate(Map<String, dynamic> item) {
    final timeString = item['type'] == 'break' ? item['start_time'] : item['time'];
    return timeString != null ? formatDateOnly(timeString) : '';
  }

  String _getTimelineTimeText(Map<String, dynamic> item) {
    if (item['type'] == 'break') {
      final endTime = item['end_time'];
      return endTime != null
          ? '${formatTimeOnly(item['start_time'])}부터\n${formatTimeOnly(endTime)}까지'
          : '${formatTimeOnly(item['start_time'])}부터\n진행중';
    } else {
      final time = item['time'];
      return time != null ? formatTimeOnly(time) : '진행중';
    }
  }

  String _getBreakDuration(Map<String, dynamic> item) {
    if (item['type'] != 'break' || item['end_time'] == null) {
      return '';
    }
    return _calculateBreakDuration(item['start_time'], item['end_time']);
  }

  Widget _buildTimeline() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.grey));
    }

    List<Map<String, dynamic>> timelineItems = [];

    // 활동 시작
    timelineItems.add(
      {
        'type': 'activity_start',
        'time': _sessionData['start_time'],
        'title': '활동 시작',
      },
    );

    for (int i = 0; i < _breaks.length; i++) {
      timelineItems.add({
        'type': 'break',
        'start_time': _breaks[i]['start_time'],
        'end_time': _breaks[i]['end_time'],
        'title': '${i + 1}번째 휴식',
        'break_id': _breaks[i]['break_id'],
      });
    }

    timelineItems.add({
      'type': 'activity_end',
      'time': _sessionData['end_time'],
      'title': '활동 종료',
      'session_id': _sessionData['session_id'],
    });

    return ListView.builder(
      itemCount: timelineItems.length,
      itemBuilder: (context, index) {
        final beforeItem = index > 0 ? timelineItems[index - 1] : null;
        final item = timelineItems[index];
        final afterItem = index < timelineItems.length - 1 ? timelineItems[index + 1] : null;

        final currentDate = _getTimelineDate(item);
        final previousDate = index > 0 ? _getTimelineDate(timelineItems[index - 1]) : '';

        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.2,
          isFirst: index == 0,
          isLast: index == timelineItems.length - 1,
          indicatorStyle: IndicatorStyle(
            width: 10,
            color: _getTimelineColor(item['type']),
          ),
          beforeLineStyle: LineStyle(
            color: AppColors.backgroundTertiary(context),
            thickness: 2,
          ),
          startChild: currentDate != previousDate
              ? Text(
                  currentDate,
                  style: AppTextStyles.getCaption(context).copyWith(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
          endChild: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: editMode && item['type'] != 'activity_start'
                ? () {
                    HapticFeedback.lightImpact();
                    _showTimePicker(
                      context: context,
                      item: item,
                      beforeItem: beforeItem,
                      afterItem: afterItem,
                    );
                  }
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: index == timelineItems.length - 1 ? 8 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(item['title'], style: AppTextStyles.getBody(context)),
                            SizedBox(width: context.wp(2)),
                            if (item['type'] == 'break')
                              Text(
                                _getBreakDuration(item),
                                style: AppTextStyles.getCaption(context).copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          _getTimelineTimeText(item),
                          style: AppTextStyles.getCaption(context).copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (editMode && item['type'] != 'activity_start')
                    Icon(
                      LucideIcons.edit,
                      size: context.lg,
                      color: AppColors.textSecondary(context),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getTimelineColor(String type) {
    switch (type) {
      case 'activity_start':
      case 'activity_end':
        return Colors.blueAccent;
      default:
        return AppColors.backgroundTertiary(context);
    }
  }

  String _calculateBreakDuration(String startTime, String endTime) {
    final start = DateTime.parse(startTime);
    final end = DateTime.parse(endTime);
    final duration = end.difference(start);

    return formatTime(duration.inSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(90),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 60,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: context.hp(2)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '활동 기록',
                    style: AppTextStyles.getTitle(context),
                  ),
                  if (!editMode)
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          editMode = !editMode;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: context.paddingXS,
                      ),
                      child: Text(
                        '수정',
                        style: AppTextStyles.getCaption(context).copyWith(
                          color: Colors.white,
                          wordSpacing: -0.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: context.hp(2)),
              _buildTitleRow(
                label: activityName,
                color: activityColor,
                icon: activityIcon,
                duration: _sessionData['duration'],
              ),
              SizedBox(height: context.hp(2)),
              Divider(color: AppColors.backgroundSecondary(context)),
              SizedBox(height: context.hp(2)),
              Text(
                '타임라인',
                style: AppTextStyles.getBody(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary(context),
                ),
              ),
              SizedBox(height: context.hp(1)),
              Expanded(child: _buildTimeline()),
            ],
          ),
          if (editMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
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
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '저장',
                        style: AppTextStyles.getBody(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
