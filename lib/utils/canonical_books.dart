/// Ordre canonique des 66 livres de la Bible (AT puis NT).
/// Utilisé pour trier la liste des livres renvoyée par la base de données.
const List<String> kCanonicalBookOrder = [
  // Ancien Testament
  'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
  'Josué', 'Juges', 'Ruth',
  '1 Samuel', '2 Samuel', '1 Rois', '2 Rois',
  '1 Chroniques', '2 Chroniques',
  'Esdras', 'Néhémie', 'Esther',
  'Job', 'Psaume', 'Proverbes', 'Ecclésiaste', 'Cantique Des Cantiqu',
  'Ésaïe', 'Jérémie', 'Lamentations', 'Ézéchiel', 'Daniel',
  'Osée', 'Joël', 'Amos', 'Abdias', 'Jonas', 'Michée',
  'Nahum', 'Habacuc', 'Sophonie', 'Aggée', 'Zacharie', 'Malachie',
  // Nouveau Testament
  'Matthieu', 'Marc', 'Luc', 'Jean',
  'Actes',
  'Romains',
  '1 Corinthiens', '2 Corinthiens',
  'Galates', 'Éphésiens', 'Philippiens', 'Colossiens',
  '1 Thessaloniciens', '2 Thessaloniciens',
  '1 Timothée', '2 Timothée',
  'Tite', 'Philémon',
  'Hébreux',
  'Jacques',
  '1 Pierre', '2 Pierre',
  '1 Jean', '2 Jean', '3 Jean',
  'Jude',
  'Apocalypse',
];

/// Trie [books] selon l'ordre canonique.
/// Les livres non reconnus sont placés à la fin dans leur ordre d'origine.
List<String> sortBooksCanonically(List<String> books) {
  final known = <String>[];
  final unknown = <String>[];

  for (final book in books) {
    if (kCanonicalBookOrder.contains(book)) {
      known.add(book);
    } else {
      unknown.add(book);
    }
  }

  known.sort((a, b) =>
      kCanonicalBookOrder.indexOf(a).compareTo(kCanonicalBookOrder.indexOf(b)));

  return [...known, ...unknown];
}
