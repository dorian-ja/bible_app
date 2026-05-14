import 'dart:async';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/database_service.dart';
import '../utils/note_colors.dart';

class FavorisPage extends StatefulWidget {
  final void Function(String book, String chapter, [int verse])? onVerseTap;

  const FavorisPage({super.key, this.onVerseTap});

  @override
  State<FavorisPage> createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Favoris ──
  List<Verse> _favoriteVerses = [];
  StreamSubscription? _favoritesWatcher;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // ── Notes ──
  List<Verse> _annotatedVerses = [];
  StreamSubscription? _notesWatcher;

  // ── Collections ──
  List<FavoriteCollection> _collections = [];
  StreamSubscription? _collectionsWatcher;

  // shared loading flag
  bool _isLoading = true;

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
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() => setState(() => _query = _searchController.text));
    _subscribeToFavorites();
    _subscribeToNotes();
    _subscribeToCollections();
  }

  void _subscribeToFavorites() {
    _favoritesWatcher = (DatabaseService.db.select(DatabaseService.db.verses)
          ..where((t) => t.isFavorite.equals(true)))
        .watch()
        .listen((verses) {
      if (mounted) setState(() { _favoriteVerses = verses; _isLoading = false; });
    });
  }

  void _subscribeToNotes() {
    _notesWatcher = DatabaseService.db.watchAnnotatedVerses().listen((verses) {
      if (mounted) setState(() => _annotatedVerses = verses);
    });
  }

  void _subscribeToCollections() {
    _collectionsWatcher = DatabaseService.db.watchAllCollections().listen((cols) {
      if (mounted) setState(() => _collections = cols);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _favoritesWatcher?.cancel();
    _notesWatcher?.cancel();
    _collectionsWatcher?.cancel();
    super.dispose();
  }

  // ─── Favoris ───────────────────────────────────────────────

  Widget _buildFavorisTab() {
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
        if (_favoriteVerses.isEmpty)
          const Expanded(child: Center(child: Text('Aucun favori pour le moment.')))
        else if (verses.isEmpty)
          const Expanded(child: Center(child: Text('Aucun favori ne correspond.')))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              itemCount: verses.length,
              itemBuilder: (context, i) => _buildVerseCard(verses[i]),
            ),
          ),
      ],
    );
  }

  // ─── Notes ─────────────────────────────────────────────────

  Widget _buildNotesTab() {
    if (_annotatedVerses.isEmpty) {
      return const Center(child: Text('Aucune note pour le moment.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: _annotatedVerses.length,
      itemBuilder: (context, i) {
        final verse = _annotatedVerses[i];
        final highlight = parseNoteColor(verse.noteColor);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: highlight,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.onVerseTap
                ?.call(verse.book, verse.chapter.toString(), verse.verse),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${verse.book} ${verse.chapter}:${verse.verse}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    verse.textContent,
                    style: GoogleFonts.lora(fontSize: 14, height: 1.55),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (verse.noteText != null && verse.noteText!.isNotEmpty) ...[
                    const Divider(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes, size: 14, color: Colors.black54),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            verse.noteText!,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Collections ───────────────────────────────────────────

  Widget _buildCollectionsTab() {
    return Stack(
      children: [
        _collections.isEmpty
            ? const Center(child: Text('Aucune collection.\nAppuyez sur + pour en créer une.', textAlign: TextAlign.center))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                itemCount: _collections.length,
                itemBuilder: (context, i) {
                  final col = _collections[i];
                  final color = _parseCollectionColor(col.colorHex);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color,
                        radius: 14,
                      ),
                      title: Text(col.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Supprimer la collection',
                        onPressed: () => _confirmDeleteCollection(col),
                      ),
                      onTap: () => _openCollection(col),
                    ),
                  );
                },
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'fab_collection',
            onPressed: _showCreateCollectionDialog,
            tooltip: 'Nouvelle collection',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Color _parseCollectionColor(String hex) {
    final c = hex.replaceAll('#', '');
    if (c.length == 6) {
      final v = int.tryParse(c, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    return const Color(0xFF4E342E);
  }

  void _showCreateCollectionDialog() {
    final nameCtrl = TextEditingController();
    String selectedHex = '#4E342E';
    final colors = [
      ('#4E342E', 'Marron'),
      ('#1565C0', 'Bleu'),
      ('#2E7D32', 'Vert'),
      ('#AD1457', 'Rose'),
      ('#E65100', 'Orange'),
      ('#6A1B9A', 'Violet'),
    ];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nouvelle collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nom'),
                onSubmitted: (_) {},
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: colors.map((c) {
                  final color = _parseCollectionColor(c.$1);
                  final isSelected = selectedHex == c.$1;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedHex = c.$1),
                    child: Tooltip(
                      message: c.$2,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade400,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  await DatabaseService.db.insertCollection(name, selectedHex);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCollection(FavoriteCollection col) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la collection ?'),
        content: Text('« ${col.name} » sera supprimée (les versets ne seront pas affectés).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await DatabaseService.db.deleteCollection(col.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _openCollection(FavoriteCollection col) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CollectionDetailPage(
          collection: col,
          onVerseTap: widget.onVerseTap,
        ),
      ),
    );
  }

  // ─── Shared widget ──────────────────────────────────────────

  Widget _buildVerseCard(Verse verse) {
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
                      '${verse.book} ${verse.chapter}:${verse.verse}',
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
                onPressed: () => DatabaseService.toggleFavorite(verse),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.star_outline), text: 'Favoris'),
            Tab(icon: Icon(Icons.notes_outlined), text: 'Notes'),
            Tab(icon: Icon(Icons.collections_bookmark_outlined), text: 'Collections'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFavorisTab(),
              _buildNotesTab(),
              _buildCollectionsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Page détail d'une collection ──────────────────────────────

class _CollectionDetailPage extends StatelessWidget {
  final FavoriteCollection collection;
  final void Function(String book, String chapter, [int verse])? onVerseTap;

  const _CollectionDetailPage({required this.collection, this.onVerseTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(collection.name)),
      body: StreamBuilder<List<Verse>>(
        stream: DatabaseService.db.watchCollectionVerses(collection.id),
        builder: (context, snapshot) {
          final verses = snapshot.data ?? [];
          if (verses.isEmpty) {
            return const Center(
              child: Text(
                'Cette collection est vide.\nAjoutez des versets depuis la page de lecture.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            itemCount: verses.length,
            itemBuilder: (context, i) {
              final verse = verses[i];
              final highlight = parseNoteColor(verse.noteColor);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: highlight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context);
                    onVerseTap?.call(verse.book, verse.chapter.toString(), verse.verse);
                  },
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
                                '${verse.book} ${verse.chapter}:${verse.verse}',
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
                          icon: const Icon(Icons.remove_circle_outline),
                          tooltip: 'Retirer de la collection',
                          onPressed: () => DatabaseService.db
                              .removeVerseFromCollection(collection.id, verse.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
