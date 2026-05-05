// lib/pages/verset_du_jour_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database.dart';
import '../services/database_service.dart';

class VersetDuJourPage extends StatefulWidget {
  final void Function(String book, String chapter)? onVerseTap;

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
  }

  @override
  void dispose() {
    _verseWatcher?.cancel();
    super.dispose();
  }

  Future<void> _loadOrGenerateVerse() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final keyDate = "${today.year}-${today.month}-${today.day}";
    
    String? storedBook = prefs.getString('verset_book');
    String? storedChapter = prefs.getString('verset_chapter');
    String? storedVerseNum = prefs.getString('verset_verse');
    String? storedDate = prefs.getString('verset_date');

    if (storedDate != keyDate || storedBook == null || storedChapter == null || storedVerseNum == null) {
      // Générer un nouveau verset du jour
      final String data = await rootBundle.loadString('assets/bible.json');
      final Map<String, dynamic> bibleData = json.decode(data);
      
      final books = bibleData.keys.toList();
      final randomBook = books[Random().nextInt(books.length)];
      final chaptersMap = bibleData[randomBook] as Map<String, dynamic>;
      final chaptersKeys = chaptersMap.keys.toList();
      final randomChapterKey = chaptersKeys[Random().nextInt(chaptersKeys.length)];
      final versesMap = chaptersMap[randomChapterKey] as Map<String, dynamic>;
      final versesKeys = versesMap.keys.toList();
      final randomVerseKey = versesKeys[Random().nextInt(versesKeys.length)];

      await prefs.setString('verset_date', keyDate);
      await prefs.setString('verset_book', randomBook);
      await prefs.setString('verset_chapter', randomChapterKey);
      await prefs.setString('verset_verse', randomVerseKey);
      
      storedBook = randomBook;
      storedChapter = randomChapterKey;
      storedVerseNum = randomVerseKey;
    }

    _subscribeToVerse(storedBook, int.parse(storedChapter), int.parse(storedVerseNum));
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
    final controller = TextEditingController(text: _currentVerse!.noteText ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Note personnelle"),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: "Votre note..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              await DatabaseService.updateVerseNote(_currentVerse!, controller.text, null);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentVerse == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${_currentVerse!.book} ${_currentVerse!.chapter}:${_currentVerse!.verse}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "“${_currentVerse!.textContent}”",
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (_currentVerse!.noteText != null && _currentVerse!.noteText!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Text(
                  _currentVerse!.noteText!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 36,
                  icon: Icon(
                    _currentVerse!.isFavorite ? Icons.star : Icons.star_border,
                    color: _currentVerse!.isFavorite ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () => DatabaseService.toggleFavorite(_currentVerse!),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note, size: 36),
                  onPressed: _showNoteDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 36),
                  onPressed: () => SharePlus.instance.share(ShareParams(text: "${_currentVerse!.book} ${_currentVerse!.chapter}:${_currentVerse!.verse}\n\"${_currentVerse!.textContent}\"")),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => widget.onVerseTap?.call(_currentVerse!.book, _currentVerse!.chapter.toString()),
              icon: const Icon(Icons.menu_book),
              label: const Text("Lire le chapitre complet"),
            ),
          ],
        ),
      ),
    );
  }
}
