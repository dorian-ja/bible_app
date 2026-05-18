// lib/pages/lecture_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' show Value;
import '../database/database.dart';
import '../services/database_service.dart';
import '../services/tts_service.dart';
import '../utils/note_colors.dart';
import '../widgets/note_color_picker.dart';
import '../widgets/share_verse_image_dialog.dart';
import '../main.dart' show themeService;
import 'immersive_lecture_page.dart';

class LecturePage extends StatefulWidget {
  final String? initialBook;
  final String? initialChapter;
  final int? initialVerse;
  final VoidCallback? onRedirectionConsumed;
  final void Function(String title)? onTitleChange;

  const LecturePage({
    super.key,
    this.initialBook,
    this.initialChapter,
    this.initialVerse,
    this.onRedirectionConsumed,
    this.onTitleChange,
  });

  static Future<void> saveLastPosition(String book, String chapter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_book', book);
    await prefs.setString('last_chapter', chapter);
  }

  static Future<({String book, String chapter})?> loadLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final book = prefs.getString('last_book');
    final chapter = prefs.getString('last_chapter');
    if (book == null || chapter == null) return null;
    return (book: book, chapter: chapter);
  }

  @override
  State<LecturePage> createState() => _LecturePageState();
}

class _LecturePageState extends State<LecturePage>
    with SingleTickerProviderStateMixin {
  List<String> _books = [];
  List<String> _chapters = [];
  List<Verse> _chapterVerses = [];

  String? selectedBook;
  String? selectedChapter;

  bool _isLoading = true;
  double _contentOpacity = 1.0;
  bool _isFirstChapterEmission = false;
  int? _targetVerse;

  StreamSubscription? _chapterVersesSubscription;
  bool _isCurrentChapterRead = false;
  StreamSubscription? _chapterReadStatusSubscription;

  final TtsService _tts = TtsService();
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _verseKeys = [];

  // Animation de surbrillance pour mettre en évidence un verset après navigation.
  late final AnimationController _flashCtrl;
  late final Animation<double> _flashAnim;
  int? _flashIndex;

  @override
  void initState() {
    super.initState();
    themeService.addListener(_onThemeChanged);
    _tts.addListener(_onTtsChanged);
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    // Fade in rapide → maintien → fade out lent, pour attirer l'œil sans gêner.
    _flashAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 2),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 3),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 6),
    ]).animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeInOut));
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
            duration: const Duration(milliseconds: 300), alignment: 0.3);
      }
    }
  }

  @override
  void didUpdateWidget(covariant LecturePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.initialBook != null && widget.initialBook != selectedBook) ||
        (widget.initialChapter != null &&
            widget.initialChapter != selectedChapter)) {
      selectedBook = widget.initialBook;
      selectedChapter = widget.initialChapter;
      _targetVerse = widget.initialVerse;
      // Différer pour éviter setState pendant le build du parent
      // (didUpdateWidget s'exécute pendant la phase build de _BibleAppState).
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _loadDataForSelection();
        if (mounted) widget.onRedirectionConsumed?.call();
      });
    }
  }

  @override
  void dispose() {
    themeService.removeListener(_onThemeChanged);
    _tts.removeListener(_onTtsChanged);
    _flashCtrl.dispose();
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
    if (!mounted) return;
    // Si didUpdateWidget a déjà installé une sélection pendant nos awaits,
    // respecter ce choix au lieu de l'écraser avec _books.first ('Genèse').
    if (selectedBook == null && _books.isNotEmpty) {
      selectedBook = widget.initialBook ?? _books.first;
      _targetVerse = widget.initialVerse;
    }
    if (selectedBook != null) {
      await _loadChaptersForBook(selectedBook!);
      if (!mounted) return;
      if (_chapters.isNotEmpty) {
        selectedChapter ??= widget.initialChapter ?? _chapters.first;
        await _loadAndWatchVersesForChapter(selectedBook!, selectedChapter!);
        _subscribeToChapterReadStatus(selectedBook!, selectedChapter!);
      }
    }
    if (!mounted) return;
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

  void _scrollToVerse(int verseNum) {
    final index = _chapterVerses.indexWhere((v) => v.verse == verseNum);
    if (index < 0 || index >= _verseKeys.length) return;
    _attemptScrollToIndex(index, attempt: 0);
    _flashVerse(index);
  }

  void _flashVerse(int index) {
    if (!mounted) return;
    setState(() => _flashIndex = index);
    _flashCtrl.forward(from: 0).whenComplete(() {
      if (mounted && _flashIndex == index) {
        setState(() => _flashIndex = null);
      }
    });
  }

  void _attemptScrollToIndex(int index, {required int attempt}) {
    if (!mounted) return;
    if (index < 0 || index >= _verseKeys.length) return;

    final ctx = _verseKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.15,
      );
      return;
    }

    // Item hors viewport : pas de currentContext car SliverList lazy-layout
    // les enfants. On saute vers une position estimée pour faire entrer
    // l'item dans le cacheExtent, puis on retente au prochain frame.
    if (attempt >= 6 || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final total = _chapterVerses.length;
    if (total > 0 && position.maxScrollExtent > 0) {
      final estimated =
          (index / total * position.maxScrollExtent).clamp(0.0, position.maxScrollExtent);
      _scrollController.jumpTo(estimated);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptScrollToIndex(index, attempt: attempt + 1);
    });
  }

  Future<void> _loadAndWatchVersesForChapter(
      String bookName, String chapterNumberStr) async {
    final int? chapterNumber = int.tryParse(chapterNumberStr);
    if (chapterNumber == null) return;

    // Sauvegarde de la dernière position lue
    LecturePage.saveLastPosition(bookName, chapterNumberStr);

    await _tts.stop();
    await _chapterVersesSubscription?.cancel();

    // Fade out, vider immédiatement, armer le flag première émission
    setState(() {
      _contentOpacity = 0.0;
      _chapterVerses = [];
      _verseKeys = [];
      _isFirstChapterEmission = true;
    });

    _chapterVersesSubscription =
        DatabaseService.watchVerses(bookName, chapterNumber).listen(
      (updatedVerses) {
        if (!mounted) return;
        setState(() {
          _chapterVerses = updatedVerses;
          _verseKeys = List.generate(updatedVerses.length, (_) => GlobalKey());
          _contentOpacity = 1.0;
        });

        // Scroll uniquement à la première émission (changement de chapitre).
        // Les émissions suivantes (toggle favori, note…) ne bougent pas l'écran.
        if (_isFirstChapterEmission) {
          _isFirstChapterEmission = false;
          final tv = _targetVerse;
          _targetVerse = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (tv != null) {
              // Double callback : le premier frame construit la liste,
              // le second garantit que le layout est pleinement terminé.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _scrollToVerse(tv);
              });
            } else if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
          });
        }
      },
    );
  }

  void _subscribeToChapterReadStatus(String book, String chapterStr) {
    _chapterReadStatusSubscription?.cancel();
    final int? chapterNum = int.tryParse(chapterStr);
    if (chapterNum == null) return;
    _chapterReadStatusSubscription =
        DatabaseService.watchChapterReadStatus(book, chapterNum)
            .listen((isRead) {
      if (mounted) setState(() => _isCurrentChapterRead = isRead);
    });
  }

  void _showNoteDialog(Verse verse) {
    final controller = TextEditingController(text: verse.noteText ?? '');
    String? selectedColor = verse.noteColor;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(
              '${verse.book} ${verse.chapter}:${verse.verse}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                maxLines: 3,
                decoration:
                    const InputDecoration(hintText: 'Votre note...'),
              ),
              const SizedBox(height: 12),
              const Text('Surlignage :',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              NoteColorPicker(
                selectedHex: selectedColor,
                onChanged: (hex) =>
                    setStateDialog(() => selectedColor = hex),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler')),
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
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConcordance(Verse verse) async {
    final related =
        await DatabaseService.db.findRelatedVerses(verse);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text('Versets liés',
                      style: GoogleFonts.lora(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(
                    '${verse.book} ${verse.chapter}:${verse.verse}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (related.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: Text('Aucun verset lié trouvé.')),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: related.length,
                  itemBuilder: (_, i) {
                    final v = related[i];
                    return ListTile(
                      title: Text(
                        '${v.book} ${v.chapter}:${v.verse}',
                        style: GoogleFonts.lora(
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        v.textContent,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          selectedBook = v.book;
                          selectedChapter = v.chapter.toString();
                        });
                        _loadDataForSelection();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseItem(BuildContext context, int index) {
    final verse = _chapterVerses[index];
    final highlight = parseNoteColor(verse.noteColor);
    final isActive = _tts.isPlaying && _tts.currentVerseIndex == index;
    final activeColor = Theme.of(context).colorScheme.primaryContainer;
    final baseColor = isActive ? activeColor : highlight;
    final key = index < _verseKeys.length ? _verseKeys[index] : null;
    final isFlashing = _flashIndex == index;

    if (isFlashing) {
      final flashColor =
          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.55);
      return AnimatedBuilder(
        animation: _flashAnim,
        builder: (context, child) {
          final color =
              Color.lerp(baseColor, flashColor, _flashAnim.value);
          return Container(
            key: key,
            color: color,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: child,
          );
        },
        child: _buildVerseRow(context, verse, index, isActive),
      );
    }

    return Container(
      key: key,
      color: baseColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: _buildVerseRow(context, verse, index, isActive),
    );
  }

  Widget _buildVerseRow(
      BuildContext context, Verse verse, int index, bool isActive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _tts.isPlaying || _tts.state == TtsState.paused
                ? _tts.playFrom(index)
                : null,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '${verse.verse} ',
                  style: GoogleFonts.lora(
                    fontSize: themeService.bibleFontSize * 0.68,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha(180),
                    height: 1.6,
                  ),
                ),
                TextSpan(
                  text: verse.textContent,
                  style: GoogleFonts.lora(
                    fontSize: themeService.bibleFontSize,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                    height: 1.6,
                  ),
                ),
              ]),
            ),
          ),
        ),
        PopupMenuButton<_VerseAction>(
          icon: const Icon(Icons.more_vert, size: 18),
          onSelected: (action) {
            switch (action) {
              case _VerseAction.note:
                _showNoteDialog(verse);
              case _VerseAction.favorite:
                HapticFeedback.lightImpact();
                DatabaseService.toggleFavorite(verse);
              case _VerseAction.collection:
                _showAddToCollectionDialog(verse);
              case _VerseAction.share:
                SharePlus.instance.share(ShareParams(
                    text:
                        '${verse.book} ${verse.chapter}:${verse.verse}\n"${verse.textContent}"'));
              case _VerseAction.shareImage:
                showShareVerseImageDialog(context, verse);
              case _VerseAction.concordance:
                _showConcordance(verse);
              case _VerseAction.linkPrayer:
                _showLinkToPrayerDialog(verse);
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
                title: Text(verse.isFavorite
                    ? 'Retirer des favoris'
                    : 'Ajouter aux favoris'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: _VerseAction.collection,
              child: ListTile(
                leading: Icon(Icons.collections_bookmark_outlined),
                title: Text('Ajouter à une collection'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: _VerseAction.share,
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Partager texte'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: _VerseAction.shareImage,
              child: ListTile(
                leading: Icon(Icons.image_outlined),
                title: Text('Partager en image'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: _VerseAction.linkPrayer,
              child: ListTile(
                leading: Icon(Icons.self_improvement),
                title: Text('Lier à une prière'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: _VerseAction.concordance,
              child: ListTile(
                leading: Icon(Icons.link),
                title: Text('Versets liés'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (verse.isFavorite)
          const Icon(Icons.star, color: Colors.amber, size: 14),
      ],
    );
  }

  Future<void> _showAddToCollectionDialog(Verse verse) async {
    final collections =
        (await DatabaseService.db.watchAllCollections().first).toList();
    if (!mounted) return;

    final memberIds = await DatabaseService.db.getVerseCollectionIds(verse.id);
    if (!mounted) return;
    final selected = memberIds.toSet();

    Color parseHex(String hex) {
      final c = hex.replaceAll('#', '');
      if (c.length == 6) {
        final v = int.tryParse(c, radix: 16);
        if (v != null) return Color(0xFF000000 | v);
      }
      return const Color(0xFF4E342E);
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Collections'),
          content: SizedBox(
            width: double.maxFinite,
            child: collections.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                        'Aucune collection. Créez-en une avec le bouton « + ».'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: collections.length,
                    itemBuilder: (_, i) {
                      final col = collections[i];
                      final isIn = selected.contains(col.id);
                      return CheckboxListTile(
                        value: isIn,
                        title: Text(col.name),
                        secondary: CircleAvatar(
                          radius: 12,
                          backgroundColor: parseHex(col.colorHex),
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) async {
                          if (v == true) {
                            await DatabaseService.db
                                .addVerseToCollection(col.id, verse.id);
                            setDialogState(() => selected.add(col.id));
                          } else {
                            await DatabaseService.db
                                .removeVerseFromCollection(col.id, verse.id);
                            setDialogState(() => selected.remove(col.id));
                          }
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle'),
              onPressed: () async {
                final created = await _showCreateCollectionDialog();
                if (created != null) {
                  await DatabaseService.db
                      .addVerseToCollection(created, verse.id);
                  // Recharger la liste après création
                  final fresh =
                      await DatabaseService.db.watchAllCollections().first;
                  setDialogState(() {
                    collections
                      ..clear()
                      ..addAll(fresh);
                    selected.add(created);
                  });
                }
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _showCreateCollectionDialog() async {
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

    Color parseHex(String hex) {
      final c = hex.replaceAll('#', '');
      final v = int.tryParse(c, radix: 16);
      return v != null ? Color(0xFF000000 | v) : const Color(0xFF4E342E);
    }

    return showDialog<int>(
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
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: colors.map((c) {
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
                          color: parseHex(c.$1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade400,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
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
                if (name.isEmpty) return;
                final id = await DatabaseService.db
                    .insertCollection(name, selectedHex);
                if (ctx.mounted) Navigator.pop(ctx, id);
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLinkToPrayerDialog(Verse verse) async {
    final prayers = await DatabaseService.db
        .select(DatabaseService.db.prayers)
        .get();

    if (!mounted) return;

    if (prayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Aucune prière trouvée. Créez d\'abord une prière dans le carnet.')),
      );
      return;
    }

    final ref = '${verse.book} ${verse.chapter}:${verse.verse}';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lier à une prière'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: prayers.length,
            itemBuilder: (_, i) {
              final prayer = prayers[i];
              return ListTile(
                title: Text(prayer.title),
                subtitle: prayer.linkedVerseRef != null
                    ? Text('Lié à : ${prayer.linkedVerseRef}',
                        style: const TextStyle(fontSize: 11))
                    : null,
                onTap: () async {
                  await DatabaseService.db.updatePrayer(prayer.copyWith(
                    linkedVerseRef: Value(ref),
                    linkedVerseText: Value(verse.textContent),
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Verset lié à « ${prayer.title} »')),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showGoToVerseDialog() {
    final controller = TextEditingController();

    void confirm(BuildContext ctx) {
      final n = int.tryParse(controller.text.trim());
      if (n != null && n >= 1 && n <= _chapterVerses.length) {
        _scrollToVerse(n);
        Navigator.pop(ctx);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aller au verset'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Numéro de verset (1–${_chapterVerses.length})',
          ),
          onSubmitted: (_) => confirm(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => confirm(ctx),
            child: const Text('Aller'),
          ),
        ],
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
            // Theme override : supprime hover/highlight/focus persistants sur
            // les DropdownButton (le focus reste après sélection sur Flutter Web).
            Theme(
              data: Theme.of(context).copyWith(
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      // Défense : pendant la transition (didUpdateWidget vient
                      // d'installer un nouveau livre mais _books pas encore mis
                      // à jour), évite l'assertion "value not in items".
                      value: _books.contains(selectedBook) ? selectedBook : null,
                      isExpanded: true,
                      items: _books
                          .map((b) =>
                              DropdownMenuItem(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          FocusScope.of(context).unfocus();
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
                      // Défense : selectedChapter peut être pour le nouveau
                      // livre alors que _chapters contient encore ceux de
                      // l'ancien (rebuild entre didUpdateWidget et fin du
                      // chargement async).
                      value: _chapters.contains(selectedChapter)
                          ? selectedChapter
                          : null,
                      isExpanded: true,
                      items: _chapters
                          .map((ch) => DropdownMenuItem(
                              value: ch, child: Text('Ch. $ch')))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          FocusScope.of(context).unfocus();
                          setState(() => selectedChapter = v);
                          _loadAndWatchVersesForChapter(selectedBook!, v);
                          _subscribeToChapterReadStatus(selectedBook!, v);
                          widget.onTitleChange
                              ?.call('$selectedBook $v');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            // ── Barre Lu + mode immersif + audio ──
            Row(
              children: [
                const Text('Lu'),
                Switch(
                  value: _isCurrentChapterRead,
                  onChanged: (_) => DatabaseService.toggleChapterReadStatus(
                      selectedBook!, int.parse(selectedChapter!)),
                ),
                const Spacer(),
                if (_chapterVerses.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.pin),
                    tooltip: 'Aller au verset…',
                    onPressed: _showGoToVerseDialog,
                  ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  tooltip: 'Mode lecture immersif',
                  onPressed: selectedBook != null && selectedChapter != null
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => ImmersiveLecturePage(
                                initialBook: selectedBook!,
                                initialChapter: selectedChapter!,
                                allBooks: _books,
                              ),
                            ),
                          )
                      : null,
                ),
                _AudioPlayerBar(tts: _tts, verses: _chapterVerses),
              ],
            ),
            // ── Liste des versets ──
            Expanded(
              child: AnimatedOpacity(
                opacity: _contentOpacity,
                duration: const Duration(milliseconds: 220),
                child: ListView(
                  controller: _scrollController,
                  children: [
                    for (int index = 0; index < _chapterVerses.length; index++)
                      _buildVerseItem(context, index),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _VerseAction {
  note,
  favorite,
  collection,
  share,
  shareImage,
  concordance,
  linkPrayer,
}

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
        if (isActive)
          PopupMenuButton<double>(
            tooltip: 'Vitesse',
            initialValue: tts.speed,
            icon: Text('${tts.speed}×',
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold)),
            onSelected: (v) => tts.setSpeed(v),
            itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                .map((v) =>
                    PopupMenuItem(value: v, child: Text('$v×')))
                .toList(),
          ),
        if (isActive)
          IconButton(
            icon: const Icon(Icons.skip_previous),
            color: color,
            tooltip: 'Verset précédent',
            onPressed: tts.skipPrevious,
          ),
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
        if (isActive)
          IconButton(
            icon: const Icon(Icons.skip_next),
            color: color,
            tooltip: 'Verset suivant',
            onPressed: tts.skipNext,
          ),
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
