// lib/pages/lecture_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database.dart';
import '../services/database_service.dart';
import '../utils/note_colors.dart';
import '../widgets/note_color_picker.dart';

class LecturePage extends StatefulWidget {
  final String? initialBook;
  final String? initialChapter;
  final VoidCallback? onRedirectionConsumed;

  const LecturePage({
    super.key,
    this.initialBook,
    this.initialChapter,
    this.onRedirectionConsumed,
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

  @override
  void initState() {
    super.initState();
    _initializePage();
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
    _chapterVersesSubscription?.cancel();
    _chapterReadStatusSubscription?.cancel();
    super.dispose();
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
    setState(() {});
  }

  Future<void> _loadChaptersForBook(String bookName) async {
    _chapters = await DatabaseService.getChaptersForBook(bookName);
  }

  Future<void> _loadAndWatchVersesForChapter(String bookName, String chapterNumberStr) async {
    final int? chapterNumber = int.tryParse(chapterNumberStr);
    if (chapterNumber == null) return;

    await _chapterVersesSubscription?.cancel();
    _chapterVersesSubscription = DatabaseService.watchVerses(bookName, chapterNumber)
        .listen((updatedVerses) {
      if (mounted) setState(() => _chapterVerses = updatedVerses);
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
    if (_isLoading) return Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(selectedChapter != null ? '$selectedBook $selectedChapter' : selectedBook!)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedBook,
                    isExpanded: true,
                    items: _books.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (v) { if (v != null) { selectedBook = v; selectedChapter = null; _loadDataForSelection(); } },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedChapter,
                    isExpanded: true,
                    items: _chapters.map((ch) => DropdownMenuItem(value: ch, child: Text('Ch. $ch'))).toList(),
                    onChanged: (v) { if (v != null) { selectedChapter = v; _loadAndWatchVersesForChapter(selectedBook!, v); _subscribeToChapterReadStatus(selectedBook!, v); } },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Lu'),
                Switch(
                  value: _isCurrentChapterRead,
                  onChanged: (v) => DatabaseService.toggleChapterReadStatus(selectedBook!, int.parse(selectedChapter!)),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _chapterVerses.length,
                itemBuilder: (context, index) {
                  final verse = _chapterVerses[index];
                  final highlight = parseNoteColor(verse.noteColor);
                  return Container(
                    color: highlight,
                    child: ListTile(
                      title: Text('${verse.verse}. ${verse.textContent}'),
                      subtitle: verse.noteText != null ? Text(verse.noteText!, style: TextStyle(fontStyle: FontStyle.italic)) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: Icon(Icons.edit_note), onPressed: () => showNoteDialogForVerse(verse)),
                          IconButton(
                            icon: Icon(verse.isFavorite ? Icons.star : Icons.star_border, color: verse.isFavorite ? Colors.amber : null),
                            onPressed: () => DatabaseService.toggleFavorite(verse),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () => SharePlus.instance.share(ShareParams(text: '${verse.book} ${verse.chapter}:${verse.verse}\n"${verse.textContent}"')),
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
