// lib/pages/favoris_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../database/database.dart';
import '../services/database_service.dart';

class FavorisPage extends StatefulWidget {
  final Function(String book, String chapter)? onVerseTap;

  const FavorisPage({super.key, this.onVerseTap});

  @override
  State<FavorisPage> createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> {
  List<Verse> _favoriteVerses = [];
  bool _isLoading = true;
  StreamSubscription? _favoritesWatcher;

  @override
  void initState() {
    super.initState();
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

    return ListView.builder(
      itemCount: _favoriteVerses.length,
      itemBuilder: (context, index) {
        final verse = _favoriteVerses[index];
        return ListTile(
          title: Text('${verse.book} ${verse.chapter}:${verse.verse}'),
          subtitle: Text(verse.textContent), // Corrigé : textContent au lieu de text
          trailing: IconButton(
            icon: const Icon(Icons.star, color: Colors.amber),
            tooltip: 'Retirer des favoris',
            onPressed: () => _removeFavorite(verse),
          ),
          onTap: () => widget.onVerseTap?.call(verse.book, verse.chapter.toString()),
        );
      },
    );
  }
}
