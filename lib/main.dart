import 'dart:async';
import 'package:flutter/foundation.dart'; // Remplace dart:io
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

// Vos imports
import 'services/isar_service.dart';
import 'pages/lecture_page.dart';
import 'pages/verset_du_jour_page.dart';
import 'pages/favoris_page.dart';
import 'pages/recherche_page.dart';
import 'pages/plan_de_lecture_page.dart';

// VARIABLES GLOBALES
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final StreamController<int> tabNavigationController = StreamController<int>.broadcast();

const String verseReadPreferenceKeyPrefix = 'verse_of_the_day_read_';
const int morningNotificationId = 0;
const int middayReminderNotificationId = 1;

// INITIALISATION NOTIFICATIONS
Future<void> initializeLocalNotifications() async {
  if (kIsWeb) return; // Pas de support notifications locales standard sur Web

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onNotificationTapped,
    onDidReceiveBackgroundNotificationResponse: onNotificationTapped,
  );
}

@pragma('vm:entry-point')
Future<void> onNotificationTapped(NotificationResponse response) async {
  if (response.payload == 'verse_of_day_morning' || response.payload == 'verse_of_day_reminder') {
    await _markVerseAsReadForToday();
    await _cancelMiddayReminderNotification();
    tabNavigationController.add(1);
  }
}

Future<void> scheduleDailyMorningNotification() async {
  if (kIsWeb) return;
  if (!await Permission.notification.isGranted) return;

  const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
    'morning_verse_channel', 'Verset du Jour (Matin)',
    importance: Importance.max, priority: Priority.high,
  );
  const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

  try {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      morningNotificationId, '📖 Verset du Jour !', 'Venez découvrir votre verset biblique quotidien.',
      _nextInstanceOfTime(7, 0), notificationDetails,
      payload: 'verse_of_day_morning',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  } catch (e) { debugPrint("Erreur notif matin: $e"); }
}

Future<void> scheduleMiddayReminderNotification() async {
  if (kIsWeb) return;
  if (!await Permission.notification.isGranted) return;

  final bool alreadyRead = await _checkIfVerseWasReadToday();
  if (alreadyRead) {
    await _cancelMiddayReminderNotification();
    return;
  }

  const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
    'midday_reminder_channel', 'Rappel Verset du Jour (Midi)',
    importance: Importance.defaultImportance, priority: Priority.defaultPriority,
  );
  const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

  final tz.TZDateTime scheduledTime = _nextInstanceOfTime(12, 0, specificDay: tz.TZDateTime.now(tz.local));

  if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

  try {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      middayReminderNotificationId, '🔔 Rappel Verset du Jour', "N'oubliez pas de lire votre verset du jour !",
      scheduledTime, notificationDetails,
      payload: 'verse_of_day_reminder',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  } catch (e) { debugPrint("Erreur rappel midi: $e"); }
}

Future<void> _cancelMiddayReminderNotification() async {
  if (kIsWeb) return;
  await flutterLocalNotificationsPlugin.cancel(middayReminderNotificationId);
}

// PRÉFÉRENCES
String _getTodayPreferenceKey() {
  final now = tz.TZDateTime.now(tz.local);
  return '$verseReadPreferenceKeyPrefix${now.year}-${now.month}-${now.day}';
}

Future<void> _markVerseAsReadForToday() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_getTodayPreferenceKey(), true);
}

Future<bool> _checkIfVerseWasReadToday() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_getTodayPreferenceKey()) ?? false;
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute, {DateTime? specificDay}) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, specificDay?.year ?? now.year, specificDay?.month ?? now.month, specificDay?.day ?? now.day, hour, minute);
  if (specificDay == null && scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}

// PERMISSIONS
Future<void> requestAndScheduleInitialNotifications() async {
  if (kIsWeb) return;
  
  var notificationStatus = await Permission.notification.status;
  if (!notificationStatus.isGranted) {
    notificationStatus = await Permission.notification.request();
  }

  if (notificationStatus.isGranted) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
       await Permission.scheduleExactAlarm.request();
    }
    await scheduleDailyMorningNotification();
    await scheduleMiddayReminderNotification();
  }
}

// MAIN
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await IsarService.getIsarInstance();
  } catch (e) {
    runApp(ErrorApp(errorMessage: "Erreur DB: $e"));
    return;
  }

  try {
    tz_data.initializeTimeZones();
    final String currentTimeZone = kIsWeb ? "UTC" : await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
  } catch (e) { debugPrint('Erreur TZ: $e'); }

  await initializeLocalNotifications();
  runApp(BibleApp());
}

class ErrorApp extends StatelessWidget {
  final String errorMessage;
  const ErrorApp({Key? key, required this.errorMessage}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: Center(child: Text(errorMessage))));
  }
}

class BibleApp extends StatefulWidget {
  @override
  _BibleAppState createState() => _BibleAppState();
}

class _BibleAppState extends State<BibleApp> {
  int _selectedIndex = 0;
  String? redirectedBook;
  String? redirectedChapter;
  bool _isAppInitialized = false;
  String _initializationMessage = "Initialisation...";
  StreamSubscription? _tabNavigationSubscription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _checkForNotificationLaunch();
    _tabNavigationSubscription = tabNavigationController.stream.listen((tabIndex) {
      if (mounted) setState(() => _selectedIndex = tabIndex);
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _tabNavigationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkForNotificationLaunch() async {
    if (kIsWeb) return;
    final details = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      final payload = details!.notificationResponse?.payload;
      if (payload == 'verse_of_day_morning' || payload == 'verse_of_day_reminder') {
        setState(() => _selectedIndex = 1);
        await _markVerseAsReadForToday();
        await _cancelMiddayReminderNotification();
      }
    }
  }

  Future<void> _initializeApp() async {
    bool isImportNeeded = !await IsarService.isBibleImported();
    if (isImportNeeded) {
      setState(() => _initializationMessage = "Importation de la Bible...");
      await IsarService.importBibleFromJson();
    }
    setState(() => _isAppInitialized = true);
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => requestAndScheduleInitialNotifications());
    }
  }

  void navigateToLecture(String book, String chapter) {
    if (mounted) {
      setState(() {
        redirectedBook = book;
        redirectedChapter = chapter;
        _selectedIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAppInitialized) {
      return MaterialApp(
        home: Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), Text(_initializationMessage)]))),
      );
    }

    final List<Widget> pages = [
      _selectedIndex == 0 ? LecturePage(initialBook: redirectedBook, initialChapter: redirectedChapter, onRedirectionConsumed: () => setState(() { redirectedBook = null; redirectedChapter = null; })) : const SizedBox.shrink(),
      _selectedIndex == 1 ? VersetDuJourPage(onVerseTap: navigateToLecture) : const SizedBox.shrink(),
      _selectedIndex == 2 ? FavorisPage(onVerseTap: navigateToLecture) : const SizedBox.shrink(),
      _selectedIndex == 3 ? RecherchePage(onVerseTap: navigateToLecture) : const SizedBox.shrink(),
      _selectedIndex == 4 ? PlanDeLecturePage(onChapterTap: navigateToLecture) : const SizedBox.shrink(),
    ];

    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: Text(['Lecture', 'Verset du jour', 'Favoris', 'Recherche', 'Plan'][_selectedIndex])),
        body: IndexedStack(index: _selectedIndex, children: pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            if (index == 1) { _markVerseAsReadForToday(); _cancelMiddayReminderNotification(); }
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Lecture'),
            BottomNavigationBarItem(icon: Icon(Icons.wb_sunny), label: 'Verset'),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favoris'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Recherche'),
            BottomNavigationBarItem(icon: Icon(Icons.checklist_rtl), label: 'Plan'),
          ],
        ),
      ),
    );
  }
}
