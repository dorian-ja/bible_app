import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/isar_service.dart';
import 'pages/lecture_page.dart';
import 'pages/verset_du_jour_page.dart';
import 'pages/favoris_page.dart';
import 'pages/recherche_page.dart';
import 'pages/plan_de_lecture_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.importBibleFromJson();
  runApp(BibleApp());
}

class BibleApp extends StatefulWidget {
  @override
  _BibleAppState createState() => _BibleAppState();
}

class _BibleAppState extends State<BibleApp> {
  int _selectedIndex = 0;
  String? redirectedBook;
  String? redirectedChapter;
  Map<String, dynamic> bibleData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBibleData();
  }

  Future<void> loadBibleData() async {
    final String response = await rootBundle.loadString('assets/bible.json');
    final data = json.decode(response);
    setState(() {
      bibleData = data;
      isLoading = false;
    });
  }

  void navigateToLecture(String book, String chapter) {
    setState(() {
      redirectedBook = book;
      redirectedChapter = chapter;
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      LecturePage(
        initialBook: redirectedBook,
        initialChapter: redirectedChapter,
      ),
      VersetDuJourPage(onVerseTap: navigateToLecture),
      FavorisPage(bibleData: bibleData, onVerseTap: navigateToLecture),
      RecherchePage(onVerseTap: navigateToLecture),
      PlanDeLecturePage(),
    ];

    return MaterialApp(
      title: 'Bible App',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: isLoading
          ? Scaffold(body: Center(child: CircularProgressIndicator()))
          : Scaffold(
              appBar: AppBar(
                title: Text(
                  [
                    'Lecture',
                    'Verset du jour',
                    'Favoris',
                    'Recherche',
                    'Plan de lecture',
                  ][_selectedIndex],
                ),
              ),
              body: _pages[_selectedIndex],
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Theme.of(context).primaryColor,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book),
                    label: 'Lecture',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.wb_sunny),
                    label: 'Verset du jour',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.star),
                    label: 'Favoris',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: 'Recherche',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.checklist),
                    label: 'Plan',
                  ),
                ],
              ),
            ),
    );
  }
}
