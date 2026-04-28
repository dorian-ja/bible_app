// lib/pages/favoris_page.dart
import 'dart:async'; // Pour StreamSubscription
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../models/verse.dart';
import '../services/isar_service.dart';

class FavorisPage extends StatefulWidget {
  final Function(String book, String chapter)? onVerseTap;

  const FavorisPage({Key? key, this.onVerseTap}) : super(key: key);

  @override
  _FavorisPageState createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> {
  final IsarService _isarService = IsarService();
  List<Verse> _favoriteVerses = [];
  bool _isLoading = true;
  StreamSubscription? _favoritesCollectionWatcher;

  @override
  void initState() {
    super.initState();
    _loadFavoriteVerses();
    _watchFavoritesCollection();
  }

  void _watchFavoritesCollection() async {
    final isar = await IsarService.db;
    // La méthode watchLazy() est directement disponible sur le QueryBuilder retourné par filter()
    _favoritesCollectionWatcher = isar.verses
        .filter()
        .isFavoriteEqualTo(true)
        .watchLazy() // ✅ Correct: watchLazy() est appelé sur le QueryBuilder
        .listen((_) {
          // Pour watchLazy, le paramètre du listen est void (ou dynamic que l'on ignore)
          debugPrint(
            "FavorisPage: Changement détecté par Isar watch, rechargement...",
          );
          if (mounted) {
            _loadFavoriteVerses();
          }
        });
  }

  Future<void> _loadFavoriteVerses() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    _favoriteVerses = await _isarService.getFavoriteVerses();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(Verse verse) async {
    await _isarService.toggleFavorite(verse);
    // Le watcher s'occupe du rechargement
  }

  @override
  void dispose() {
    _favoritesCollectionWatcher?.cancel();
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

    return ListView.builder(
      itemCount: _favoriteVerses.length,
      itemBuilder: (context, index) {
        final verse = _favoriteVerses[index];
        return ListTile(
          title: Text('${verse.book} ${verse.chapter}:${verse.verse}'),
          subtitle: Text(verse.text),
          trailing: IconButton(
            icon: Icon(
              verse.isFavorite ? Icons.star : Icons.star_border,
              color: verse.isFavorite ? Colors.amber : Colors.grey,
            ),
            tooltip: 'Retirer des favoris',
            onPressed: () => _removeFavorite(verse),
          ),
          onTap: () =>
              widget.onVerseTap?.call(verse.book, verse.chapter.toString()),
        );
      },
    );
  }
}
