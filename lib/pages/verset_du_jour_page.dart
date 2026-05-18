// lib/pages/verset_du_jour_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/featured_verses.dart';
import '../utils/note_colors.dart';
import '../widgets/note_color_picker.dart';
import '../widgets/share_verse_image_dialog.dart';

class VersetDuJourPage extends StatefulWidget {
  final void Function(String book, String chapter, [int verse])? onVerseTap;

  const VersetDuJourPage({super.key, this.onVerseTap});

  @override
  State<VersetDuJourPage> createState() => _VersetDuJourPageState();
}

class _VersetDuJourPageState extends State<VersetDuJourPage> {
  Verse? _currentVerse;
  StreamSubscription? _verseWatcher;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateVerse();
    // Marque le verset du jour comme lu dès l'ouverture de la page
    // (annule également le rappel programmé à 12h00 sur mobile/desktop).
    NotificationService.markVerseReadToday();
  }

  @override
  void dispose() {
    _verseWatcher?.cancel();
    super.dispose();
  }

  Future<void> _loadOrGenerateVerse() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final keyDate = '${today.year}-${today.month}-${today.day}';

    String? storedBook = prefs.getString('verset_book');
    String? storedChapter = prefs.getString('verset_chapter');
    String? storedVerseNum = prefs.getString('verset_verse');
    String? storedDate = prefs.getString('verset_date');

    if (storedDate != keyDate ||
        storedBook == null ||
        storedChapter == null ||
        storedVerseNum == null) {
      // Seed déterministe par jour (unique à la date calendaire)
      final seed = today.difference(DateTime(2024, 1, 1)).inDays;
      final totalSlots = kCuratedVerses.length + kExtraRandomSlots;
      final slot = seed % totalSlots;

      String book;
      int chapter;
      int verse;

      if (slot < kCuratedVerses.length) {
        // ── Verset curatée (~80 % des jours) ──
        final ref = kCuratedVerses[slot];
        book = ref.book;
        chapter = ref.chapter;
        verse = ref.verse;
      } else {
        // ── Tirage pondéré (~20 % des jours) ──
        final rng = Random(seed);
        final bibleData = await DatabaseService.getBibleData();

        // Construire le pool pondéré en filtrant les livres présents en DB
        final weightedBooks = <String>[];
        for (final entry in kBookWeights.entries) {
          if (bibleData.containsKey(entry.key)) {
            for (int i = 0; i < entry.value; i++) {
              weightedBooks.add(entry.key);
            }
          }
        }

        book = weightedBooks[rng.nextInt(weightedBooks.length)];
        final chaptersMap = bibleData[book] as Map<String, dynamic>;
        final chapters = chaptersMap.keys.toList();
        final chapterKey = chapters[rng.nextInt(chapters.length)];
        final versesMap = chaptersMap[chapterKey] as Map<String, dynamic>;
        final verseKeys = versesMap.keys.toList();
        chapter = int.parse(chapterKey);
        verse = int.parse(verseKeys[rng.nextInt(verseKeys.length)]);
      }

      await prefs.setString('verset_date', keyDate);
      await prefs.setString('verset_book', book);
      await prefs.setString('verset_chapter', chapter.toString());
      await prefs.setString('verset_verse', verse.toString());

      storedBook = book;
      storedChapter = chapter.toString();
      storedVerseNum = verse.toString();
    }

    _subscribeToVerse(
        storedBook, int.parse(storedChapter), int.parse(storedVerseNum));
  }

  void _subscribeToVerse(String book, int chapter, int verseNum) {
    _verseWatcher?.cancel();
    _verseWatcher = DatabaseService.watchSingleVerse(book, chapter, verseNum)
        .listen((verse) {
      if (mounted) setState(() => _currentVerse = verse);
    });
  }

  void _showNoteDialog() {
    if (_currentVerse == null) return;
    final verse = _currentVerse!;
    final controller = TextEditingController(text: verse.noteText ?? '');
    String? selectedColor = verse.noteColor;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text("Note personnelle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(hintText: "Votre note..."),
              ),
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
    if (_currentVerse == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // ---- Carte gradient ----
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Text(
                      '${_currentVerse!.book}\u00a0${_currentVerse!.chapter}\u00a0:\u00a0${_currentVerse!.verse}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '\u201c${_currentVerse!.textContent}\u201d',
                      style: GoogleFonts.lora(
                        fontSize: 19,
                        color: Colors.white,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // ---- Note personnelle ----
              if (_currentVerse!.noteText != null && _currentVerse!.noteText!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: parseNoteColor(_currentVerse!.noteColor) ??
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentVerse!.noteText!,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 28),
              // ---- Actions ----
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: _currentVerse!.isFavorite ? Icons.star : Icons.star_outline,
                    label: _currentVerse!.isFavorite ? 'Favori' : 'Ajouter',
                    color: _currentVerse!.isFavorite ? Colors.amber : null,
                    onTap: () => DatabaseService.toggleFavorite(_currentVerse!),
                  ),
                  _ActionButton(
                    icon: Icons.edit_note,
                    label: 'Note',
                    onTap: _showNoteDialog,
                  ),
                  _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'Partager',
                    onTap: () => SharePlus.instance.share(ShareParams(
                      text: '${_currentVerse!.book} ${_currentVerse!.chapter}:${_currentVerse!.verse}\n\u201c${_currentVerse!.textContent}\u201d',
                    )),
                  ),
                  _ActionButton(
                    icon: Icons.image_outlined,
                    label: 'Image',
                    onTap: () =>
                        showShareVerseImageDialog(context, _currentVerse!),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => widget.onVerseTap?.call(
                    _currentVerse!.book, _currentVerse!.chapter.toString(), _currentVerse!.verse),
                icon: const Icon(Icons.menu_book),
                label: const Text('Lire le chapitre complet'),
              ),
            ],
          ),
        ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clr = color ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Icon(icon, size: 28, color: clr),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: clr, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
