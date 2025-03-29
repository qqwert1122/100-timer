import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // 싱글톤 패턴 적용
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // 고정된 알림 ID 사용
  static const int activityCompletionId = 1;
  static const int activityReminderId = 2;
  // 알림 초기화
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // 앱 아이콘 (null = 앱 아이콘 사용)
      [
        NotificationChannel(
          channelKey: 'activity_channel',
          channelName: 'Activity Notifications',
          channelDescription: '활동 관련 알림',
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
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

    // 권한 요청
    await requestPermissions();
  }

  // 알림 권한 요청 (소리와 진동 권한 포함)
  Future<void> requestPermissions() async {
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications(
          permissions: [
            NotificationPermission.Alert,
            NotificationPermission.Sound,
            NotificationPermission.Badge,
            NotificationPermission.Vibration,
            NotificationPermission.Light,
          ],
        );
      }
    });
  }

  // 1. 즉시 활동 완료 알림
  Future<void> showActivityCompletedNotification({
    required String title,
    required String body,
  }) async {
    // 다른 예약된 알림이 있을 수 있으므로 모두 취소
    await cancelAllScheduledNotifications();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: activityCompletionId,
        channelKey: 'activity_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  // 2. 예약 활동 완료 알림
  Future<void> scheduleActivityCompletionNotification({
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    // 기존에 예약된 모든 알림 취소
    await cancelAllScheduledNotifications();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: activityCompletionId,
        channelKey: 'activity_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledTime),
    );
  }

  // 3. 예약된 활동 알림 (미리 알림)
  Future<void> scheduleActivityReminderNotification({
    required DateTime reminderTime,
    required String title,
    required String body,
  }) async {
    // 기존에 예약된 미리 알림만 취소 (완료 알림은 유지)
    await cancelReminderNotification();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: activityReminderId,
        channelKey: 'activity_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: reminderTime),
    );
  }

  // 예약된 활동 알림 변경
  Future<void> updateScheduledNotification({
    required DateTime newScheduledTime,
    required String title,
    required String body,
    bool isReminder = false,
  }) async {
    final int notificationId = isReminder ? activityReminderId : activityCompletionId;

    // 기존 해당 유형의 알림 취소
    await AwesomeNotifications().cancel(notificationId);

    // 새 알림 예약
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'activity_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: newScheduledTime),
    );
  }

  // 완료 알림만 취소
  Future<void> cancelCompletionNotification() async {
    await AwesomeNotifications().cancel(activityCompletionId);
  }

  // 미리 알림만 취소
  Future<void> cancelReminderNotification() async {
    await AwesomeNotifications().cancel(activityReminderId);
  }

  // 모든 예약된 알림 취소
  Future<void> cancelAllScheduledNotifications() async {
    await cancelCompletionNotification();
    await cancelReminderNotification();
  }

  // 모든 알림 취소 (표시된 알림 포함)
  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
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
