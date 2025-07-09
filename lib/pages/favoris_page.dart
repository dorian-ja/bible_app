import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavorisPage extends StatefulWidget {
  final Map<String, dynamic> bibleData;
  final void Function(String book, String chapter)? onVerseTap;

  FavorisPage({required this.bibleData, this.onVerseTap});

  @override
  _FavorisPageState createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> {
  Set<String> favorites = {};

  @override
  void initState() {
    super.initState();
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

  String? getVerseText(String key) {
    final parts = key.split('|');
    if (parts.length != 3) return null;
    final book = parts[0];
    final chapter = parts[1];
    final verse = parts[2];

    final bookData = widget.bibleData[book];
    if (bookData == null) return null;

    final chapterData = bookData[chapter];
    if (chapterData == null) return null;

    return chapterData[verse];
  }

  @override
  Widget build(BuildContext context) {
    final sortedFavorites = favorites.toList()..sort();
    return ListView.builder(
      itemCount: sortedFavorites.length,
      itemBuilder: (context, index) {
        final key = sortedFavorites[index];
        final parts = key.split('|');
        final book = parts[0];
        final chapter = parts[1];
        final verse = parts[2];
        final ref = "$book $chapter:$verse";
        final text = getVerseText(key) ?? 'Erreur de lecture';
        return ListTile(
          title: Text(ref, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(text),
          trailing: IconButton(
            icon: Icon(Icons.star, color: Colors.amber),
            onPressed: () => toggleFavorite(key),
          ),
          onTap: () {
            if (widget.onVerseTap != null) {
              widget.onVerseTap!(book, chapter);
            }
          },
        );
      },
    );
  }
}
