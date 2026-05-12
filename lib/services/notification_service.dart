import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart' show flutterLocalNotificationsPlugin;
import 'database_service.dart';

/// IDs des notifications planifiées.
const int _kMorningNotifId = 1; // 7h00 Europe/Paris (récurrent)
const int _kNoonReminderNotifId = 2; // 12h00 Europe/Paris (ponctuel jour J si non lu)
const int _kPrayerNotifOffset = 1000; // IDs 1000+ réservés aux rappels de prières

const String _kPrefNotifEnabled = 'notif_enabled';
const String _kPrefVerseReadDate = 'verset_du_jour_read_date'; // yyyy-MM-dd

/// Heures fixes (heure française).
const int _kMorningHour = 7;
const int _kMorningMinute = 0;
const int _kNoonHour = 12;
const int _kNoonMinute = 0;

const String _kParisTimezone = 'Europe/Paris';

class NotificationService {
  // ---------------------------------------------------------------------------
  // PERMISSION
  // ---------------------------------------------------------------------------

  /// Demande la permission de notifications (Android 13+ / iOS).
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // ---------------------------------------------------------------------------
  // PARAMÈTRES UTILISATEUR
  // ---------------------------------------------------------------------------

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPrefNotifEnabled) ?? true;
  }

  /// Active ou désactive les rappels (7h00 + rappel 12h00) et applique immédiatement.
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefNotifEnabled, enabled);

    if (kIsWeb) return;

    if (enabled) {
      await _scheduleMorning();
      await _scheduleNoonReminderIfNeeded();
    } else {
      await cancelAll();
    }
  }

  // ---------------------------------------------------------------------------
  // SUIVI "VERSET LU AUJOURD'HUI"
  // ---------------------------------------------------------------------------

  static String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  static Future<bool> isVerseReadToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPrefVerseReadDate) == _todayKey();
  }

  /// Marque le verset du jour comme lu et reprogramme le rappel de midi
  /// pour le lendemain (au cas où l'utilisateur n'ouvre pas l'app demain).
  static Future<void> markVerseReadToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefVerseReadDate, _todayKey());
    if (kIsWeb) return;
    if (!await isEnabled()) return;
    // Annule celui d'aujourd'hui et programme celui de demain.
    await _scheduleNoonReminderIfNeeded();
  }

  // ---------------------------------------------------------------------------
  // PLANIFICATION (mobile / desktop)
  // ---------------------------------------------------------------------------

  static tz.Location _paris() => tz.getLocation(_kParisTimezone);

  static tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final paris = _paris();
    final nowParis = tz.TZDateTime.now(paris);
    var occ = tz.TZDateTime(paris, nowParis.year, nowParis.month, nowParis.day, hour, minute);
    if (!occ.isAfter(nowParis)) {
      occ = occ.add(const Duration(days: 1));
    }
    return occ;
  }

  static const AndroidNotificationDetails _androidMorning = AndroidNotificationDetails(
    'daily_verse_morning',
    'Verset du jour',
    channelDescription: 'Rappel quotidien à 7h00 pour lire le verset du jour',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const AndroidNotificationDetails _androidNoon = AndroidNotificationDetails(
    'daily_verse_reminder',
    'Rappel verset du jour',
    channelDescription: 'Rappel à 12h00 si le verset du jour n\'a pas été lu',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const DarwinNotificationDetails _darwinDetails = DarwinNotificationDetails();

  static const AndroidNotificationDetails _androidPrayer = AndroidNotificationDetails(
    'prayer_reminders',
    'Rappels de prières',
    channelDescription: 'Rappels quotidiens pour vos prières programmées',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static Future<void> _scheduleMorning() async {
    await flutterLocalNotificationsPlugin.cancel(_kMorningNotifId);
    final scheduled = _nextOccurrence(_kMorningHour, _kMorningMinute);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      _kMorningNotifId,
      'Verset du jour ✝️',
      'Bonjour ! Découvrez votre verset du jour.',
      scheduled,
      const NotificationDetails(android: _androidMorning, iOS: _darwinDetails, macOS: _darwinDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // récurrence quotidienne
    );
  }

  /// Programme le rappel ponctuel à 12h00 Paris.
  /// - Si aujourd'hui n'est pas lu et que 12h00 n'est pas encore passé : aujourd'hui.
  /// - Sinon : demain à 12h00 (sera reprogrammé chaque jour à l'ouverture de l'app
  ///   ou lors du marquage "lu").
  static Future<void> _scheduleNoonReminderIfNeeded() async {
    await flutterLocalNotificationsPlugin.cancel(_kNoonReminderNotifId);

    final paris = _paris();
    final nowParis = tz.TZDateTime.now(paris);
    final today12h = tz.TZDateTime(paris, nowParis.year, nowParis.month, nowParis.day, _kNoonHour, _kNoonMinute);

    tz.TZDateTime target;
    if (!await isVerseReadToday() && today12h.isAfter(nowParis)) {
      target = today12h;
    } else {
      target = today12h.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      _kNoonReminderNotifId,
      'N\'oubliez pas votre verset du jour 📖',
      'Vous n\'avez pas encore lu le verset d\'aujourd\'hui.',
      target,
      const NotificationDetails(android: _androidNoon, iOS: _darwinDetails, macOS: _darwinDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ---------------------------------------------------------------------------
  // RAPPELS DE PRIÈRES
  // ---------------------------------------------------------------------------

  static Future<void> schedulePrayerReminder(int prayerId, String prayerTitle, DateTime reminderTime) async {
    if (kIsWeb) return;
    final notifId = _kPrayerNotifOffset + prayerId;
    await flutterLocalNotificationsPlugin.cancel(notifId);

    final paris = _paris();
    final nowParis = tz.TZDateTime.now(paris);
    var scheduled = tz.TZDateTime(paris, nowParis.year, nowParis.month, nowParis.day, reminderTime.hour, reminderTime.minute);
    if (!scheduled.isAfter(nowParis)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notifId,
      'Rappel de prière 🙏',
      prayerTitle,
      scheduled,
      const NotificationDetails(android: _androidPrayer, iOS: _darwinDetails, macOS: _darwinDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelPrayerReminder(int prayerId) async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancel(_kPrayerNotifOffset + prayerId);
  }

  static Future<void> _rescheduleAllPrayerReminders() async {
    final prayersWithReminders = await DatabaseService.db.getPrayersWithReminders();
    for (final prayer in prayersWithReminders) {
      if (prayer.reminderTime != null) {
        await schedulePrayerReminder(prayer.id, prayer.title, prayer.reminderTime!);
      }
    }
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancel(_kMorningNotifId);
    await flutterLocalNotificationsPlugin.cancel(_kNoonReminderNotifId);
  }

  // ---------------------------------------------------------------------------
  // DÉMARRAGE DE L'APPLICATION
  // ---------------------------------------------------------------------------

  /// À appeler au démarrage : reprogramme les notifications si activées.
  /// Sans effet sur le web (voir [getStartupWebReminder]).
  static Future<void> rescheduleOnStartup() async {
    if (kIsWeb) return;
    if (!await isEnabled()) return;
    // Activé par défaut au premier lancement : on demande la permission si
    // elle n'a pas encore été accordée. Si l'utilisateur refuse, on n'active
    // simplement pas les notifications (sans bloquer l'app).
    if (!await Permission.notification.isGranted) {
      final granted = await requestPermission();
      if (!granted) return;
    }
    await _scheduleMorning();
    await _scheduleNoonReminderIfNeeded();
    await _rescheduleAllPrayerReminders();
  }

  /// Pour le web : retourne un message à afficher en bannière au démarrage,
  /// ou `null` si aucun rappel n'est pertinent (rappels désactivés, déjà lu,
  /// ou avant 7h Paris).
  static Future<String?> getStartupWebReminder() async {
    if (!await isEnabled()) return null;
    if (await isVerseReadToday()) return null;

    final paris = _paris();
    final nowParis = tz.TZDateTime.now(paris);
    if (nowParis.hour >= _kNoonHour) {
      return 'Rappel : vous n\'avez pas encore lu votre verset du jour 📖';
    }
    if (nowParis.hour >= _kMorningHour) {
      return 'C\'est l\'heure de votre verset du jour ✝️';
    }
    return null;
  }
}
