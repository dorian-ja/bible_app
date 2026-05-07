import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'pages/lecture_page.dart';
import 'pages/verset_du_jour_page.dart';
import 'pages/favoris_page.dart';
import 'pages/recherche_page.dart';
import 'pages/plan_de_lecture_page.dart';
import 'pages/settings_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final StreamController<int> tabNavigationController = StreamController<int>.broadcast();
final ThemeService themeService = ThemeService();

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

  try {
    tz_data.initializeTimeZones();
    final String currentTimeZone = kIsWeb ? "UTC" : await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
  } catch (e) { debugPrint('Erreur TZ: $e'); }

  await themeService.load();
  if (!kIsWeb) await initializeLocalNotifications();
  if (!kIsWeb) await NotificationService.rescheduleOnStartup();

  runApp(const BibleApp());
}

// ---------- Palette Parchemin ----------
const Color kPrimary = Color(0xFF4E342E);
const Color kAccent  = Color(0xFFFFCC80);
const Color kCreamBg = Color(0xFFFFF8F0);

// ---------- Thèmes ----------

ThemeData _buildTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: brightness,
  ).copyWith(secondary: kAccent);

  // Barre de statut/navigation système
  final overlayStyle = isLight
      ? SystemUiOverlayStyle(
          statusBarColor: kPrimary,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: colorScheme.surfaceContainerLowest,
          systemNavigationBarIconBrightness: Brightness.dark,
        )
      : SystemUiOverlayStyle(
          statusBarColor: colorScheme.surface,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: colorScheme.surfaceContainerLowest,
          systemNavigationBarIconBrightness: Brightness.light,
        );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isLight ? kCreamBg : null,
    textTheme: GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: isLight ? kPrimary : colorScheme.surface,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: overlayStyle,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: kPrimary.withValues(alpha: isLight ? 0.15 : 0.3),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isLight ? Colors.white : null,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isLight ? Colors.white : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kPrimary.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kPrimary.withValues(alpha: 0.3)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kPrimary, width: 1.5),
      ),
    ),
  );
}

class BibleApp extends StatefulWidget {
  const BibleApp({super.key});

  @override
  State<BibleApp> createState() => _BibleAppState();
}

class _BibleAppState extends State<BibleApp> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String? redirectedBook;
  String? redirectedChapter;
  bool _splashVisible = true;
  String _initializationMessage = 'Initialisation...';
  String _lectureSubtitle = '';
  StreamSubscription? _tabNavigationSubscription;

  late final AnimationController _splashCtrl;
  late final Animation<double> _splashOpacity;
  late final Animation<double> _splashScale;
  late final AnimationController _tabFadeCtrl;
  late final Animation<double> _tabFade;

  @override
  void initState() {
    super.initState();
    themeService.addListener(_onThemeChanged);

    // Splash
    _splashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _splashOpacity =
        CurvedAnimation(parent: _splashCtrl, curve: Curves.easeInOut);
    _splashScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _splashCtrl, curve: Curves.elasticOut),
    );
    _splashCtrl.forward();

    // Fade onglets
    _tabFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _tabFade = CurvedAnimation(parent: _tabFadeCtrl, curve: Curves.easeIn);
    _tabFadeCtrl.value = 1.0;

    _tabNavigationSubscription = tabNavigationController.stream.listen((tabIndex) {
      if (mounted) {
        _tabFadeCtrl.forward(from: 0);
        setState(() => _selectedIndex = tabIndex);
      }
    });
    _initializeApp();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    themeService.removeListener(_onThemeChanged);
    _tabNavigationSubscription?.cancel();
    _splashCtrl.dispose();
    _tabFadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final isImportNeeded = !await DatabaseService.isBibleImported();
    if (isImportNeeded) {
      setState(() => _initializationMessage = 'Importation de la Bible...');
      await DatabaseService.importBibleFromJson();
    }
    await Future.delayed(const Duration(milliseconds: 900));
    String? webReminder;
    if (kIsWeb) {
      webReminder = await NotificationService.getStartupWebReminder();
    }
    await _splashCtrl.reverse();
    if (mounted) {
      setState(() {
        _splashVisible = false;
      });
    }

    if (webReminder != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messenger = ScaffoldMessenger.maybeOf(navigatorKey.currentContext ?? context);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(webReminder!),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Lire',
              onPressed: () => tabNavigationController.add(1),
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

  Widget _appBarTitle() {
    final sub = _selectedIndex == 0
        ? _lectureSubtitle
        : const ['', 'Verset du jour', 'Favoris', 'Recherche',
            'Plan de lecture'][_selectedIndex];
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset('assets/MyOwnBible_logo_trans.png',
              width: 28, height: 28),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('MyOwnBible',
                  style: GoogleFonts.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              if (sub.isNotEmpty)
                Text(sub,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ---- Splash animé ----
    if (_splashVisible) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: themeService.themeMode,
        home: Scaffold(
          backgroundColor: kPrimary,
          body: Center(
            child: AnimatedBuilder(
              animation: _splashCtrl,
              builder: (_, __) => FadeTransition(
                opacity: _splashOpacity,
                child: ScaleTransition(
                  scale: _splashScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/MyOwnBible_logo_trans.png',
                          width: 110, height: 110),
                      const SizedBox(height: 20),
                      Text('MyOwnBible',
                          style: GoogleFonts.lora(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(_initializationMessage,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 13)),
                      const SizedBox(height: 28),
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ---- App principale ----
    final pages = [
      _selectedIndex == 0
          ? LecturePage(
              initialBook: redirectedBook,
              initialChapter: redirectedChapter,
              onRedirectionConsumed: () => setState(() {
                redirectedBook = null;
                redirectedChapter = null;
              }),
              onTitleChange: (t) {
                if (mounted) setState(() => _lectureSubtitle = t);
              },
            )
          : const SizedBox.shrink(),
      _selectedIndex == 1
          ? VersetDuJourPage(onVerseTap: navigateToLecture)
          : const SizedBox.shrink(),
      _selectedIndex == 2
          ? FavorisPage(onVerseTap: navigateToLecture)
          : const SizedBox.shrink(),
      _selectedIndex == 3
          ? RecherchePage(onVerseTap: navigateToLecture)
          : const SizedBox.shrink(),
      _selectedIndex == 4
          ? PlanDeLecturePage(onChapterTap: navigateToLecture)
          : const SizedBox.shrink(),
    ];

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeService.themeMode,
      home: Scaffold(
        appBar: AppBar(
          title: _appBarTitle(),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Paramètres',
              onPressed: () => navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _tabFade,
          child: IndexedStack(index: _selectedIndex, children: pages),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            _tabFadeCtrl.forward(from: 0);
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Lecture'),
            NavigationDestination(
                icon: Icon(Icons.wb_sunny_outlined),
                selectedIcon: Icon(Icons.wb_sunny),
                label: 'Verset'),
            NavigationDestination(
                icon: Icon(Icons.star_outline),
                selectedIcon: Icon(Icons.star),
                label: 'Favoris'),
            NavigationDestination(
                icon: Icon(Icons.search), label: 'Recherche'),
            NavigationDestination(
                icon: Icon(Icons.checklist_rtl_outlined),
                selectedIcon: Icon(Icons.checklist_rtl),
                label: 'Plan'),
          ],
        ),
      ),
    );
  }
}

