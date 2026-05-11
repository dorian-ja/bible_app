// lib/pages/lecture_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database.dart';
import '../services/database_service.dart';
import '../services/tts_service.dart';
import '../utils/note_colors.dart';
import '../widgets/note_color_picker.dart';
import '../main.dart' show themeService;

class LecturePage extends StatefulWidget {
  final String? initialBook;
  final String? initialChapter;
  final VoidCallback? onRedirectionConsumed;
  final void Function(String title)? onTitleChange;

  const LecturePage({
    super.key,
    this.initialBook,
    this.initialChapter,
    this.onRedirectionConsumed,
    this.onTitleChange,
  });

  @override
  State<LecturePage> createState() => _LecturePageState();
}

class _LecturePageState extends State<LecturePage> {
  List<String> _books = [];
  List<String> _chapters = [];
  List<Verse> _chapterVerses = [];

  String? selectedBook;
  String? selectedChapter;

  bool _isLoading = true;

  StreamSubscription? _chapterVersesSubscription;
  bool _isCurrentChapterRead = false;
  StreamSubscription? _chapterReadStatusSubscription;

  final TtsService _tts = TtsService();
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _verseKeys = [];

  @override
  void initState() {
    super.initState();
    themeService.addListener(_onThemeChanged);
    _tts.addListener(_onTtsChanged);
    _initializePage();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _onTtsChanged() {
    if (mounted) {
      setState(() {});
      _scrollToCurrentVerse();
    }
  }

  void _scrollToCurrentVerse() {
    final idx = _tts.currentVerseIndex;
    if (idx < _verseKeys.length) {
      final ctx = _verseKeys[idx].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 300),
            alignment: 0.3);
      }
    }
  }

  @override
  void didUpdateWidget(covariant LecturePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.initialBook != null && widget.initialBook != selectedBook) ||
        (widget.initialChapter != null && widget.initialChapter != selectedChapter)) {
      selectedBook = widget.initialBook;
      selectedChapter = widget.initialChapter;
      _loadDataForSelection();
    }
  }

  @override
  void dispose() {
    themeService.removeListener(_onThemeChanged);
    _tts.removeListener(_onTtsChanged);
    _tts.stop();
    _tts.dispose();
    _scrollController.dispose();
    _chapterVersesSubscription?.cancel();
    _chapterReadStatusSubscription?.cancel();
    super.dispose();
  }

  void _goToPreviousChapter() {
    if (selectedChapter == null || _chapters.isEmpty) return;
    final idx = _chapters.indexOf(selectedChapter!);
    if (idx > 0) {
      selectedChapter = _chapters[idx - 1];
      _loadAndWatchVersesForChapter(selectedBook!, selectedChapter!);
      _subscribeToChapterReadStatus(selectedBook!, selectedChapter!);
      setState(() {});
    } else {
      // Premier chapitre du livre : aller au livre précédent
      final bookIdx = _books.indexOf(selectedBook!);
      if (bookIdx > 0) {
        setState(() {
          selectedBook = _books[bookIdx - 1];
          selectedChapter = null;
        });
        _loadDataForSelection();
      }
    }
  }

  void _goToNextChapter() {
    if (selectedChapter == null || _chapters.isEmpty) return;
    final idx = _chapters.indexOf(selectedChapter!);
    if (idx < _chapters.length - 1) {
      selectedChapter = _chapters[idx + 1];
      _loadAndWatchVersesForChapter(selectedBook!, selectedChapter!);
      _subscribeToChapterReadStatus(selectedBook!, selectedChapter!);
      setState(() {});
    } else {
      // Dernier chapitre du livre : aller au livre suivant
      final bookIdx = _books.indexOf(selectedBook!);
      if (bookIdx < _books.length - 1) {
        setState(() {
          selectedBook = _books[bookIdx + 1];
          selectedChapter = null;
        });
        _loadDataForSelection();
      }
    }
  }

  Future<void> _initializePage() async {
    setState(() => _isLoading = true);
    _books = await DatabaseService.getBooks();
    if (_books.isNotEmpty) {
      selectedBook = widget.initialBook ?? _books.first;
      await _loadChaptersForBook(selectedBook!);
      if (_chapters.isNotEmpty) {
        selectedChapter = widget.initialChapter ?? _chapters.first;
        await _loadAndWatchVersesForChapter(selectedBook!, selectedChapter!);
        _subscribeToChapterReadStatus(selectedBook!, selectedChapter!);
      }
    }
    setState(() => _isLoading = false);
    widget.onRedirectionConsumed?.call();
    _updateTitle();
  }

  Future<void> _loadDataForSelection() async {
    if (selectedBook == null) return;
    setState(() {});
    await _loadChaptersForBook(selectedBook!);
    if (_chapters.isNotEmpty) {
      if (selectedChapter == null || !_chapters.contains(selectedChapter)) {
        selectedChapter = _chapters.first;
      }
      await _loadAndWatchVersesForChapter(selectedBook!, selectedChapter!);
      _subscribeToChapterReadStatus(selectedBook!, selectedChapter!);
    }
    _updateTitle();
    setState(() {});
  }

  void _updateTitle() {
    if (selectedBook != null) {
      final t = selectedChapter != null
          ? '$selectedBook $selectedChapter'
          : selectedBook!;
      widget.onTitleChange?.call(t);
    }
  }

  Future<void> _loadChaptersForBook(String bookName) async {
    _chapters = await DatabaseService.getChaptersForBook(bookName);
  }

  Future<void> _loadAndWatchVersesForChapter(String bookName, String chapterNumberStr) async {
    final int? chapterNumber = int.tryParse(chapterNumberStr);
    if (chapterNumber == null) return;

    await _tts.stop();
    await _chapterVersesSubscription?.cancel();
    _chapterVersesSubscription = DatabaseService.watchVerses(bookName, chapterNumber)
        .listen((updatedVerses) {
      if (mounted) {
        setState(() {
          _chapterVerses = updatedVerses;
          _verseKeys
            ..clear()
            ..addAll(List.generate(updatedVerses.length, (_) => GlobalKey()));
        });
      }
    });
  }

  void _subscribeToChapterReadStatus(String book, String chapterStr) {
    _chapterReadStatusSubscription?.cancel();
    final int? chapterNum = int.tryParse(chapterStr);
    if (chapterNum == null) return;

    _chapterReadStatusSubscription = DatabaseService.watchChapterReadStatus(book, chapterNum).listen((isRead) {
      if (mounted) setState(() => _isCurrentChapterRead = isRead);
    });
  }

  void showNoteDialogForVerse(Verse verse) {
    final controller = TextEditingController(text: verse.noteText ?? '');
    String? selectedColor = verse.noteColor;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text("Note pour ${verse.book} ${verse.chapter}:${verse.verse}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(hintText: "Votre note...")),
              const SizedBox(height: 12),
              const Text('Couleur de surlignage :', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              NoteColorPicker(
                selectedHex: selectedColor,
                onChanged: (hex) => setStateDialog(() => selectedColor = hex),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Annuler")),
            TextButton(
              onPressed: () async {
                final text = controller.text.trim();
                await DatabaseService.updateVerseNote(
                  verse,
                  text.isEmpty ? null : text,
                  selectedColor,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -300) _goToNextChapter();
        if (v > 300) _goToPreviousChapter();
      },
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // ── Sélecteurs livre / chapitre ──
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedBook,
                    isExpanded: true,
                    items: _books.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        selectedBook = v;
                        selectedChapter = null;
                        _loadDataForSelection();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedChapter,
                    isExpanded: true,
                    items: _chapters.map((ch) => DropdownMenuItem(value: ch, child: Text('Ch. $ch'))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => selectedChapter = v);
                        _loadAndWatchVersesForChapter(selectedBook!, v);
                        _subscribeToChapterReadStatus(selectedBook!, v);
                        widget.onTitleChange?.call('$selectedBook $v');
                      }
                    },
                  ),
                ),
              ],
            ),
            // ── Barre Lu + bouton audio ──
            Row(
              children: [
                const Text('Lu'),
                Switch(
                  value: _isCurrentChapterRead,
                  onChanged: (v) => DatabaseService.toggleChapterReadStatus(
                      selectedBook!, int.parse(selectedChapter!)),
                ),
                const Spacer(),
                _AudioPlayerBar(tts: _tts, verses: _chapterVerses),
              ],
            ),
            // ── Liste des versets ──
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _chapterVerses.length,
                itemBuilder: (context, index) {
                  final verse = _chapterVerses[index];
                  final highlight = parseNoteColor(verse.noteColor);
                  final isActive = _tts.isPlaying && _tts.currentVerseIndex == index;
                  final activeColor = Theme.of(context).colorScheme.primaryContainer;

                  return Container(
                    key: _verseKeys.length > index ? _verseKeys[index] : null,
                    color: isActive ? activeColor : highlight,
                    child: ListTile(
                      title: Text(
                        '${verse.verse}. ${verse.textContent}',
                        style: GoogleFonts.lora(
                          fontSize: themeService.bibleFontSize,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: verse.noteText != null
                          ? Text(verse.noteText!,
                              style: const TextStyle(fontStyle: FontStyle.italic))
                          : null,
                      onTap: () => _tts.isPlaying || _tts.state == TtsState.paused
                          ? _tts.playFrom(index)
                          : null,
                      trailing: PopupMenuButton<_VerseAction>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (action) {
                          switch (action) {
                            case _VerseAction.note:
                              showNoteDialogForVerse(verse);
                            case _VerseAction.favorite:
                              DatabaseService.toggleFavorite(verse);
                            case _VerseAction.share:
                              SharePlus.instance.share(ShareParams(
                                  text: '${verse.book} ${verse.chapter}:${verse.verse}\n"${verse.textContent}"'));
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: _VerseAction.note,
                            child: ListTile(
                              leading: Icon(Icons.edit_note),
                              title: Text('Note'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: _VerseAction.favorite,
                            child: ListTile(
                              leading: Icon(
                                verse.isFavorite ? Icons.star : Icons.star_border,
                                color: verse.isFavorite ? Colors.amber : null,
                              ),
                              title: Text(verse.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: _VerseAction.share,
                            child: ListTile(
                              leading: Icon(Icons.share),
                              title: Text('Partager'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _VerseAction { note, favorite, share }

// ── Widget barre de lecture audio ──────────────────────────────────────────

class _AudioPlayerBar extends StatelessWidget {
  final TtsService tts;
  final List<Verse> verses;

  const _AudioPlayerBar({required this.tts, required this.verses});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final isActive = tts.isPlaying || tts.state == TtsState.paused;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Voix
        if (tts.availableVoices.isNotEmpty)
          PopupMenuButton<TtsVoice>(
            tooltip: 'Voix',
            icon: Icon(Icons.record_voice_over, color: color, size: 20),
            onSelected: (v) => tts.selectVoice(v),
            itemBuilder: (_) => tts.availableVoices
                .map((v) => PopupMenuItem<TtsVoice>(
                      value: v,
                      child: Row(
                        children: [
                          if (v == tts.selectedVoice)
                            Icon(Icons.check, size: 16, color: color)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 6),
                          Text(v.displayName),
                        ],
                      ),
                    ))
                .toList(),
          ),
        // Vitesse
        if (isActive)
          PopupMenuButton<double>(
            tooltip: 'Vitesse',
            initialValue: tts.speed,
            icon: Text('${tts.speed}×',
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
            onSelected: (v) => tts.setSpeed(v),
            itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                .map((v) => PopupMenuItem(value: v, child: Text('$v×')))
                .toList(),
          ),
        // ⏮
        if (isActive)
          IconButton(
            icon: const Icon(Icons.skip_previous),
            color: color,
            tooltip: 'Verset précédent',
            onPressed: tts.skipPrevious,
          ),
        // ▶ / ⏸ / ■
        IconButton(
          icon: Icon(tts.isPlaying
              ? Icons.pause_circle_filled
              : tts.state == TtsState.paused
                  ? Icons.play_circle_filled
                  : Icons.play_circle_outline),
          color: color,
          iconSize: 32,
          tooltip: tts.isPlaying
              ? 'Pause'
              : tts.state == TtsState.paused
                  ? 'Reprendre'
                  : 'Lire le chapitre',
          onPressed: () {
            if (verses.isEmpty) return;
            if (tts.isPlaying) {
              tts.pause();
            } else if (tts.state == TtsState.paused) {
              tts.resume();
            } else {
              tts.loadAndPlay(
                verses: verses.map((v) => v.textContent).toList(),
                verseNumbers: verses.map((v) => v.verse).toList(),
              );
            }
          },
        ),
        // ⏭
        if (isActive)
          IconButton(
            icon: const Icon(Icons.skip_next),
            color: color,
            tooltip: 'Verset suivant',
            onPressed: tts.skipNext,
          ),
        // ■ stop
        if (isActive)
          IconButton(
            icon: const Icon(Icons.stop),
            color: color,
            tooltip: 'Arrêter',
            onPressed: tts.stop,
          ),
      ],
    );
  }
}
