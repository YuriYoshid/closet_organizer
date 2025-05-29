import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // 通知タップ時の処理
    // TODO: デイリーチェック画面を開く
  }

  // デイリーリマインダーを設定
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      0, // 通知ID
      'クローゼットチェックの時間です！',
      '今日のクローゼットの状態を記録しましょう',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'デイリーリマインダー',
          channelDescription: '毎日のクローゼットチェックを促す通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // キャンセル
  static Future<void> cancelDailyReminder() async {
    await _notifications.cancel(0);
  }

  // ストリーク達成通知
  static Future<void> showStreakNotification(int days) async {
    String title;
    String body;
    
    if (days == 7) {
      title = '🎉 1週間達成！';
      body = '7日間連続でチェックインしました！素晴らしい！';
    } else if (days == 30) {
      title = '🏆 1ヶ月達成！';
      body = '30日間の連続記録です！あなたは整理整頓マスター！';
    } else if (days % 10 == 0) {
      title = '🔥 $days日連続！';
      body = 'ストリークが続いています！この調子で頑張りましょう！';
    } else {
      return;
    }

    await _notifications.show(
      1, // 通知ID
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_achievement',
          'ストリーク達成',
          channelDescription: '連続記録達成の通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // 次の指定時刻を計算
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
}