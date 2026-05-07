/// Référence à un verset précis (noms exacts de bible.json).
class VerseRef {
  final String book;
  final int chapter;
  final int verse;
  const VerseRef(this.book, this.chapter, this.verse);
}

/// ~160 versets phares, équilibrés AT/NT, choisis pour leur pertinence
/// spirituelle et leur clarté hors contexte.
/// Ordre : AT → NT, puis Épîtres → Apocalypse.
const List<VerseRef> kCuratedVerses = [
  // ── Genèse ──
  VerseRef('Genèse', 1, 1),
  VerseRef('Genèse', 1, 27),
  VerseRef('Genèse', 15, 6),
  VerseRef('Genèse', 28, 15),
  VerseRef('Genèse', 50, 20),

  // ── Exode ──
  VerseRef('Exode', 14, 14),
  VerseRef('Exode', 15, 2),
  VerseRef('Exode', 33, 14),

  // ── Deutéronome ──
  VerseRef('Deutéronome', 6, 5),
  VerseRef('Deutéronome', 31, 6),
  VerseRef('Deutéronome', 31, 8),
  VerseRef('Deutéronome', 33, 27),

  // ── Josué ──
  VerseRef('Josué', 1, 9),
  VerseRef('Josué', 24, 15),

  // ── Ruth ──
  VerseRef('Ruth', 1, 16),

  // ── 1 Samuel ──
  VerseRef('1 Samuel', 16, 7),

  // ── 2 Samuel ──
  VerseRef('2 Samuel', 22, 31),

  // ── 1 Rois ──
  VerseRef('1 Rois', 19, 12),

  // ── Job ──
  VerseRef('Job', 19, 25),
  VerseRef('Job', 42, 2),

  // ── Psaume ──
  VerseRef('Psaume', 1, 1),
  VerseRef('Psaume', 16, 8),
  VerseRef('Psaume', 16, 11),
  VerseRef('Psaume', 18, 2),
  VerseRef('Psaume', 19, 1),
  VerseRef('Psaume', 23, 1),
  VerseRef('Psaume', 23, 4),
  VerseRef('Psaume', 27, 1),
  VerseRef('Psaume', 27, 14),
  VerseRef('Psaume', 32, 8),
  VerseRef('Psaume', 34, 8),
  VerseRef('Psaume', 34, 18),
  VerseRef('Psaume', 37, 4),
  VerseRef('Psaume', 37, 5),
  VerseRef('Psaume', 46, 1),
  VerseRef('Psaume', 46, 10),
  VerseRef('Psaume', 51, 10),
  VerseRef('Psaume', 56, 3),
  VerseRef('Psaume', 62, 5),
  VerseRef('Psaume', 63, 1),
  VerseRef('Psaume', 91, 1),
  VerseRef('Psaume', 91, 11),
  VerseRef('Psaume', 100, 4),
  VerseRef('Psaume', 103, 1),
  VerseRef('Psaume', 103, 12),
  VerseRef('Psaume', 103, 13),
  VerseRef('Psaume', 107, 1),
  VerseRef('Psaume', 118, 24),
  VerseRef('Psaume', 119, 105),
  VerseRef('Psaume', 121, 1),
  VerseRef('Psaume', 121, 2),
  VerseRef('Psaume', 139, 14),
  VerseRef('Psaume', 145, 18),
  VerseRef('Psaume', 147, 3),

  // ── Proverbes ──
  VerseRef('Proverbes', 3, 5),
  VerseRef('Proverbes', 3, 6),
  VerseRef('Proverbes', 4, 23),
  VerseRef('Proverbes', 11, 14),
  VerseRef('Proverbes', 16, 3),
  VerseRef('Proverbes', 16, 9),
  VerseRef('Proverbes', 17, 17),
  VerseRef('Proverbes', 18, 24),
  VerseRef('Proverbes', 19, 21),
  VerseRef('Proverbes', 31, 25),

  // ── Ecclésiaste ──
  VerseRef('Ecclésiaste', 3, 1),
  VerseRef('Ecclésiaste', 12, 13),

  // ── Ésaïe ──
  VerseRef('Ésaïe', 26, 3),
  VerseRef('Ésaïe', 40, 29),
  VerseRef('Ésaïe', 40, 31),
  VerseRef('Ésaïe', 41, 10),
  VerseRef('Ésaïe', 41, 13),
  VerseRef('Ésaïe', 43, 1),
  VerseRef('Ésaïe', 43, 2),
  VerseRef('Ésaïe', 43, 19),
  VerseRef('Ésaïe', 53, 5),
  VerseRef('Ésaïe', 55, 8),
  VerseRef('Ésaïe', 55, 9),

  // ── Jérémie ──
  VerseRef('Jérémie', 29, 11),
  VerseRef('Jérémie', 29, 13),
  VerseRef('Jérémie', 31, 3),
  VerseRef('Jérémie', 33, 3),

  // ── Lamentations ──
  VerseRef('Lamentations', 3, 22),
  VerseRef('Lamentations', 3, 23),

  // ── Daniel ──
  VerseRef('Daniel', 3, 17),

  // ── Michée ──
  VerseRef('Michée', 6, 8),

  // ── Habacuc ──
  VerseRef('Habacuc', 2, 4),
  VerseRef('Habacuc', 3, 17),

  // ── Zacharie ──
  VerseRef('Zacharie', 4, 6),

  // ── Malachie ──
  VerseRef('Malachie', 3, 10),

  // ── Matthieu ──
  VerseRef('Matthieu', 5, 3),
  VerseRef('Matthieu', 5, 14),
  VerseRef('Matthieu', 5, 16),
  VerseRef('Matthieu', 6, 33),
  VerseRef('Matthieu', 7, 7),
  VerseRef('Matthieu', 7, 12),
  VerseRef('Matthieu', 11, 28),
  VerseRef('Matthieu', 11, 29),
  VerseRef('Matthieu', 22, 37),
  VerseRef('Matthieu', 22, 39),
  VerseRef('Matthieu', 28, 20),

  // ── Marc ──
  VerseRef('Marc', 9, 23),
  VerseRef('Marc', 10, 45),
  VerseRef('Marc', 11, 24),

  // ── Luc ──
  VerseRef('Luc', 1, 37),
  VerseRef('Luc', 6, 31),
  VerseRef('Luc', 6, 38),
  VerseRef('Luc', 15, 20),
  VerseRef('Luc', 18, 27),

  // ── Jean ──
  VerseRef('Jean', 1, 1),
  VerseRef('Jean', 1, 14),
  VerseRef('Jean', 3, 16),
  VerseRef('Jean', 3, 17),
  VerseRef('Jean', 6, 35),
  VerseRef('Jean', 8, 12),
  VerseRef('Jean', 8, 32),
  VerseRef('Jean', 10, 10),
  VerseRef('Jean', 10, 27),
  VerseRef('Jean', 11, 25),
  VerseRef('Jean', 13, 34),
  VerseRef('Jean', 14, 1),
  VerseRef('Jean', 14, 6),
  VerseRef('Jean', 14, 27),
  VerseRef('Jean', 15, 5),
  VerseRef('Jean', 15, 13),
  VerseRef('Jean', 16, 33),

  // ── Actes ──
  VerseRef('Actes', 1, 8),
  VerseRef('Actes', 17, 28),

  // ── Romains ──
  VerseRef('Romains', 5, 8),
  VerseRef('Romains', 8, 1),
  VerseRef('Romains', 8, 28),
  VerseRef('Romains', 8, 38),
  VerseRef('Romains', 8, 39),
  VerseRef('Romains', 10, 9),
  VerseRef('Romains', 12, 2),
  VerseRef('Romains', 15, 13),

  // ── 1 Corinthiens ──
  VerseRef('1 Corinthiens', 10, 13),
  VerseRef('1 Corinthiens', 13, 4),
  VerseRef('1 Corinthiens', 13, 13),
  VerseRef('1 Corinthiens', 15, 58),

  // ── 2 Corinthiens ──
  VerseRef('2 Corinthiens', 5, 17),
  VerseRef('2 Corinthiens', 12, 9),

  // ── Galates ──
  VerseRef('Galates', 2, 20),
  VerseRef('Galates', 5, 22),
  VerseRef('Galates', 6, 9),

  // ── Éphésiens ──
  VerseRef('Éphésiens', 2, 8),
  VerseRef('Éphésiens', 2, 10),
  VerseRef('Éphésiens', 4, 32),
  VerseRef('Éphésiens', 6, 10),

  // ── Philippiens ──
  VerseRef('Philippiens', 1, 6),
  VerseRef('Philippiens', 4, 4),
  VerseRef('Philippiens', 4, 6),
  VerseRef('Philippiens', 4, 7),
  VerseRef('Philippiens', 4, 13),

  // ── Colossiens ──
  VerseRef('Colossiens', 3, 2),
  VerseRef('Colossiens', 3, 17),
  VerseRef('Colossiens', 3, 23),

  // ── 1 Thessaloniciens ──
  VerseRef('1 Thessaloniciens', 5, 16),
  VerseRef('1 Thessaloniciens', 5, 17),
  VerseRef('1 Thessaloniciens', 5, 18),

  // ── 2 Timothée ──
  VerseRef('2 Timothée', 1, 7),
  VerseRef('2 Timothée', 3, 16),

  // ── Hébreux ──
  VerseRef('Hébreux', 4, 16),
  VerseRef('Hébreux', 11, 1),
  VerseRef('Hébreux', 12, 1),
  VerseRef('Hébreux', 12, 2),
  VerseRef('Hébreux', 13, 5),
  VerseRef('Hébreux', 13, 8),

  // ── Jacques ──
  VerseRef('Jacques', 1, 5),
  VerseRef('Jacques', 1, 17),
  VerseRef('Jacques', 4, 8),
  VerseRef('Jacques', 5, 16),

  // ── 1 Pierre ──
  VerseRef('1 Pierre', 5, 7),
  VerseRef('1 Pierre', 5, 10),

  // ── 2 Pierre ──
  VerseRef('2 Pierre', 3, 9),

  // ── 1 Jean ──
  VerseRef('1 Jean', 1, 9),
  VerseRef('1 Jean', 4, 7),
  VerseRef('1 Jean', 4, 8),
  VerseRef('1 Jean', 4, 19),
  VerseRef('1 Jean', 5, 4),

  // ── Apocalypse ──
  VerseRef('Apocalypse', 3, 20),
  VerseRef('Apocalypse', 21, 4),
  VerseRef('Apocalypse', 22, 20),
];

/// Nombre de créneaux supplémentaires réservés au tirage pondéré.
/// Sur (kCuratedVerses.length + kExtraRandomSlots) jours,
/// kCuratedVerses.length jours utilisent un verset curatée (~80 %)
/// et kExtraRandomSlots jours utilisent le tirage pondéré (~20 %).
const int kExtraRandomSlots = 45;

/// Poids par livre pour le tirage pondéré.
/// Les livres absents sont exclus (généalogies, lois rituelles, etc.).
const Map<String, int> kBookWeights = {
  'Psaume': 8,
  'Proverbes': 6,
  'Jean': 6,
  'Matthieu': 5,
  'Luc': 5,
  'Marc': 4,
  'Romains': 5,
  'Philippiens': 4,
  'Éphésiens': 4,
  'Galates': 3,
  'Hébreux': 3,
  '1 Corinthiens': 3,
  '2 Corinthiens': 3,
  'Colossiens': 3,
  '1 Jean': 3,
  'Jacques': 3,
  '1 Pierre': 2,
  '2 Pierre': 2,
  'Ésaïe': 4,
  'Jérémie': 2,
  'Lamentations': 2,
  'Genèse': 2,
  'Exode': 1,
  'Deutéronome': 2,
  'Josué': 2,
  'Job': 2,
  'Daniel': 2,
  'Michée': 1,
  'Habacuc': 1,
  'Zacharie': 1,
  'Actes': 2,
  '1 Thessaloniciens': 2,
  '2 Timothée': 2,
  'Apocalypse': 2,
};
