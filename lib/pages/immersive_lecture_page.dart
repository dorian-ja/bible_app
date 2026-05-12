import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/database_service.dart';
import '../main.dart' show themeService;

class ImmersiveLecturePage extends StatefulWidget {
  final String initialBook;
  final String initialChapter;
  final List<String> allBooks;

  const ImmersiveLecturePage({
    super.key,
    required this.initialBook,
    required this.initialChapter,
    required this.allBooks,
  });

  @override
  State<ImmersiveLecturePage> createState() => _ImmersiveLecturePageState();
}

class _Chunk {
  final String book;
  final String chapter;
  final List<Verse> verses;
  _Chunk({required this.book, required this.chapter, required this.verses});
}

class _ImmersiveLecturePageState extends State<ImmersiveLecturePage> {
  final List<_Chunk> _chunks = [];
  final ScrollController _scrollController = ScrollController();
  final Map<String, List<String>> _chaptersCache = {};

  bool _showControls = true;
  bool _loadingMore = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _scrollController.addListener(_onScroll);
    _loadInitialChapter();
    _scheduleAutoHide();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scrollController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleAutoHide();
  }

  Future<List<String>> _getChapters(String book) async {
    if (_chaptersCache.containsKey(book)) return _chaptersCache[book]!;
    final chapters = await DatabaseService.getChaptersForBook(book);
    _chaptersCache[book] = chapters;
    return chapters;
  }

  Future<void> _loadInitialChapter() async {
    final chapterNum = int.tryParse(widget.initialChapter);
    if (chapterNum == null) return;
    final verses = await DatabaseService.getVerses(widget.initialBook, chapterNum);
    if (mounted) {
      setState(() => _chunks.add(_Chunk(
            book: widget.initialBook,
            chapter: widget.initialChapter,
            verses: verses,
          )));
    }
  }

  void _onScroll() {
    final max = _scrollController.position.maxScrollExtent;
    final pos = _scrollController.offset;
    if (pos >= max - 300 && !_loadingMore && _chunks.isNotEmpty) {
      _loadNextChapter();
    }
  }

  Future<void> _loadNextChapter() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);

    final last = _chunks.last;
    final chapters = await _getChapters(last.book);
    final currentIdx = chapters.indexOf(last.chapter);

    String nextBook = last.book;
    String nextChapter;

    if (currentIdx >= 0 && currentIdx < chapters.length - 1) {
      nextChapter = chapters[currentIdx + 1];
    } else {
      final bookIdx = widget.allBooks.indexOf(last.book);
      if (bookIdx < 0 || bookIdx >= widget.allBooks.length - 1) {
        setState(() => _loadingMore = false);
        return; // Fin de la Bible
      }
      nextBook = widget.allBooks[bookIdx + 1];
      final nextBookChapters = await _getChapters(nextBook);
      if (nextBookChapters.isEmpty) {
        setState(() => _loadingMore = false);
        return;
      }
      nextChapter = nextBookChapters.first;
    }

    final chapterNum = int.tryParse(nextChapter);
    if (chapterNum == null) {
      setState(() => _loadingMore = false);
      return;
    }

    final verses = await DatabaseService.getVerses(nextBook, chapterNum);
    if (mounted) {
      setState(() {
        _chunks.add(_Chunk(book: nextBook, chapter: nextChapter, verses: verses));
        _loadingMore = false;
      });
    }
  }

  int get _totalItems {
    int count = 0;
    for (final chunk in _chunks) {
      count += 1 + chunk.verses.length; // 1 header + verses
    }
    if (_loadingMore) count += 1; // loader
    return count;
  }

  Widget? _buildItem(BuildContext context, int index) {
    int offset = 0;
    for (final chunk in _chunks) {
      final chunkSize = 1 + chunk.verses.length;
      if (index < offset + chunkSize) {
        final local = index - offset;
        if (local == 0) return _buildChapterHeader(context, chunk);
        return _buildVerseItem(context, chunk.verses[local - 1]);
      }
      offset += chunkSize;
    }
    // Loader en bas
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildChapterHeader(BuildContext context, _Chunk chunk) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_chunks.indexOf(chunk) > 0)
            const Divider(thickness: 0.5),
          const SizedBox(height: 8),
          Text(
            '${chunk.book} ${chunk.chapter}',
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseItem(BuildContext context, Verse verse) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
            text: '${verse.verse} ',
            style: GoogleFonts.lora(
              fontSize: themeService.bibleFontSize * 0.68,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary.withAlpha(180),
              height: 1.6,
            ),
          ),
          TextSpan(
            text: verse.textContent,
            style: GoogleFonts.lora(
              fontSize: themeService.bibleFontSize,
              height: 1.7,
            ),
          ),
        ]),
      ),
    );
  }

  String get _currentPosition {
    if (_chunks.isEmpty) return '';
    // Estimate which chunk is currently visible
    return '${_chunks.first.book} ${_chunks.first.chapter}';
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          children: [
            // ── Texte ──
            ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                20,
                _showControls ? 72 : 24,
                20,
                40,
              ),
              itemCount: _totalItems,
              itemBuilder: _buildItem,
            ),

            // ── Overlay de contrôles ──
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  color: bg.withAlpha(220),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Quitter',
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentPosition,
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.text_increase),
                            tooltip: 'Police +',
                            onPressed: () {
                              themeService.setBibleFontSize(
                                  themeService.bibleFontSize + 1);
                              setState(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.text_decrease),
                            tooltip: 'Police −',
                            onPressed: () {
                              themeService.setBibleFontSize(
                                  themeService.bibleFontSize - 1);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
