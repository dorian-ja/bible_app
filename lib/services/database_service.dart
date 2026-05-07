import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../database/database.dart';
import '../utils/canonical_books.dart';

class DatabaseService {
  static AppDatabase? _db;
  static Map<String, dynamic>? _bibleCache;

  static AppDatabase get db {
    _db ??= AppDatabase();
    return _db!;
  }

  /// Retourne la Bible complète depuis le cache mémoire (chargé une seule fois).
  static Future<Map<String, dynamic>> getBibleData() async {
    if (_bibleCache != null) return _bibleCache!;
    final String raw = await rootBundle.loadString('assets/bible.json');
    _bibleCache = json.decode(raw) as Map<String, dynamic>;
    return _bibleCache!;
  }

  static Future<void> resetAllReadStatus() async {
    await db.update(db.verses).write(const VersesCompanion(isChapterRead: Value(false)));
  }

  static Future<bool> isBibleImported() async {
    final count = await db.verses.count().getSingle();
    return count > 0;
  }

  static Future<void> importBibleFromJson({VoidCallback? onProgress}) async {
    if (await isBibleImported()) {
      onProgress?.call();
      return;
    }

    try {
      final Map<String, dynamic> bibleMap = await getBibleData();
      final List<VersesCompanion> versesToInsert = [];

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
                versesToInsert.add(VersesCompanion.insert(
                  book: bookKey,
                  chapter: chapterInt,
                  verse: verseNumInt,
                  textContent: verseText,
                  isFavorite: const Value(false),
                  isChapterRead: const Value(false),
                ));
              }
            }
          }
        }
      }

      if (versesToInsert.isNotEmpty) {
        await db.batch((batch) {
          batch.insertAll(db.verses, versesToInsert);
        });
      }
    } catch (e) {
      debugPrint("Erreur import Drift: $e");
    } finally {
      onProgress?.call();
    }
  }

  static Future<List<String>> getBooks() async {
    final query = db.selectOnly(db.verses, distinct: true)..addColumns([db.verses.book]);
    final rows = await query.get();
    final books = rows.map((row) => row.read(db.verses.book)!).toList();
    return sortBooksCanonically(books);
  }

  static Future<List<String>> getChaptersForBook(String bookName) async {
    final query = db.selectOnly(db.verses, distinct: true)
      ..addColumns([db.verses.chapter])
      ..where(db.verses.book.equals(bookName));
    final chapters = await query.map((row) => row.read(db.verses.chapter)!).get();
    chapters.sort();
    return chapters.map((e) => e.toString()).toList();
  }

  static Future<List<Verse>> getVerses(String bookName, int chapterNumber) async {
    return (db.select(db.verses)
          ..where((t) => t.book.equals(bookName) & t.chapter.equals(chapterNumber))
          ..orderBy([(t) => OrderingTerm(expression: t.verse)]))
        .get();
  }

  static Future<Verse?> getSingleVerse(String bookName, int chapterNumber, int verseNum) async {
    return (db.select(db.verses)
          ..where((t) => t.book.equals(bookName) & t.chapter.equals(chapterNumber) & t.verse.equals(verseNum)))
        .getSingleOrNull();
  }

  static Future<List<Verse>> getFavoriteVerses() async {
    return (db.select(db.verses)..where((t) => t.isFavorite.equals(true))).get();
  }

  static Future<void> toggleFavorite(Verse verseToToggle) async {
    await (db.update(db.verses)..where((t) => t.id.equals(verseToToggle.id)))
        .write(VersesCompanion(isFavorite: Value(!verseToToggle.isFavorite)));
  }

  static Future<void> updateVerseNote(Verse verseToUpdate, String? newNoteText, String? newNoteColorHex) async {
    await (db.update(db.verses)..where((t) => t.id.equals(verseToUpdate.id)))
        .write(VersesCompanion(
      noteText: Value(newNoteText),
      noteColor: Value(newNoteColorHex),
    ));
  }

  static Future<List<Verse>> searchVersesByKeyword(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return [];
    final normalizedKeyword = removeDiacritics(trimmed.toLowerCase());
    final allVerses = await db.select(db.verses).get();
    return allVerses
        .where((v) => removeDiacritics(v.textContent.toLowerCase()).contains(normalizedKeyword))
        .toList();
  }

  static Future<bool> isChapterRead(String book, int chapter) async {
    final unreadRows = await (db.select(db.verses)
          ..where((t) => t.book.equals(book) & t.chapter.equals(chapter) & t.isChapterRead.equals(false)))
        .get();

    if (unreadRows.isEmpty) {
      final allRows = await (db.select(db.verses)
            ..where((t) => t.book.equals(book) & t.chapter.equals(chapter)))
          .get();
      return allRows.isNotEmpty;
    }
    return false;
  }

  static Future<void> toggleChapterReadStatus(String book, int chapter) async {
    final currentStatus = await isChapterRead(book, chapter);
    final newReadStatus = !currentStatus;
    await (db.update(db.verses)..where((t) => t.book.equals(book) & t.chapter.equals(chapter)))
        .write(VersesCompanion(isChapterRead: Value(newReadStatus)));
  }

  static Stream<bool> watchChapterReadStatus(String book, int chapter) {
    return (db.select(db.verses)..where((t) => t.book.equals(book) & t.chapter.equals(chapter)))
        .watch()
        .map((verses) {
          if (verses.isEmpty) return false;
          return verses.every((v) => v.isChapterRead);
        });
  }

  static Stream<List<Verse>> watchVerses(String bookName, int chapterNumber) {
    return (db.select(db.verses)
          ..where((t) => t.book.equals(bookName) & t.chapter.equals(chapterNumber))
          ..orderBy([(t) => OrderingTerm(expression: t.verse)]))
        .watch();
  }

  static Stream<Verse?> watchSingleVerse(String book, int chapter, int verseNum) {
    return (db.select(db.verses)
          ..where((t) => t.book.equals(book) & t.chapter.equals(chapter) & t.verse.equals(verseNum)))
        .watchSingleOrNull();
  }

  static Future<Set<String>> getAllFullyReadChapterKeys() async {
    final verses = await db.select(db.verses).get();
    var chapterCounts = <String, Map<String, int>>{};

    for (var verse in verses) {
      final key = '${verse.book}|${verse.chapter}';
      chapterCounts.putIfAbsent(key, () => {'total': 0, 'read': 0});
      chapterCounts[key]!['total'] = chapterCounts[key]!['total']! + 1;
      if (verse.isChapterRead) {
        chapterCounts[key]!['read'] = chapterCounts[key]!['read']! + 1;
      }
    }

    Set<String> fullyReadKeys = {};
    chapterCounts.forEach((key, counts) {
      if (counts['total']! > 0 && counts['total'] == counts['read']) {
        fullyReadKeys.add(key);
      }
    });
    return fullyReadKeys;
  }

  static Stream<Set<String>> watchAllFullyReadChapterKeys() {
    return db.select(db.verses).watch().map((verses) {
      var chapterCounts = <String, Map<String, int>>{};
      for (var verse in verses) {
        final key = '${verse.book}|${verse.chapter}';
        chapterCounts.putIfAbsent(key, () => {'total': 0, 'read': 0});
        chapterCounts[key]!['total'] = chapterCounts[key]!['total']! + 1;
        if (verse.isChapterRead) {
          chapterCounts[key]!['read'] = chapterCounts[key]!['read']! + 1;
        }
      }
      Set<String> fullyReadKeys = {};
      chapterCounts.forEach((key, counts) {
        if (counts['total']! > 0 && counts['total'] == counts['read']) {
          fullyReadKeys.add(key);
        }
      });
      return fullyReadKeys;
    });
  }

  /// Marque tous les chapitres d'un livre comme lus ou non lus.
  /// Si tous les chapitres sont déjà lus, les passe à non lus (toggle).
  static Future<void> toggleBookReadStatus(String book) async {
    final verses = await (db.select(db.verses)..where((t) => t.book.equals(book))).get();
    if (verses.isEmpty) return;
    final allRead = verses.every((v) => v.isChapterRead);
    await (db.update(db.verses)..where((t) => t.book.equals(book)))
        .write(VersesCompanion(isChapterRead: Value(!allRead)));
  }
}
