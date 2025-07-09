import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/verse.dart';

class IsarService {
  static Isar? _isar;

  static Future<Isar> getIsarInstance() async {
    if (_isar != null) return _isar!;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([VerseSchema], directory: dir.path);
    return _isar!;
  }

  static Future<void> importBibleFromJson() async {
    final isar = await getIsarInstance();
    final existing = await isar.verses.where().findFirst();
    if (existing != null) return; // déjà importé

    final String data = await rootBundle.loadString('assets/bible.json');
    final Map<String, dynamic> bibleMap = json.decode(data);
    final List<Verse> versesToInsert = [];

    for (final book in bibleMap.keys) {
      final chapters = bibleMap[book] as Map<String, dynamic>;
      for (final chapter in chapters.keys) {
        final verses = chapters[chapter] as Map<String, dynamic>;
        for (final verseNum in verses.keys) {
          final verseText = verses[verseNum];
          if (verseText is String) {
            versesToInsert.add(
              Verse()
                ..book = book
                ..chapter = int.parse(chapter)
                ..verse = int.parse(verseNum)
                ..text = verseText,
            );
          }
        }
      }
    }

    await isar.writeTxn(() async {
      await isar.verses.putAll(versesToInsert);
    });

    print(
      "✅ Importation des versets terminée : ${versesToInsert.length} versets insérés.",
    );
  }
}
