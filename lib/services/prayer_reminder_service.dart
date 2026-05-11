import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import '../database/database.dart';
import 'database_service.dart';

class PrayerReminderService {
  static const String channelId = 'prayer_reminders';
  static const String channelName = 'Rappels de prière';
  static const String channelDescription = 'Rappels pour vos prières';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialise le service de rappels
  static Future<void> initialize() async {
    if (kIsWeb) return;

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

    await _notificationsPlugin.initialize(initSettings);
  }

  /// Crée le canal de notifications
  static Future<void> createNotificationChannel() async {
    if (kIsWeb) return;

    const androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Programme un rappel pour une prière
  static Future<void> schedulePrayerReminder(Prayer prayer) async {
    if (kIsWeb || !prayer.hasReminder || prayer.reminderTime == null) return;

    final now = DateTime.now();
    var scheduledTime = prayer.reminderTime!;

    // Si l'heure est déjà passée, programmer pour demain
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // Conversion DateTime -> TZDateTime
    final tzScheduledTime = _toTZDateTime(scheduledTime);

    await _notificationsPlugin.zonedSchedule(
      prayer.id,
      'Rappel de prière',
      prayer.title,
      tzScheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exact,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Conversion utilitaire DateTime -> TZDateTime
  static tz.TZDateTime _toTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  /// Annule un rappel
  static Future<void> cancelPrayerReminder(int prayerId) async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancel(prayerId);
  }

  /// Met à jour le rappel d'une prière
  static Future<void> updatePrayerReminder(Prayer prayer) async {
    if (kIsWeb) return;

    await cancelPrayerReminder(prayer.id);

    if (prayer.hasReminder && prayer.reminderTime != null) {
      await schedulePrayerReminder(prayer);
    }
  }

  /// Récupère tous les rappels actifs
  static Future<List<Prayer>> getActivePrayerReminders() async {
    final all = await DatabaseService.db.watchAllPrayers().first;
    return all.where((p) => p.hasReminder && p.reminderTime != null).toList();
  }

  /// Reprogramme tous les rappels au démarrage
  static Future<void> rescheduleAllReminders() async {
    if (kIsWeb) return;

    final reminders = await getActivePrayerReminders();
    for (final prayer in reminders) {
      await schedulePrayerReminder(prayer);
    }
  }
}
