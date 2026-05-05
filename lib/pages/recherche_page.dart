import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diacritic/diacritic.dart';
import '../database/database.dart';
import '../services/database_service.dart';

class RecherchePage extends StatefulWidget {
  final void Function(String book, String chapter)? onVerseTap;

  const RecherchePage({super.key, this.onVerseTap});

  @override
  State<RecherchePage> createState() => _RecherchePageState();
}

class _RecherchePageState extends State<RecherchePage> {
  Map<String, dynamic> bibleData = {};
  List<Verse> searchResults = [];
  String query = "";
  bool isSearching = false;
  final TextEditingController keywordController = TextEditingController();
  final TextEditingController refController = TextEditingController();
  StreamSubscription? _verseWatcher;

  @override
  void initState() {
    super.initState();
    loadBibleData();
    _subscribeToVerseChanges();
  }

  @override
  void dispose() {
    _verseWatcher?.cancel();
    super.dispose();
  }

  void _subscribeToVerseChanges() {
    // On observe la table des versets pour rafraîchir les résultats si un favori change
    _verseWatcher = DatabaseService.db.select(DatabaseService.db.verses).watch().listen((_) {
      if (mounted && searchResults.isNotEmpty) {
        _refreshSearchResults();
      }
    });
  }

  Future<void> _refreshSearchResults() async {
    // Optionnel : re-exécuter la recherche actuelle pour mettre à jour les états favoris
    if (keywordController.text.isNotEmpty) {
      searchVerses(keywordController.text, silent: true);
    }
  }

  Future<void> loadBibleData() async {
    final String response = await rootBundle.loadString('assets/bible.json');
    setState(() => bibleData = json.decode(response));
  }

  Future<void> _toggleFavorite(Verse verse) async {
    await DatabaseService.toggleFavorite(verse);
  }

  Future<void> searchVerses(String keyword, {bool silent = false}) async {
    if (!silent) setState(() => isSearching = true);
    query = keyword;

    if (keyword.trim().isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    final results = await DatabaseService.searchVersesByKeyword(keyword);
    if (mounted) {
      setState(() {
        searchResults = results;
        isSearching = false;
      });
    }
  }

  Future<void> searchByReference(String input) async {
    setState(() => isSearching = true);
    query = input;

    final match = RegExp(r'^(.+?)\s+(\d+):(\d+)$').firstMatch(input.trim());
    if (match == null) {
      setState(() { searchResults = []; isSearching = false; });
      return;
    }

    final bookInput = match.group(1)?.trim();
    final chapterNum = int.tryParse(match.group(2) ?? '');
    final verseNum = int.tryParse(match.group(3) ?? '');

    if (bookInput == null || chapterNum == null || verseNum == null) {
      setState(() { searchResults = []; isSearching = false; });
      return;
    }

    // Recherche du livre exact (gestion diacritiques)
    String? foundBookKey;
    try {
      foundBookKey = bibleData.keys.firstWhere(
        (b) => removeDiacritics(b.toLowerCase()) == removeDiacritics(bookInput.toLowerCase()),
      );
    } catch (_) {}

    if (foundBookKey != null) {
      final verse = await DatabaseService.getSingleVerse(foundBookKey, chapterNum, verseNum);
      if (mounted) {
        setState(() {
          searchResults = verse != null ? [verse] : [];
          isSearching = false;
        });
      }
    } else {
      setState(() { searchResults = []; isSearching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: keywordController,
            decoration: InputDecoration(
              labelText: 'Rechercher un mot-clé',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => searchVerses(keywordController.text)),
            ),
            onSubmitted: (v) => searchVerses(v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: refController,
            decoration: InputDecoration(
              labelText: 'Accès direct (ex: Jean 3:16)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(icon: const Icon(Icons.menu_book), onPressed: () => searchByReference(refController.text)),
            ),
            onSubmitted: (v) => searchByReference(v),
          ),
        ),
        Expanded(
          child: isSearching
              ? const Center(child: CircularProgressIndicator())
              : searchResults.isEmpty
                  ? Center(child: Text(query.isEmpty ? 'Entrez un mot ou une référence.' : 'Aucun verset trouvé.'))
                  : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final verse = searchResults[index];
                        return ListTile(
                          title: Text('${verse.book} ${verse.chapter}:${verse.verse}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(verse.textContent),
                          trailing: IconButton(
                            icon: Icon(verse.isFavorite ? Icons.star : Icons.star_border, color: verse.isFavorite ? Colors.amber : null),
                            onPressed: () => _toggleFavorite(verse),
                          ),
                          onTap: () => widget.onVerseTap?.call(verse.book, verse.chapter.toString()),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
