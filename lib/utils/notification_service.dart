import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/prefs_service.dart';

class NotificationService {
  // 싱글톤 패턴 적용
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  // 고정된 알림 ID 사용
  static const int activityCompletionId = 1;
  static const int activityReminderId = 2;
  static const String channelKey = 'activity_channel_20250419';

  // 알림 초기화
  Future<void> initialize() async {
    logger.d('[NotificationService] Notification init');
    if (_readyCompleter.isCompleted) return; // 이미 완료
    if (_isInitialized) return; // 초기화 진행 중
    _isInitialized = true;

    await PrefsService().reload(); // 초기화 순서 충돌 방지를 위한 disk 동기화

    await AwesomeNotifications().initialize(
      null, // 앱 아이콘 (null = 앱 아이콘 사용)
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'Activity Notifications',
          channelDescription: '활동 관련 알림',
          defaultColor: Colors.redAccent,
          ledColor: Colors.redAccent,
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
          vibrationPattern: highVibrationPattern,
          defaultRingtoneType: DefaultRingtoneType.Notification,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );

    if (PrefsService().hasRequestedNotificationPermission) {
      await requestPermissions();
      PrefsService().hasRequestedNotificationPermission = true;
    }

    _readyCompleter.complete();
  }

  Future<bool> checkPermission() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  // 알림 권한 요청 (소리와 진동 권한 포함)
  Future<bool> requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (isAllowed) return true;

    final bool granted = await AwesomeNotifications().requestPermissionToSendNotifications(
      permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light,
      ],
    );

    PrefsService().alarmFlag = granted;
    return granted;
  }

  // 1. 즉시 활동 완료 알림
  Future<void> showActivityCompletedNotification({
    required String title,
    required String body,
  }) async {
    try {
      await ready;
      if (!await checkPermission()) {
        return;
      }
      ;

      // 다른 예약된 알림이 있을 수 있으므로 모두 취소
      await cancelAllScheduledNotifications();

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: activityCompletionId,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
          fullScreenIntent: true,
          category: NotificationCategory.Alarm,
          autoDismissible: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('AwesomeNotif error: ${e.code} ${e.message}');
      return;
    }
  }

  // 2. 예약 활동 완료 알림
  Future<void> scheduleActivityCompletionNotification({
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    try {
      await ready;
      if (!await checkPermission()) {
        return;
      }
      ;

      // 기존에 예약된 모든 알림 취소
      await cancelAllScheduledNotifications();

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: activityCompletionId,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledTime,
          preciseAlarm: true, // ← 필수
          allowWhileIdle: true, // ← 필수
          repeats: false,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('AwesomeNotif error: ${e.code} ${e.message}');
      return;
    }
  }

  // 3. 예약된 활동 알림 (미리 알림)
  Future<void> scheduleActivityReminderNotification({
    required DateTime reminderTime,
    required String title,
    required String body,
  }) async {
    try {
      await ready;
      if (!await checkPermission()) {
        return;
      }

      // 기존에 예약된 미리 알림만 취소 (완료 알림은 유지)
      await cancelReminderNotification();

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: activityReminderId,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(date: reminderTime),
      );
    } on PlatformException catch (e) {
      debugPrint('AwesomeNotif error: ${e.code} ${e.message}');
      return;
    }
  }

  // 예약된 활동 알림 변경
  Future<void> updateScheduledNotification({
    required DateTime newScheduledTime,
    required String title,
    required String body,
    bool isReminder = false,
  }) async {
    try {
      await ready;
      if (!await checkPermission()) {
        return;
      }

      final int notificationId = isReminder ? activityReminderId : activityCompletionId;

      // 기존 해당 유형의 알림 취소
      await AwesomeNotifications().cancel(notificationId);

      // 새 알림 예약
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(date: newScheduledTime),
      );
    } on PlatformException catch (e) {
      debugPrint('AwesomeNotif error: ${e.code} ${e.message}');
      return;
    }
  }

  // 완료 알림만 취소
  Future<void> cancelCompletionNotification() async {
    try {
      await ready;
      await AwesomeNotifications().cancel(activityCompletionId);
    } on PlatformException catch (e) {
      logger.e('AwesomeNotif error: ${e.code} ${e.message}');
    }
  }

  // 미리 알림만 취소
  Future<void> cancelReminderNotification() async {
    try {
      await ready;
      await AwesomeNotifications().cancel(activityReminderId);
    } on PlatformException catch (e) {
      logger.e('AwesomeNotif error: ${e.code} ${e.message}');
    }
  }

  // 모든 예약된 알림 취소
  Future<void> cancelAllScheduledNotifications() async {
    await cancelCompletionNotification();
    await cancelReminderNotification();
  }

  // 모든 알림 취소 (표시된 알림 포함)
  Future<void> cancelAllNotifications() async {
    try {
      await ready;
      await AwesomeNotifications().cancelAll();
    } on PlatformException catch (e) {
      logger.e('AwesomeNotif error: ${e.code} ${e.message}');
    }
  }

  // 알림 액션 수신 핸들러 (정적 메서드)
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // 사용자가 알림을 탭했을 때 특별한 동작 없음
  }

  // 알림 생성 핸들러 (정적 메서드)
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // 알림 생성 시 특별한 동작 없음
  }

  // 알림 표시 핸들러 (정적 메서드)
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // 알림이 표시되었을 때 특별한 동작 없음
  }

  // 알림 해제 핸들러 (정적 메서드)
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // 알림이 해제되었을 때 특별한 동작 없음
  }
}
