import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

// Nouveaux imports Drift
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'pages/lecture_page.dart';
import 'pages/verset_du_jour_page.dart';
import 'pages/favoris_page.dart';
import 'pages/recherche_page.dart';
import 'pages/plan_de_lecture_page.dart';
import 'pages/settings_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final StreamController<int> tabNavigationController = StreamController<int>.broadcast();

const String verseReadPreferenceKeyPrefix = 'verse_of_the_day_read_';

Future<void> initializeLocalNotifications() async {
  if (kIsWeb) return;
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid, iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Drift (SQLite)
  // L'instance est créée automatiquement lors du premier appel à DatabaseService.db

  try {
    tz_data.initializeTimeZones();
    final String currentTimeZone = kIsWeb ? "UTC" : await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
  } catch (e) { debugPrint('Erreur TZ: $e'); }

  if (!kIsWeb) await initializeLocalNotifications();
  if (!kIsWeb) await NotificationService.rescheduleOnStartup();
  
  runApp(const BibleApp());
}

class BibleApp extends StatefulWidget {
  const BibleApp({super.key});

  @override
  State<BibleApp> createState() => _BibleAppState();
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

  Future<void> _initializeApp() async {
    bool isImportNeeded = !await DatabaseService.isBibleImported();
    if (isImportNeeded) {
      setState(() => _initializationMessage = "Importation de la Bible...");
      await DatabaseService.importBibleFromJson();
    }
    // Sur le web, récupère un éventuel rappel à afficher en bannière au démarrage.
    String? webReminder;
    if (kIsWeb) {
      webReminder = await NotificationService.getStartupWebReminder();
    }
    setState(() => _isAppInitialized = true);

    if (webReminder != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messenger = ScaffoldMessenger.maybeOf(navigatorKey.currentContext ?? context);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(webReminder!),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Lire',
              onPressed: () {
                tabNavigationController.add(1); // onglet Verset du jour
              },
            ),
          ),
        );
      });
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
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/MyOwnBible_logo_trans.png', width: 120, height: 120),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_initializationMessage),
              ],
            ),
          ),
        ),
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: Text(['Lecture', 'Verset du jour', 'Favoris', 'Recherche', 'Plan'][_selectedIndex]),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Paramètres',
              onPressed: () => navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
          ],
        ),
        body: IndexedStack(index: _selectedIndex, children: pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
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
