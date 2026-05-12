// lib/pages/favoris_page.dart
import 'dart:async';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/database_service.dart';

class FavorisPage extends StatefulWidget {
  final void Function(String book, String chapter, [int verse])? onVerseTap;

  const FavorisPage({super.key, this.onVerseTap});

  @override
  State<FavorisPage> createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> {
  List<Verse> _favoriteVerses = [];
  bool _isLoading = true;
  StreamSubscription? _favoritesWatcher;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<Verse> get _filteredVerses {
    if (_query.isEmpty) return _favoriteVerses;
    final q = removeDiacritics(_query.toLowerCase());
    return _favoriteVerses.where((v) {
      return removeDiacritics(v.textContent.toLowerCase()).contains(q) ||
             removeDiacritics(v.book.toLowerCase()).contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text));
    _subscribeToFavorites();
  }

  void _subscribeToFavorites() {
    _favoritesWatcher = (DatabaseService.db.select(DatabaseService.db.verses)
          ..where((t) => t.isFavorite.equals(true)))
        .watch()
        .listen((verses) {
      if (mounted) {
        setState(() {
          _favoriteVerses = verses;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _removeFavorite(Verse verse) async {
    await DatabaseService.toggleFavorite(verse);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _favoritesWatcher?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteVerses.isEmpty) {
      return const Center(child: Text('Aucun favori pour le moment.'));
    }

    final verses = _filteredVerses;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Filtrer les favoris…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
        ),
        if (verses.isEmpty)
          const Expanded(
            child: Center(child: Text('Aucun favori ne correspond.')),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              itemCount: verses.length,
              itemBuilder: (context, index) {
                final verse = verses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => widget.onVerseTap
                        ?.call(verse.book, verse.chapter.toString(), verse.verse),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${verse.book} ${verse.chapter}: ${verse.verse}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.primary,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  verse.textContent,
                                  style: GoogleFonts.lora(fontSize: 14, height: 1.55),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.star, color: Colors.amber),
                            tooltip: 'Retirer des favoris',
                            onPressed: () => _removeFavorite(verse),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
