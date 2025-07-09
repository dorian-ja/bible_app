import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlanDeLecturePage extends StatefulWidget {
  @override
  _PlanDeLecturePageState createState() => _PlanDeLecturePageState();
}

class _PlanDeLecturePageState extends State<PlanDeLecturePage> {
  Map<String, dynamic> bibleData = {};
  Set<String> lus = {};
  int totalChapitres = 0;
  bool showOnlyUnread = false;
  bool allExpanded = false;

  @override
  void initState() {
    super.initState();
    loadBible();
    loadProgression();
  }

  Future<void> loadBible() async {
    final String data = await rootBundle.loadString('assets/bible.json');
    final Map<String, dynamic> decoded = json.decode(data);

    int total = 0;
    decoded.forEach((book, chapters) {
      total += (chapters as Map<String, dynamic>).length;
    });

    final prefs = await SharedPreferences.getInstance();
    final expandedValue = prefs.getBool('plan_all_expanded') ?? false;

    setState(() {
      bibleData = decoded;
      totalChapitres = total;
      allExpanded = expandedValue;
    });
  }

  Future<void> loadProgression() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lus = prefs.getStringList('lus')?.toSet() ?? {};
    });
  }

  Future<void> toggleLu(String book, String chapter) async {
    final key = '$book|$chapter';
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (lus.contains(key)) {
        lus.remove(key);
      } else {
        lus.add(key);
      }
      prefs.setStringList('lus', lus.toList());
    });
  }

  Future<void> resetProgression() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lus.clear();
      prefs.remove('lus');
    });
  }

  Future<void> toggleAllExpanded() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      allExpanded = !allExpanded;
      prefs.setBool('plan_all_expanded', allExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return bibleData.isEmpty
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progression : ${lus.length} / $totalChapitres chapitres lus',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: totalChapitres == 0
                          ? 0.0
                          : lus.length / totalChapitres,
                      backgroundColor: Colors.grey[300],
                      color: Colors.indigo,
                      minHeight: 8,
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Afficher seulement non lus'),
                        Switch(
                          value: showOnlyUnread,
                          onChanged: (value) {
                            setState(() {
                              showOnlyUnread = value;
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: resetProgression,
                          icon: Icon(Icons.refresh),
                          label: Text("Réinitialiser"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: toggleAllExpanded,
                          icon: Icon(
                            allExpanded ? Icons.unfold_less : Icons.unfold_more,
                          ),
                          label: Text(
                            allExpanded ? "Réduire tout" : "Développer tout",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: bibleData.entries.map((entry) {
                    final book = entry.key;
                    final chapters = (entry.value as Map<String, dynamic>).keys
                        .toList();
                    chapters.sort(
                      (a, b) => int.parse(a).compareTo(int.parse(b)),
                    );

                    final visibleChapters = chapters.where((chapter) {
                      final key = '$book|$chapter';
                      return !showOnlyUnread || !lus.contains(key);
                    }).toList();

                    final lusDansLivre = chapters
                        .where((ch) => lus.contains('$book|$ch'))
                        .length;
                    final totalDansLivre = chapters.length;
                    final progress = totalDansLivre == 0
                        ? 0.0
                        : lusDansLivre / totalDansLivre;

                    if (visibleChapters.isEmpty) return SizedBox.shrink();

                    return ExpansionTile(
                      key: UniqueKey(),
                      initiallyExpanded: allExpanded,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[300],
                            color: Colors.indigo,
                            minHeight: 6,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$lusDansLivre / $totalDansLivre chapitres lus',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      children: visibleChapters.map((chapter) {
                        final key = '$book|$chapter';
                        final isLu = lus.contains(key);
                        return CheckboxListTile(
                          title: Text('Chapitre $chapter'),
                          value: isLu,
                          onChanged: (_) => toggleLu(book, chapter),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
  }
}
