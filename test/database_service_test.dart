import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_app/database/database.dart';
import 'package:bible_app/utils/canonical_books.dart';
import 'package:bible_app/utils/note_colors.dart';

AppDatabase _openTestDatabase() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() => db = _openTestDatabase());
  tearDown(() async => db.close());

  // ------------------------------------------------------------------ //
  //  1. Insertion & comptage
  // ------------------------------------------------------------------ //
  group('Insertions', () {
    test('base vide au départ', () async {
      final count = await db.verses.count().getSingle();
      expect(count, 0);
    });

    test('verset inséré correctement', () async {
      await db.into(db.verses).insert(VersesCompanion.insert(
        book: 'Jean', chapter: 3, verse: 16, textContent: 'Car Dieu a tant aimé le monde...',
      ));
      final count = await db.verses.count().getSingle();
      expect(count, 1);
    });
  });

  // ------------------------------------------------------------------ //
  //  2. Favori
  // ------------------------------------------------------------------ //
  group('Favori', () {
    test('passe de false à true puis de true à false', () async {
      final id = await db.into(db.verses).insert(VersesCompanion.insert(
        book: 'Jean', chapter: 3, verse: 16, textContent: 'texte',
      ));

      var verse = await (db.select(db.verses)..where((t) => t.id.equals(id))).getSingle();
      expect(verse.isFavorite, false);

      await (db.update(db.verses)..where((t) => t.id.equals(id)))
          .write(VersesCompanion(isFavorite: Value(!verse.isFavorite)));
      verse = await (db.select(db.verses)..where((t) => t.id.equals(id))).getSingle();
      expect(verse.isFavorite, true);

      await (db.update(db.verses)..where((t) => t.id.equals(id)))
          .write(VersesCompanion(isFavorite: Value(!verse.isFavorite)));
      verse = await (db.select(db.verses)..where((t) => t.id.equals(id))).getSingle();
      expect(verse.isFavorite, false);
    });
  });

  // ------------------------------------------------------------------ //
  //  3. Notes
  // ------------------------------------------------------------------ //
  group('Note', () {
    test('enregistre texte et couleur', () async {
      final id = await db.into(db.verses).insert(VersesCompanion.insert(
        book: 'Jean', chapter: 3, verse: 16, textContent: 'texte',
      ));
      await (db.update(db.verses)..where((t) => t.id.equals(id)))
          .write(const VersesCompanion(noteText: Value('Ma note'), noteColor: Value('#FFF59D')));

      final verse = await (db.select(db.verses)..where((t) => t.id.equals(id))).getSingle();
      expect(verse.noteText, 'Ma note');
      expect(verse.noteColor, '#FFF59D');
    });

    test('efface la note en passant null', () async {
      final id = await db.into(db.verses).insert(VersesCompanion.insert(
        book: 'Jean', chapter: 3, verse: 16, textContent: 'texte',
        noteText: const Value('ancienne note'),
      ));
      await (db.update(db.verses)..where((t) => t.id.equals(id)))
          .write(const VersesCompanion(noteText: Value(null), noteColor: Value(null)));

      final verse = await (db.select(db.verses)..where((t) => t.id.equals(id))).getSingle();
      expect(verse.noteText, isNull);
    });
  });

  // ------------------------------------------------------------------ //
  //  4. Statut de lecture
  // ------------------------------------------------------------------ //
  group('Lecture', () {
    Future<void> insert(int verse, {bool read = false}) =>
        db.into(db.verses).insert(VersesCompanion.insert(
          book: 'Genèse', chapter: 1, verse: verse, textContent: 'v$verse',
          isChapterRead: Value(read),
        ));

    test('chapitre non lu si au moins un verset non lu', () async {
      await insert(1, read: true);
      await insert(2, read: false);
      final unread = await (db.select(db.verses)
            ..where((t) => t.book.equals('Genèse') & t.chapter.equals(1) & t.isChapterRead.equals(false)))
          .get();
      expect(unread, isNotEmpty);
    });

    test('chapitre lu si tous les versets sont lus', () async {
      await insert(1, read: true);
      await insert(2, read: true);
      final unread = await (db.select(db.verses)
            ..where((t) => t.book.equals('Genèse') & t.chapter.equals(1) & t.isChapterRead.equals(false)))
          .get();
      expect(unread, isEmpty);
    });
  });

  // ------------------------------------------------------------------ //
  //  5. sortBooksCanonically
  // ------------------------------------------------------------------ //
  group('sortBooksCanonically', () {
    test('ordre Genèse < Jean < Apocalypse', () {
      final sorted = sortBooksCanonically(['Apocalypse', 'Jean', 'Genèse']);
      expect(sorted.indexOf('Genèse'), lessThan(sorted.indexOf('Jean')));
      expect(sorted.indexOf('Jean'), lessThan(sorted.indexOf('Apocalypse')));
    });

    test('livre inconnu placé à la fin', () {
      final sorted = sortBooksCanonically(['Inconnu', 'Jean']);
      expect(sorted.last, 'Inconnu');
    });
  });

  // ------------------------------------------------------------------ //
  //  6. parseNoteColor
  // ------------------------------------------------------------------ //
  group('parseNoteColor', () {
    test('retourne null pour hex null', () => expect(parseNoteColor(null), isNull));
    test('retourne null pour chaîne vide', () => expect(parseNoteColor(''), isNull));
    test('retourne null pour hex invalide', () => expect(parseNoteColor('#ZZZ'), isNull));

    test('parse #FFF59D correctement', () {
      expect(parseNoteColor('#FFF59D'), const Color(0xFFFFF59D));
    });
  });
}
