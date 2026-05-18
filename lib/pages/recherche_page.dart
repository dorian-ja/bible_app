import 'dart:async';
import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../services/database_service.dart';
import '../utils/note_colors.dart';

class RecherchePage extends StatefulWidget {
  final void Function(String book, String chapter, [int verse])? onVerseTap;

  const RecherchePage({super.key, this.onVerseTap});

  @override
  State<RecherchePage> createState() => _RecherchePageState();
}

class _RecherchePageState extends State<RecherchePage> {
  Map<String, dynamic> bibleData = {};
  List<Verse> searchResults = [];
  String query = "";
  bool isSearching = false;
  String? _selectedColor;
  List<String> _searchHistory = [];
  bool _showHistory = false;
  final TextEditingController keywordController = TextEditingController();
  final TextEditingController refController = TextEditingController();
  final FocusNode _keywordFocus = FocusNode();
  StreamSubscription? _verseWatcher;

  static const _historyKey = 'search_history';
  static const _historyMax = 8;

  @override
  void initState() {
    super.initState();
    loadBibleData();
    _subscribeToVerseChanges();
    _loadHistory();
    _keywordFocus.addListener(() {
      setState(() => _showHistory = _keywordFocus.hasFocus && keywordController.text.isEmpty);
    });
    keywordController.addListener(() {
      setState(() => _showHistory = _keywordFocus.hasFocus && keywordController.text.isEmpty);
    });
  }

  @override
  void dispose() {
    _verseWatcher?.cancel();
    keywordController.dispose();
    refController.dispose();
    _keywordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _searchHistory = prefs.getStringList(_historyKey) ?? []);
    }
  }

  Future<void> _saveToHistory(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    final updated = [trimmed, ..._searchHistory.where((h) => h != trimmed)]
        .take(_historyMax)
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, updated);
    if (mounted) setState(() => _searchHistory = updated);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    if (mounted) setState(() => _searchHistory = []);
  }

  void _subscribeToVerseChanges() {
    _verseWatcher = DatabaseService.db.select(DatabaseService.db.verses).watch().listen((_) {
      if (mounted && searchResults.isNotEmpty) {
        _refreshSearchResults();
      }
    });
  }

  Future<void> _refreshSearchResults() async {
    if (_selectedColor != null) {
      _searchByColor(_selectedColor!, silent: true);
    } else if (keywordController.text.isNotEmpty) {
      searchVerses(keywordController.text, silent: true);
    }
  }

  Future<void> loadBibleData() async {
    final data = await DatabaseService.getBibleData();
    setState(() => bibleData = data);
  }

  Future<void> _toggleFavorite(Verse verse) async {
    await DatabaseService.toggleFavorite(verse);
  }

  void _clearAll() {
    keywordController.clear();
    refController.clear();
    setState(() {
      _selectedColor = null;
      searchResults = [];
      query = '';
      isSearching = false;
    });
  }

  Future<void> _searchByColor(String colorHex, {bool silent = false}) async {
    if (!silent) {
      keywordController.clear();
      refController.clear();
      setState(() {
        _selectedColor = colorHex;
        isSearching = true;
        query = colorHex;
      });
    }
    final results = await DatabaseService.getVersesByColor(colorHex);
    if (mounted) {
      setState(() {
        searchResults = results;
        isSearching = false;
      });
    }
  }

  Future<void> searchVerses(String keyword, {bool silent = false}) async {
    if (!silent) {
      setState(() {
        _selectedColor = null;
        isSearching = true;
        _showHistory = false;
      });
      if (keyword.trim().isNotEmpty) _saveToHistory(keyword.trim());
    }
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
    setState(() {
      _selectedColor = null;
      isSearching = true;
    });
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
    final colors = kNoteColorOptions.where((c) => c.hex != null).toList();

    return Column(
      children: [
        // ── Recherche mot-clé ──
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            controller: keywordController,
            focusNode: _keywordFocus,
            decoration: InputDecoration(
              labelText: 'Rechercher un mot-clé',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: keywordController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearAll,
                    )
                  : null,
            ),
            onSubmitted: (v) => searchVerses(v),
            onChanged: (_) => setState(() {}),
          ),
        ),
        // ── Historique de recherche ──
        if (_showHistory && _searchHistory.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: _searchHistory
                        .map((h) => InputChip(
                              label: Text(h, style: const TextStyle(fontSize: 12)),
                              onPressed: () {
                                keywordController.text = h;
                                searchVerses(h);
                                _keywordFocus.unfocus();
                              },
                              onDeleted: () async {
                                final updated = List<String>.from(_searchHistory)..remove(h);
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setStringList(_historyKey, updated);
                                if (mounted) setState(() => _searchHistory = updated);
                              },
                            ))
                        .toList(),
                  ),
                ),
                TextButton(
                  onPressed: _clearHistory,
                  child: const Text('Effacer', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        // ── Accès direct par référence ──
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            controller: refController,
            decoration: const InputDecoration(
              labelText: 'Accès direct (ex : Jean 3:16)',
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
            onSubmitted: (v) => searchByReference(v),
          ),
        ),
        // ── Filtre par couleur de surlignage ──
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              const Icon(Icons.palette_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              ...colors.map((opt) {
                final isSelected = _selectedColor == opt.hex;
                final color = parseNoteColor(opt.hex)!;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: opt.label,
                    child: GestureDetector(
                      onTap: () => isSelected
                          ? _clearAll()
                          : _searchByColor(opt.hex!),
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
                          boxShadow: isSelected
                              ? [BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                )]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 14, color: Colors.black54)
                            : null,
                      ),
                    ),
                  ),
                );
              }),
              if (_selectedColor != null) ...[
                const Spacer(),
                TextButton(
                  onPressed: _clearAll,
                  child: const Text('Effacer'),
                ),
              ],
            ],
          ),
        ),
        // ── Résultats ──
        Expanded(
          child: isSearching
              ? const Center(child: CircularProgressIndicator())
              : searchResults.isEmpty
                  ? Center(
                      child: Text(
                        query.isEmpty
                            ? 'Entrez un mot, une référence\nou sélectionnez une couleur.'
                            : _selectedColor != null
                                ? 'Aucun verset surligné avec cette couleur.'
                                : 'Aucun verset trouvé.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final verse = searchResults[index];
                        final highlight = parseNoteColor(verse.noteColor);
                        final textOverride = readableTextOn(highlight, context);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: highlight,
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
                                            color: textOverride ??
                                                Theme.of(context).colorScheme.primary,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          verse.textContent,
                                          style: GoogleFonts.lora(
                                              fontSize: 14,
                                              height: 1.55,
                                              color: textOverride),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      verse.isFavorite ? Icons.star : Icons.star_outline,
                                      color: verse.isFavorite ? Colors.amber : null,
                                    ),
                                    onPressed: () => _toggleFavorite(verse),
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
