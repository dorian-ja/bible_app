import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class VersetDuJourPage extends StatefulWidget {
  final void Function(String book, String chapter)? onVerseTap;

  VersetDuJourPage({this.onVerseTap});

  @override
  _VersetDuJourPageState createState() => _VersetDuJourPageState();
}

class _VersetDuJourPageState extends State<VersetDuJourPage> {
  String? book;
  String? chapter;
  String? verse;
  String? text;
  Set<String> favorites = {};
  Map<String, dynamic>? noteData;

  @override
  void initState() {
    super.initState();
    loadOrGenerateVerse();
    loadFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadFavorites();
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

  Future loadOrGenerateVerse() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final keyDate = "${today.year}-${today.month}-${today.day}";
    final storedDate = prefs.getString('verset_date');
    final storedBook = prefs.getString('verset_book');
    final storedChapter = prefs.getString('verset_chapter');
    final storedVerse = prefs.getString('verset_verse');

    if (storedDate == keyDate &&
        storedBook != null &&
        storedChapter != null &&
        storedVerse != null) {
      await loadVerseFromData(storedBook, storedChapter, storedVerse);
    } else {
      await generateNewVerse(prefs, keyDate);
    }
  }

  Future<void> loadVerseFromData(String b, String c, String v) async {
    final String data = await rootBundle.loadString('assets/bible.json');
    final Map<String, dynamic> bibleData = json.decode(data);
    final String verseText = bibleData[b]?[c]?[v] ?? '';
    setState(() {
      book = b;
      chapter = c;
      verse = v;
      text = verseText;
    });
    await loadNote();
  }

  Future<void> generateNewVerse(SharedPreferences prefs, String keyDate) async {
    final String data = await rootBundle.loadString('assets/bible.json');
    final Map<String, dynamic> bibleData = json.decode(data);
    final books = bibleData.keys.toList();
    final randomBook = books[Random().nextInt(books.length)];
    final chapters = (bibleData[randomBook] as Map<String, dynamic>).keys
        .toList();
    final randomChapter = chapters[Random().nextInt(chapters.length)];
    final verses =
        (bibleData[randomBook][randomChapter] as Map<String, dynamic>).keys
            .toList();
    final randomVerse = verses[Random().nextInt(verses.length)];
    final String verseText = bibleData[randomBook][randomChapter][randomVerse];

    await prefs.setString('verset_date', keyDate);
    await prefs.setString('verset_book', randomBook);
    await prefs.setString('verset_chapter', randomChapter);
    await prefs.setString('verset_verse', randomVerse);

    setState(() {
      book = randomBook;
      chapter = randomChapter;
      verse = randomVerse;
      text = verseText;
    });
    await loadNote();
  }

  Future<void> loadNote() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$book|$chapter|$verse';
    final jsonString = prefs.getString('note_$key');
    if (jsonString != null) {
      setState(() {
        noteData = json.decode(jsonString);
      });
    }
  }

  void showNoteDialog() {
    final key = '$book|$chapter|$verse';
    final noteText = noteData?['text'] ?? '';
    final colorHex = noteData?['color'] ?? '#FFFFFFFF';
    final controller = TextEditingController(text: noteText);
    Color currentColor = Color(int.parse(colorHex.substring(1), radix: 16));

    showDialog(
      context: context,
      builder: (context) {
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
                children: [Colors.yellow, Colors.green, Colors.red, Colors.blue]
                    .map(
                      (c) => GestureDetector(
                        onTap: () {
                          setState(() {
                            currentColor = c;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.all(4),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: currentColor == c ? 3 : 1,
                              color: Colors.black,
                            ),
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
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final colorHex =
                    '#${currentColor.value.toRadixString(16).padLeft(8, '0')}';
                await prefs.setString(
                  'note_$key',
                  json.encode({'text': controller.text, 'color': colorHex}),
                );
                setState(() {
                  noteData = {'text': controller.text, 'color': colorHex};
                });
                Navigator.pop(context);
              },
              child: Text("Enregistrer"),
            ),
          ],
        );
      },
    );
  }

  void openChapter() {
    if (widget.onVerseTap != null && book != null && chapter != null) {
      widget.onVerseTap!(book!, chapter!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (text == null) {
      return Center(child: CircularProgressIndicator());
    }
    final key = "$book|$chapter|$verse";
    final isFavorite = favorites.contains(key);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$book $chapter:$verse",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "“$text”",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          if (noteData != null && noteData!['text'] != '')
            Container(
              margin: EdgeInsets.only(top: 12),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(
                  int.parse(noteData!['color'].substring(1), radix: 16),
                ).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                noteData!['text'],
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          SizedBox(height: 24),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : Colors.grey,
            ),
            onPressed: () async {
              await toggleFavorite(key);
              await loadFavorites();
            },
          ),
          ElevatedButton.icon(
            onPressed: openChapter,
            icon: Icon(Icons.menu_book),
            label: Text("Lire le chapitre complet"),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.share),
            label: Text("Partager"),
            onPressed: () {
              if (book != null &&
                  chapter != null &&
                  verse != null &&
                  text != null) {
                final verseToShare = "$book $chapter:$verse\n\"$text\"";
                Share.share(verseToShare);
              }
            },
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.edit),
            label: Text("Ajouter une note"),
            onPressed: showNoteDialog,
          ),
        ],
      ),
    );
  }
}
