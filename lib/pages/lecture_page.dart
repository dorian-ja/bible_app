import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class LecturePage extends StatefulWidget {
  final String? initialBook;
  final String? initialChapter;

  LecturePage({this.initialBook, this.initialChapter});

  @override
  _LecturePageState createState() => _LecturePageState();
}

class _LecturePageState extends State<LecturePage> {
  Map<String, dynamic> bibleData = {};
  String? selectedBook;
  String? selectedChapter;
  Set<String> favorites = {};
  Map<String, Map<String, dynamic>> notes = {};

  @override
  void initState() {
    super.initState();
    loadBible();
    loadFavorites();
    loadNotes();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = prefs.getStringList('favorites')?.toSet() ?? {};
    });
  }

  Future<void> toggleFavorite(String key) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favorites.contains(key)) {
        favorites.remove(key);
      } else {
        favorites.add(key);
      }
      prefs.setStringList('favorites', favorites.toList());
    });
  }

  Future<void> loadBible() async {
    final String data = await rootBundle.loadString('assets/bible.json');
    final Map<String, dynamic> decoded = json.decode(data);
    setState(() {
      bibleData = decoded;
      selectedBook = widget.initialBook ?? decoded.keys.first;
      selectedChapter =
          widget.initialChapter ??
          (decoded[selectedBook!] as Map<String, dynamic>).keys.first;
    });
    markAsRead();
  }

  Future<void> markAsRead() async {
    if (selectedBook != null && selectedChapter != null) {
      final prefs = await SharedPreferences.getInstance();
      final lus = prefs.getStringList('lus')?.toSet() ?? {};
      final key = '${selectedBook!}|${selectedChapter!}';
      if (!lus.contains(key)) {
        lus.add(key);
        await prefs.setStringList('lus', lus.toList());
      }
    }
  }

  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('note_'));
    for (var k in keys) {
      final jsonString = prefs.getString(k);
      if (jsonString != null) {
        final noteData = json.decode(jsonString);
        notes[k.replaceFirst('note_', '')] = noteData;
      }
    }
    setState(() {});
  }

  Future<void> saveNote(String key, String text, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final colorHex = '#${color.value.toRadixString(16).padLeft(8, '0')}';
    await prefs.setString(
      'note_$key',
      json.encode({'text': text, 'color': colorHex}),
    );
    notes[key] = {'text': text, 'color': colorHex};
    setState(() {});
  }

  void showNoteDialog(String key) {
    final note = notes[key]?['text'] ?? '';
    final colorHex = notes[key]?['color'] ?? '#FFFFFFFF';
    final controller = TextEditingController(text: note);
    Color currentColor = Color(int.parse(colorHex.substring(1), radix: 16));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Note personnelle"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    decoration: InputDecoration(hintText: "Votre note..."),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    children:
                        [Colors.yellow, Colors.green, Colors.red, Colors.blue]
                            .map(
                              (c) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    currentColor = c;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  margin: EdgeInsets.all(4),
                                  width: currentColor == c ? 36 : 30,
                                  height: currentColor == c ? 36 : 30,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: currentColor == c
                                          ? Colors.black
                                          : Colors.grey,
                                      width: currentColor == c ? 3 : 1,
                                    ),
                                    boxShadow: currentColor == c
                                        ? [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : [],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    saveNote(key, controller.text, currentColor);
                    Navigator.pop(context);
                  },
                  child: Text("Enregistrer"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void goToNextChapter() {
    final bookList = bibleData.keys.toList();
    final currentBookIndex = bookList.indexOf(selectedBook!);
    final chapters =
        (bibleData[selectedBook!] as Map<String, dynamic>).keys.toList()
          ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    final currentChapterIndex = chapters.indexOf(selectedChapter!);
    if (currentChapterIndex < chapters.length - 1) {
      setState(() {
        selectedChapter = chapters[currentChapterIndex + 1];
      });
    } else if (currentBookIndex < bookList.length - 1) {
      final nextBook = bookList[currentBookIndex + 1];
      final nextChapters =
          (bibleData[nextBook] as Map<String, dynamic>).keys.toList()
            ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      setState(() {
        selectedBook = nextBook;
        selectedChapter = nextChapters.first;
      });
    }
    markAsRead();
  }

  void goToPreviousChapter() {
    final bookList = bibleData.keys.toList();
    final currentBookIndex = bookList.indexOf(selectedBook!);
    final chapters =
        (bibleData[selectedBook!] as Map<String, dynamic>).keys.toList()
          ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    final currentChapterIndex = chapters.indexOf(selectedChapter!);
    if (currentChapterIndex > 0) {
      setState(() {
        selectedChapter = chapters[currentChapterIndex - 1];
      });
    } else if (currentBookIndex > 0) {
      final prevBook = bookList[currentBookIndex - 1];
      final prevChapters =
          (bibleData[prevBook] as Map<String, dynamic>).keys.toList()
            ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      setState(() {
        selectedBook = prevBook;
        selectedChapter = prevChapters.last;
      });
    }
    markAsRead();
  }

  @override
  Widget build(BuildContext context) {
    if (bibleData.isEmpty || selectedBook == null || selectedChapter == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final chapters =
        (bibleData[selectedBook!] as Map<String, dynamic>).keys.toList()
          ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    final verses =
        bibleData[selectedBook!]?[selectedChapter!] as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(title: Text('$selectedBook $selectedChapter')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedBook,
                    onChanged: (value) {
                      setState(() {
                        selectedBook = value;
                        selectedChapter =
                            (bibleData[selectedBook!] as Map<String, dynamic>)
                                .keys
                                .first;
                      });
                      markAsRead();
                    },
                    isExpanded: true,
                    items: bibleData.keys.map((book) {
                      return DropdownMenuItem(value: book, child: Text(book));
                    }).toList(),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedChapter,
                    onChanged: (value) async {
                      setState(() {
                        selectedChapter = value;
                      });
                      markAsRead();
                    },
                    isExpanded: true,
                    items: chapters.map((ch) {
                      return DropdownMenuItem(
                        value: ch,
                        child: Text('Chapitre $ch'),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Lu'),
                FutureBuilder<SharedPreferences>(
                  future: SharedPreferences.getInstance(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData ||
                        selectedBook == null ||
                        selectedChapter == null) {
                      return Switch(value: false, onChanged: null);
                    }
                    final prefs = snapshot.data!;
                    final lus = prefs.getStringList('lus')?.toSet() ?? {};
                    final key = '$selectedBook|$selectedChapter';
                    final isLu = lus.contains(key);
                    return Switch(
                      value: isLu,
                      onChanged: (value) {
                        setState(() {
                          if (value) {
                            lus.add(key);
                          } else {
                            lus.remove(key);
                          }
                          prefs.setStringList('lus', lus.toList());
                        });
                      },
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  ...(verses?.entries.map((entry) {
                        final verseKey =
                            '$selectedBook|$selectedChapter|${entry.key}';
                        final isFavorite = favorites.contains(verseKey);
                        final noteColor = notes[verseKey]?['color'];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: noteColor != null
                                    ? Color(
                                        int.parse(
                                          noteColor.substring(1),
                                          radix: 16,
                                        ),
                                      )
                                    : Colors.transparent,
                                width: 6,
                              ),
                            ),
                            color: noteColor != null
                                ? Color(
                                    int.parse(
                                      noteColor.substring(1),
                                      radix: 16,
                                    ),
                                  ).withOpacity(0.05)
                                : null,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key}. ${entry.value}',
                                style: TextStyle(fontSize: 17, height: 1.5),
                              ),
                              SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    tooltip: 'Note',
                                    onPressed: () => showNoteDialog(verseKey),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 20,
                                      color: isFavorite
                                          ? Colors.amber
                                          : Colors.grey,
                                    ),
                                    tooltip: 'Favori',
                                    onPressed: () => toggleFavorite(verseKey),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.share,
                                      size: 20,
                                      color: Colors.blueGrey,
                                    ),
                                    tooltip: 'Partager',
                                    onPressed: () {
                                      final textToShare =
                                          "$selectedBook $selectedChapter:${entry.key}\n\"${entry.value}\"";
                                      Share.share(textToShare);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList() ??
                      []),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: goToPreviousChapter,
                        icon: Icon(Icons.arrow_back),
                        label: Text('Chapitre précédent'),
                      ),
                      ElevatedButton.icon(
                        onPressed: goToNextChapter,
                        icon: Icon(Icons.arrow_forward),
                        label: Text('Chapitre suivant'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
