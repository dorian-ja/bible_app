// lib/services/isar_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/verse.dart';

class IsarService {
  static Isar? _isar;

  static Future<Isar> get db async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    return await getIsarInstance();
  }

  static Future<void> resetAllReadStatus() async {
    final isar = await db;
    final List<Verse> allVerses = await isar.verses.where().findAll();
    if (allVerses.isNotEmpty) {
      await isar.writeTxn(() async {
        for (var verse in allVerses) {
          verse.isChapterRead = false;
        }
        await isar.verses.putAll(allVerses);
      });
    }
  }

  static Future<Isar> getIsarInstance() async {
    if (_isar != null && _isar!.isOpen) return _isar!;

    String dirPath = ''; 
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      dirPath = dir.path;
    }

    _isar = await Isar.open(
      [VerseSchema],
      directory: dirPath,
      name: "bibleIsar",
      inspector: !kIsWeb, // Désactiver l'inspecteur sur le Web
    );
    
    return _isar!;
  }

  static Future<bool> isBibleImported() async {
    final isar = await db;
    final count = await isar.verses.count();
    return count > 0;
  }

  static Future<void> importBibleFromJson({VoidCallback? onProgress}) async {
    final isar = await db;
    if (await isBibleImported()) {
      onProgress?.call();
      return;
    }
    try {
      final String data = await rootBundle.loadString('assets/bible.json');
      final Map<String, dynamic> bibleMap = json.decode(data);
      final List<Verse> versesToInsert = [];
      for (final bookKey in bibleMap.keys) {
        final chapters = bibleMap[bookKey] as Map<String, dynamic>;
        for (final chapterKey in chapters.keys) {
          final versesData = chapters[chapterKey] as Map<String, dynamic>;
          for (final verseNumKey in versesData.keys) {
            final verseText = versesData[verseNumKey];
            if (verseText is String) {
              int? chapterInt = int.tryParse(chapterKey);
              int? verseNumInt = int.tryParse(verseNumKey);
              if (chapterInt != null && verseNumInt != null) {
                versesToInsert.add(Verse(
                  book: bookKey, chapter: chapterInt, verse: verseNumInt,
                  text: verseText, isFavorite: false, isChapterRead: false,
                ));
              }
            }
          }
        }
      }
      if (versesToInsert.isNotEmpty) {
        await isar.writeTxn(() async => await isar.verses.putAll(versesToInsert));
      }
    } catch (e) { debugPrint("Erreur import: $e"); }
    finally { onProgress?.call(); }
  }

  Future<List<String>> getBooks() async {
    final isar = await db;
    return await isar.verses.where().distinctByBook().bookProperty().findAll();
  }

  Future<List<String>> getChaptersForBook(String bookName) async {
    final isar = await db;
    final chapterNumbers = await isar.verses.filter().bookEqualTo(bookName).distinctByChapter().chapterProperty().findAll();
    chapterNumbers.sort();
    return chapterNumbers.map((num) => num.toString()).toList();
  }

  Future<List<Verse>> getVerses(String bookName, int chapterNumber) async {
    final isar = await db;
    return await isar.verses.filter().bookEqualTo(bookName).and().chapterEqualTo(chapterNumber).sortByVerse().findAll();
  }

  Future<Verse?> getSingleVerse(String bookName, int chapterNumber, int verseNum) async {
    final isar = await db;
    return await isar.verses.filter().bookEqualTo(bookName).and().chapterEqualTo(chapterNumber).and().verseEqualTo(verseNum).findFirst();
  }

  Future<List<Verse>> getFavoriteVerses() async {
    final isar = await db;
    return await isar.verses.filter().isFavoriteEqualTo(true).findAll();
  }

  Future<Verse?> toggleFavorite(Verse verseToToggle) async {
    final isar = await db;
    final Verse? currentVerse = await isar.verses.get(verseToToggle.id);
    if (currentVerse != null) {
      currentVerse.isFavorite = !currentVerse.isFavorite;
      await isar.writeTxn(() async => await isar.verses.put(currentVerse));
      return currentVerse;
    }
    return null;
  }

  Future<Verse?> updateVerseNote(Verse verseToUpdate, String? newNoteText, String? newNoteColorHex) async {
    final isar = await db;
    final Verse? currentVerse = await isar.verses.get(verseToUpdate.id);
    if (currentVerse != null) {
      currentVerse.noteText = newNoteText;
      currentVerse.noteColor = newNoteColorHex;
      await isar.writeTxn(() async => await isar.verses.put(currentVerse));
      return currentVerse;
    }
    return null;
  }

  Future<List<Verse>> searchVersesByKeyword(String keyword) async {
    final isar = await db;
    if (keyword.trim().isEmpty) return [];
    return await isar.verses.filter().textContains(keyword, caseSensitive: false).findAll();
  }

  static Future<bool> isChapterRead(String book, int chapter) async {
    final isar = await db;
    final countUnread = await isar.verses.filter().bookEqualTo(book).chapterEqualTo(chapter).isChapterReadEqualTo(false).count();
    if (countUnread == 0) {
      final total = await isar.verses.filter().bookEqualTo(book).chapterEqualTo(chapter).count();
      return total > 0;
    }
    return false;
  }

  static Future<void> toggleChapterReadStatus(String book, int chapter) async {
    final isar = await db;
    final currentStatus = await isChapterRead(book, chapter);
    final newReadStatus = !currentStatus;
    final List<Verse> versesToUpdate = await isar.verses.filter().bookEqualTo(book).chapterEqualTo(chapter).findAll();
    if (versesToUpdate.isNotEmpty) {
      await isar.writeTxn(() async {
        for (var verse in versesToUpdate) { verse.isChapterRead = newReadStatus; }
        await isar.verses.putAll(versesToUpdate);
      });
    }
  }

  static Stream<bool> watchChapterReadStatus(String book, int chapter) async* {
    final isar = await db;
    yield await isChapterRead(book, chapter);
    final query = isar.verses.filter().bookEqualTo(book).chapterEqualTo(chapter).build();
    await for (final _ in query.watchLazy(fireImmediately: false)) {
      yield await isChapterRead(book, chapter);
    }
  }

  static Future<Set<String>> getAllFullyReadChapterKeys() async {
    final isar = await db;
    final allVerses = await isar.verses.where().findAll();
    var chapterCounts = <String, Map<String, int>>{};
    for (var verse in allVerses) {
      final key = '${verse.book}|${verse.chapter}';
      chapterCounts.putIfAbsent(key, () => {'total': 0, 'read': 0});
      chapterCounts[key]!['total'] = chapterCounts[key]!['total']! + 1;
      if (verse.isChapterRead) { chapterCounts[key]!['read'] = chapterCounts[key]!['read']! + 1; }
    }
    Set<String> fullyReadKeys = {};
    chapterCounts.forEach((key, counts) {
      if (counts['total']! > 0 && counts['total'] == counts['read']) { fullyReadKeys.add(key); }
    });
    return fullyReadKeys;
  }

  static Stream<Set<String>> watchAllFullyReadChapterKeys() async* {
    final isar = await db;
    yield await getAllFullyReadChapterKeys();
    await for (final _ in isar.verses.watchLazy(fireImmediately: false)) {
      yield await getAllFullyReadChapterKeys();
    }
  }
}
