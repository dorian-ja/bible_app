import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diacritic/diacritic.dart';

class RecherchePage extends StatefulWidget {
  final void Function(String book, String chapter)? onVerseTap;

  RecherchePage({this.onVerseTap});

  @override
  _RecherchePageState createState() => _RecherchePageState();
}

class _RecherchePageState extends State<RecherchePage> {
  Map<String, dynamic> bibleData = {};
  List<Map<String, String>> searchResults = [];
  Set<String> favorites = {};
  String query = "";
  bool isSearching = false;
  final TextEditingController keywordController = TextEditingController();
  final TextEditingController refController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadBibleData();
    loadFavorites();
  }

  Future<void> loadBibleData() async {
    final String response = await rootBundle.loadString('assets/bible.json');
    final data = json.decode(response);
    setState(() {
      bibleData = data;
    });
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

  Future<void> searchVerses(String keyword) async {
    setState(() {
      isSearching = true;
      searchResults = [];
      query = keyword;
    });

    if (keyword.trim().isEmpty) {
      setState(() {
        isSearching = false;
      });
      return;
    }

    final searchLower = removeDiacritics(keyword.toLowerCase());
    final results = <Map<String, String>>[];

    await Future.delayed(Duration(milliseconds: 100)); // petit délai UI

    for (final book in bibleData.keys) {
      final chapters = bibleData[book] as Map<String, dynamic>;
      for (final chapter in chapters.keys) {
        final verses = chapters[chapter] as Map<String, dynamic>;
        for (final verseNum in verses.keys) {
          final verseText = verses[verseNum];
          if (verseText is String &&
              removeDiacritics(verseText.toLowerCase()).contains(searchLower)) {
            results.add({
              'key': "$book|$chapter|$verseNum",
              'reference': "$book $chapter:$verseNum",
              'text': verseText,
            });
          }
        }
      }
    }

    setState(() {
      searchResults = results;
      isSearching = false;
    });
  }

  Map<String, String>? getVerseFromReference(String input) {
    final match = RegExp(r'^(.+?)\s+(\d+):(\d+)$').firstMatch(input.trim());
    if (match == null) return null;

    final bookInput = match.group(1)?.trim();
    final chapter = match.group(2);
    final verse = int.tryParse(match.group(3)!);
    if (bookInput == null || chapter == null || verse == null) return null;

    final normalizedInput = removeDiacritics(bookInput.toLowerCase());
    final book = bibleData.keys.firstWhere(
      (b) => removeDiacritics(b.toLowerCase()) == normalizedInput,
      orElse: () => '',
    );

    if (book.isEmpty) return null;
    final chapterData = bibleData[book]?[chapter];
    if (chapterData == null || !chapterData.containsKey(verse.toString()))
      return null;

    return {
      'key': "$book|$chapter|$verse",
      'reference': "$book $chapter:$verse",
      'text': chapterData[verse.toString()] as String,
    };
  }

  void searchByReference(String input) {
    final result = getVerseFromReference(input);
    setState(() {
      searchResults = result != null ? [result] : [];
      query = input;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: keywordController,
              decoration: InputDecoration(
                labelText: 'Rechercher un mot-clé',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => searchVerses(keywordController.text),
                ),
              ),
              onSubmitted: searchVerses,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: refController,
              decoration: InputDecoration(
                labelText: 'Accès direct (ex: Jean 3:16)',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => searchByReference(refController.text),
                ),
              ),
              onSubmitted: searchByReference,
            ),
          ),
          if (isSearching)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else if (searchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                query.isEmpty
                    ? 'Entrez un mot ou une référence.'
                    : 'Aucun verset trouvé.',
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final result = searchResults[index];
                final key = result['key']!;
                final ref = result['reference']!;
                final text = result['text']!;
                final isFavorite = favorites.contains(key);
                final parts = key.split('|');
                final book = parts[0];
                final chapter = parts[1];

                return ListTile(
                  title: Text(
                    ref,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(text),
                  trailing: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => toggleFavorite(key),
                  ),
                  onTap: () {
                    if (widget.onVerseTap != null) {
                      widget.onVerseTap!(book, chapter);
                    }
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
