// lib/models/verse.dart
import 'package:flutter/material.dart'; // Pour 'Color'
import 'package:isar/isar.dart';

part 'verse.g.dart'; // N'oubliez pas cette ligne et d'exécuter build_runner

@collection
class Verse {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String book;

  @Index()
  late int chapter;

  @Index()
  late int verse;

  @Index(type: IndexType.value, caseSensitive: false)
  late String text;

  @Index()
  bool isFavorite;

  String? noteText;
  String? noteColor;

  @Index() // Indexer ce champ peut être utile si vous voulez rapidement trouver tous les chapitres lus.
  bool isChapterRead; // <<< NOUVEAU CHAMP

  Verse({
    this.book = '',
    this.chapter = 0,
    this.verse = 0,
    this.text = '',
    this.isFavorite = false,
    this.noteText,
    this.noteColor,
    this.isChapterRead =
        false, // <<< AJOUTER AU CONSTRUCTEUR (avec valeur par défaut)
  });

  // Getter pour convertir la couleur hex en objet Color (votre code existant, inchangé)
  @ignore
  Color? get noteColorAsColor {
    if (noteColor == null || noteColor!.isEmpty) return null;
    try {
      final buffer = StringBuffer();
      if (noteColor!.length == 6 ||
          (noteColor!.length == 7 && noteColor!.startsWith('#'))) {
        buffer.write('ff');
      }
      buffer.write(noteColor!.replaceFirst('#', ''));
      if (buffer.toString().length == 8) {
        return Color(int.parse(buffer.toString(), radix: 16));
      } else if (buffer.toString().length == 6 &&
          !noteColor!.startsWith('#') &&
          noteColor!.length == 6) {
        return Color(int.parse('ff${buffer.toString()}', radix: 16));
      } else {
        print(
          "Erreur de format de noteColor après préparation: '${buffer.toString()}' pour l'original '${noteColor}'",
        );
        return null;
      }
    } catch (e) {
      print("Erreur de conversion de noteColor '$noteColor': $e");
      return null;
    }
  }

  // Optionnel: Composite index pour assurer l'unicité et optimiser les requêtes par livre/chapitre/verset
  // Si vous ne l'avez pas déjà et que vous voulez assurer qu'il n'y a qu'un seul verset 1 pour Jean chapitre 1.
  // @Index(composite: [
  //   CompositeIndex('book'),
  //   CompositeIndex('chapter'),
  //   CompositeIndex('verse')
  // ], unique: true, replace: true) // `replace: true` signifie que si vous essayez d'insérer un doublon, il sera remplacé.
  // List<String> get bookChapterVerseKey => [book, chapter.toString(), verse.toString()];

  @override
  String toString() {
    // Optionnel, mais utile pour le débogage
    return 'Verse{id: $id, book: $book, ch: $chapter, v: $verse, fav: $isFavorite, read: $isChapterRead, text: ${text.substring(0, (text.length > 20 ? 20 : text.length))}...}';
  }
}
