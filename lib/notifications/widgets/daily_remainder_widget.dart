import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/notification_service.dart';
import 'package:project1/utils/prefs_service.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:provider/provider.dart';

class DailyRemainderWidget extends StatefulWidget {
  const DailyRemainderWidget({super.key});

  @override
  State<DailyRemainderWidget> createState() => _DailyRemainderWidgetState();
}

class _DailyRemainderWidgetState extends State<DailyRemainderWidget> {
  // provider
  late final StatsProvider _statsProvider;

  // 알림 로직
  final NotificationService _notificationService = NotificationService();
  final String _prefsKey = 'daily_reminders';
  List<Map<String, dynamic>> _savedReminders = [];

  List<bool> selectedDays = List.generate(7, (index) => false);
  String? selectedActivity;
  String? _selectedActivityIcon;
  String? _selectedActivityColor;
  DateTime selectedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _statsProvider = Provider.of<StatsProvider>(context, listen: false);
    _loadReminders();
    _rescheduleAllNotifications();
  }

  void _loadReminders() async {
    final saved = PrefsService().prefs.getString(_prefsKey);
    if (saved != null) {
      _savedReminders = List<Map<String, dynamic>>.from(
          (jsonDecode(saved) as List).map((e) => Map<String, dynamic>.from(e)));
      setState(() {});
    }

    // await NotificationService().logScheduledNotifications();
  }

  void _saveReminders() {
    PrefsService().prefs.setString(_prefsKey, jsonEncode(_savedReminders));
  }

  Future<void> _rescheduleAllNotifications() async {
    final remindersCopy = List<Map<String, dynamic>>.from(_savedReminders);

    // 모든 기존 알림 취소
    for (var reminder in remindersCopy) {
      await _notificationService.cancelReminderNotifications(reminder['id']);
    }

    // 새로 예약
    for (var reminder in remindersCopy) {
      await _scheduleNotificationsForReminder(reminder);
    }
  }

  Future<void> _scheduleNotificationsForReminder(
      Map<String, dynamic> reminder) async {
    if (!PrefsService().reminderAlarmFlag) return;
    if (!await _notificationService.checkPermission()) return;

    bool hasPermission = await _notificationService.checkPermission();
    if (!hasPermission) {
      hasPermission = await _notificationService.requestPermissions();
      if (!hasPermission) {
        logger.d('[ReminderDebug] 알림 권한 거부됨 - 스케줄링 중단');
        return;
      }
    }

    final now = DateTime.now();
    final List<int> days = List<int>.from(reminder['days'] ?? []);
    final hour = reminder['hour'] as int;
    final minute = reminder['minute'] as int;
    final activity = reminder['activity'] as String;
    final reminderId = reminder['id'] as int;

    logger.d('[ReminderDebug] ===== 리마인더 스케줄링 시작 =====');
    logger.d('[ReminderDebug] 활동: $activity');
    logger.d('[ReminderDebug] 선택된 요일: $days (0=월, 6=일)');
    logger.d('[ReminderDebug] 알림 시간: $hour:$minute');

    final baseId = (reminderId % 1000000) *
        1000; // 각 리마인더는 1000개 ID 범위 사용 (reminderId % 1000000)
    int notificationIndex = 0; // dayOffset 대신 순차 index 사용
    int scheduledCount = 0;

    for (int dayOffset = 0; dayOffset <= 60; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      if (days.contains(targetDate.weekday - 1)) {
        final scheduledDate = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          hour,
          minute,
        );

        if (scheduledDate.isAfter(now)) {
          final notificationId = baseId + notificationIndex;
          notificationIndex++;
          scheduledCount++;

          logger.d('[ReminderDebug] 알림 #$scheduledCount - '
              'ID: $notificationId, '
              '날짜: ${scheduledDate.toString()}, '
              '요일: ${targetDate.weekday}');

          await _notificationService.scheduleReminderWithId(
            id: notificationId,
            reminderTime: scheduledDate,
            title: '$activity 시작할 시간이에요!',
            body: '지금 바로 시작해보세요.',
          );

          await _notificationService.debugNotification(
            id: notificationId,
            scheduledTime: scheduledDate,
            title: '$activity 시작할 시간이에요!',
          );
        }
      }
    }
    logger.d('[ReminderDebug] 총 ${scheduledCount}개 알림 예약 완료');
  }

  void _editReminder(Map<String, dynamic> reminder) {
    selectedDays =
        List.generate(7, (i) => (reminder['days'] as List).contains(i));
    selectedTime = DateTime(2024, 1, 1, reminder['hour'], reminder['minute']);
    selectedActivity = reminder['activity'];
    _selectedActivityIcon = reminder['activityIcon'];
    _selectedActivityColor = reminder['activityColor'];

    _deleteReminder(reminder['id']);
    _showNotificationBottomSheet();
  }

  void _deleteReminder(int id) async {
    setState(() {
      _savedReminders.removeWhere((r) => r['id'] == id);
    });
    _saveReminders();
    await _notificationService.cancelReminderNotifications(id);
  }

  void _showNotificationBottomSheet() {
    if (selectedActivity == null) {
      selectedDays = List.generate(7, (index) => false);
      selectedTime = DateTime.now();
      _selectedActivityIcon = null;
      _selectedActivityColor = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: context.hp(80),
          padding: context.paddingHorizSM,
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: context.paddingXS,
                width: context.wp(20),
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary(context),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: context.hp(2)),

              // Title
              Text(
                '활동 알람',
                style: AppTextStyles.getTitle(context),
              ),
              SizedBox(height: context.hp(2)),

              // 시간 피커
              Text(
                '시간',
                style: AppTextStyles.getBody(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary(context)),
              ),
              SizedBox(height: context.hp(1)),
              SizedBox(
                height: 100,
                child: Transform.scale(
                  scale: 0.9,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: selectedTime,
                    onDateTimeChanged: (DateTime time) {
                      selectedTime = time;
                    },
                  ),
                ),
              ),
              SizedBox(height: context.hp(2)),

              // 요일 선택
              Text(
                '반복',
                style: AppTextStyles.getBody(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary(context)),
              ),
              SizedBox(height: context.hp(1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  final days = ['월', '화', '수', '목', '금', '토', '일'];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setModalState(() {
                        selectedDays[index] = !selectedDays[index];
                      });
                    },
                    child: Container(
                      width: context.wp(10),
                      height: context.wp(10),
                      decoration: BoxDecoration(
                        color: selectedDays[index]
                            ? Colors.blueAccent
                            : AppColors.backgroundSecondary(context),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          days[index],
                          style: TextStyle(
                            color: selectedDays[index]
                                ? Colors.white
                                : AppColors.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: context.hp(2)),

              // 활동
              Text(
                '활동',
                style: AppTextStyles.getBody(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary(context)),
              ),
              SizedBox(height: context.hp(1)),
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final result = await _showActivitySelector();
                  if (result != null) {
                    setModalState(() {
                      selectedActivity = result;
                    });
                  }
                },
                child: Container(
                  padding: context.paddingSM,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedActivity ?? '활동을 선택해주세요',
                        style: AppTextStyles.getBody(context)
                            .copyWith(color: AppColors.textPrimary(context)),
                      ),
                      Icon(CupertinoIcons.chevron_right, size: 16),
                    ],
                  ),
                ),
              ),
              Spacer(),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showActivitySelector() async {
    final activities = await _statsProvider.getActivities();

    return await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        height: context.hp(60),
        padding: context.paddingHorizSM,
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: context.paddingXS,
              width: context.wp(20),
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textPrimary(context),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: context.hp(2)),
            Text(
              '활동 선택',
              style: AppTextStyles.getTitle(context),
            ),
            SizedBox(height: context.hp(2)),
            Expanded(
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  final iconName = activity['activity_icon'];
                  final iconData = getIconImage(iconName);

                  return Container(
                    decoration: BoxDecoration(
                      color: activity['activity_name'] == selectedActivity
                          ? Colors.red[50]
                          : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: Image.asset(
                        iconData,
                        width: context.xl,
                        height: context.xl,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: context.xl,
                            height: context.xl,
                            color: Colors.grey.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              activity['activity_name'],
                              style: AppTextStyles.getBody(context).copyWith(
                                fontWeight: FontWeight.w900,
                                color: activity['activity_name'] ==
                                        selectedActivity
                                    ? Colors.redAccent.shade200
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.symmetric(vertical: 2.0),
                            decoration: BoxDecoration(
                              color: ColorService.hexToColor(
                                  activity['activity_color']),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _selectedActivityIcon = activity['activity_icon'];
                        _selectedActivityColor = activity['activity_color'];
                        Navigator.pop(context, activity['activity_name']);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    final bool isValid =
        selectedDays.contains(true) && selectedActivity != null;

    return Container(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.backgroundSecondary(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '취소',
                style: AppTextStyles.getBody(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
          ),
          SizedBox(width: context.wp(4)),
          Expanded(
            child: ElevatedButton(
              onPressed: isValid
                  ? () async {
                      HapticFeedback.lightImpact();

                      final newReminder = {
                        'id': DateTime.now().millisecondsSinceEpoch,
                        'days': selectedDays
                            .asMap()
                            .entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList(),
                        'hour': selectedTime.hour,
                        'minute': selectedTime.minute,
                        'activity': selectedActivity,
                        'activityIcon': _selectedActivityIcon,
                        'activityColor': _selectedActivityColor,
                      };

                      _savedReminders.add(newReminder);
                      _saveReminders();
                      await _scheduleNotificationsForReminder(newReminder);

                      setState(() {});
                      Navigator.of(context).pop();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isValid
                    ? Colors.blueAccent
                    : AppColors.backgroundSecondary(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '저장',
                style: AppTextStyles.getBody(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      isValid ? Colors.white : AppColors.textSecondary(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.paddingSM,
      decoration: BoxDecoration(color: AppColors.background(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '데일리 리마인더',
                style: AppTextStyles.getTitle(context),
              ),
              FutureBuilder<bool>(
                future: _notificationService.checkPermission(),
                builder: (context, snapshot) {
                  final hasPermission = snapshot.data ?? false;
                  if (!hasPermission) return SizedBox.shrink();

                  return Container(
                    padding: context.paddingXS,
                    decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary(context),
                        shape: BoxShape.circle),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showNotificationBottomSheet();
                      },
                      child: Icon(
                        LucideIcons.plus,
                        size: context.lg,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: context.hp(2)),
          FutureBuilder<bool>(
            future: _notificationService.checkPermission(),
            builder: (context, snapshot) {
              final hasPermission = snapshot.data ?? false;

              print('hasPermission : $hasPermission');

              if (!hasPermission) {
                // 권한이 없을 경우
                return Container(
                  margin: EdgeInsets.only(bottom: context.hp(2)),
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final granted =
                          await _notificationService.requestPermissions();
                      if (granted) {
                        PrefsService().reminderAlarmFlag = true;
                        await _rescheduleAllNotifications();
                        setState(() {});
                      }
                    },
                    child: Container(
                      padding: context.paddingSM,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '알림 권한 허용하기',
                            style: AppTextStyles.getBody(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                // 권한이 있을 경우
                return Column(
                  children: [
                    if (_savedReminders.isEmpty)
                      Text(
                        '알림이 비어있어요',
                        style: AppTextStyles.getBody(context).copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ..._savedReminders.map((reminder) {
                      final days = ['월', '화', '수', '목', '금', '토', '일'];
                      final daysList = List<int>.from(reminder['days'] ?? []);
                      final selectedDayNames =
                          daysList.map((i) => days[i]).join(', ');

                      return Container(
                        margin: EdgeInsets.only(bottom: context.hp(2)),
                        child: Row(
                          children: [
                            Image.asset(
                              getIconImage(reminder['activityIcon'] ?? ''),
                              width: context.xl,
                              height: context.xl,
                            ),
                            SizedBox(width: context.wp(4)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    spacing: 10,
                                    children: [
                                      Text(
                                        selectedDayNames,
                                        style: AppTextStyles.getBody(context)
                                            .copyWith(
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                      Text(
                                        '${reminder['hour'].toString().padLeft(2, '0')}:${reminder['minute'].toString().padLeft(2, '0')}',
                                        style: AppTextStyles.getBody(context),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: context.hp(0.5)),
                                  Row(
                                    spacing: 10,
                                    children: [
                                      Text(
                                        reminder['activity'],
                                        style: AppTextStyles.getBody(context)
                                            .copyWith(
                                          color: AppColors.textPrimary(context),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: ColorService.hexToColor(
                                              reminder['activityColor'] ??
                                                  '#000000'),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  color: AppColors.textPrimary(context),
                                  shape: BoxShape.circle),
                              child: IconButton(
                                icon: Icon(
                                  LucideIcons.edit,
                                  size: 16,
                                  color: AppColors.background(context),
                                ),
                                onPressed: () {
                                  _editReminder(reminder);
                                },
                              ),
                            ),
                            SizedBox(width: context.wp(2)),
                            Container(
                              decoration: BoxDecoration(
                                  color: AppColors.textPrimary(context),
                                  shape: BoxShape.circle),
                              child: IconButton(
                                icon: Icon(
                                  LucideIcons.trash2,
                                  size: 16,
                                  color: AppColors.background(context),
                                ),
                                onPressed: () {
                                  _deleteReminder(reminder['id']);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
