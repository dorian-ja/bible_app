import 'dart:async'; // Pour StreamSubscription
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// import 'package:shared_preferences/shared_preferences.dart'; // N'est plus utilisé pour les favoris ici
import 'package:diacritic/diacritic.dart';

// Importer vos services et modèles Isar
import '../services/isar_service.dart';
import '../models/verse.dart'; // Assurez-vous que ce chemin est correct

class RecherchePage extends StatefulWidget {
  final void Function(String book, String chapter)? onVerseTap;

  RecherchePage({Key? key, this.onVerseTap}) : super(key: key);

  @override
  _RecherchePageState createState() => _RecherchePageState();
}

class _RecherchePageState extends State<RecherchePage> {
  final IsarService _isarService = IsarService(); // Instance du service Isar

  Map<String, dynamic> bibleData =
      {}; // Pour charger bible.json (recherche textuelle)

  // searchResults contiendra maintenant des objets Verse (ou des Map enrichies)
  // au lieu de simples Map<String, String> pour faciliter la gestion des favoris.
  // Pour une meilleure performance et typage, créer un petit modèle pour les résultats de recherche est une bonne idée.
  // Pour l'instant, on va enrichir la Map.
  List<Map<String, dynamic>> searchResults = [];

  // Set<String> favorites = {}; // *** SUPPRIMER : les favoris sont gérés par Isar ***

  String query = "";
  bool isSearching = false;
  final TextEditingController keywordController = TextEditingController();
  final TextEditingController refController = TextEditingController();

  StreamSubscription?
  _verseCollectionSubscription; // Pour écouter tous les changements sur les versets

  @override
  void initState() {
    super.initState();
    loadBibleData(); // Charger les données pour la recherche textuelle
    // loadFavorites(); // *** SUPPRIMER ***
    _watchAllVerses(); // Écouter les changements de favoris (ou autres) dans Isar
  }

  @override
  void dispose() {
    _verseCollectionSubscription?.cancel();
    super.dispose();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // Écouter les changements sur TOUTE la collection Verse.
  // Si un favori change n'importe où, et que ce verset est dans searchResults,
  // on veut rafraîchir l'UI de la recherche.
  void _watchAllVerses() async {
    final isar = await IsarService.db;
    _verseCollectionSubscription = isar.verses.watchLazy().listen((_) {
      debugPrint(
        "RecherchePage (Watcher): Changement détecté dans la collection Verses.",
      );
      if (mounted && searchResults.isNotEmpty) {
        // Il faut rafraîchir l'état de favori des résultats affichés
        _refreshSearchResultsWithFavoriteStatus();
      }
    });
  }

  Future<void> _refreshSearchResultsWithFavoriteStatus() async {
    if (searchResults.isEmpty) return;

    final List<Map<String, dynamic>> updatedResults = [];
    for (var oldResult in searchResults) {
      // oldResult contient 'book', 'chapter', 'verseNum', 'text'
      // Il faut retrouver l'objet Verse correspondant dans Isar pour son état de favori
      try {
        final bookName = oldResult['book'] as String;
        final chapterNum = int.parse(oldResult['chapter'] as String);
        final verseNum = int.parse(oldResult['verseNum'] as String);

        Verse? verseFromDb = await _isarService.getSingleVerse(
          bookName,
          chapterNum,
          verseNum,
        );

        updatedResults.add({
          'book': bookName,
          'chapter': chapterNum.toString(),
          'verseNum': verseNum.toString(),
          'reference': oldResult['reference'],
          'text': oldResult['text'],
          'isFavorite': verseFromDb?.isFavorite ?? false,
          // Mettre à jour le statut favori
          'isarId': verseFromDb?.id,
          // Stocker l'ID Isar pour les actions futures
        });
      } catch (e) {
        debugPrint(
          "Erreur lors du rafraîchissement du statut favori pour un résultat : $e",
        );
        // Ajouter l'ancien résultat sans l'info à jour si la récupération échoue
        updatedResults.add(
          oldResult..['isFavorite'] = false,
        ); // Mettre à false par défaut
      }
    }
    setStateIfMounted(() {
      searchResults = updatedResults;
    });
  }

  Future<void> loadBibleData() async {
    final String response = await rootBundle.loadString('assets/bible.json');
    final data = json.decode(response);
    setStateIfMounted(() {
      bibleData = data;
    });
  }

  // *** SUPPRIMER loadFavorites() ***
  // Future<void> loadFavorites() async { ... }

  Future<void> _toggleFavoriteForResult(
    Map<String, dynamic> searchResult,
  ) async {
    final String bookName = searchResult['book'] as String;
    final int chapterNum = int.parse(searchResult['chapter'] as String);
    final int verseNum = int.parse(searchResult['verseNum'] as String);
    // bool currentIsFavorite = searchResult['isFavorite'] as bool; // L'état actuel affiché

    // 1. Récupérer l'objet Verse depuis Isar (ou s'assurer qu'il existe)
    Verse? verse = await _isarService.getSingleVerse(
      bookName,
      chapterNum,
      verseNum,
    );

    if (verse == null) {
      // Si le verset n'existe pas encore dans Isar (parce qu'il n'a jamais été lu/favorisé via les autres pages)
      // il faut le créer et l'ajouter.
      // C'est un cas qui peut arriver si l'import initial n'a pas tout mis dans Isar.
      // Pour cet exemple, on suppose que IsarService.getSingleVerse le crée s'il n'existe pas,
      // ou que l'import initial a bien rempli la base Isar.
      // Si ce n'est pas le cas, il faudrait une logique ici pour créer un nouvel objet Verse.
      debugPrint(
        "RecherchePage: Verset $bookName $chapterNum:$verseNum non trouvé dans Isar pour toggle. Il devrait être créé par getSingleVerse ou l'import initial.",
      );
      // Pour être sûr, créons-le si manquant. L'ID sera auto-généré.
      // Assurez-vous que votre modèle Verse a un constructeur adapté.
      verse = Verse()
        ..book = bookName
        ..chapter = chapterNum
        ..verse = verseNum
        ..text =
            searchResult['text']
                as String // Assumer que le texte est dans searchResult
        ..isFavorite = false; // Sera inversé par toggleFavorite
      // ..noteText = null // etc.
      // Pas besoin de le sauvegarder ici, toggleFavorite s'en chargera (s'il le crée)
    }

    // 2. Appeler le service pour basculer le favori dans Isar
    Verse? updatedVerse = await _isarService.toggleFavorite(verse);

    // 3. Mettre à jour l'UI
    // Le watcher _watchAllVerses devrait normalement s'en charger.
    // Mais pour une réactivité immédiate sur cet item spécifique, on peut le mettre à jour directement.
    if (updatedVerse != null) {
      setStateIfMounted(() {
        final index = searchResults.indexWhere(
          (r) =>
              r['book'] == bookName &&
              r['chapter'] == chapterNum.toString() &&
              r['verseNum'] == verseNum.toString(),
        );
        if (index != -1) {
          searchResults[index]['isFavorite'] = updatedVerse.isFavorite;
          searchResults[index]['isarId'] =
              updatedVerse.id; // Au cas où il a été créé
        }
      });
    } else {
      debugPrint("RecherchePage: Erreur lors du toggle du favori via service.");
      // Gérer l'erreur si besoin
    }
  }

  Future<void> searchVerses(String keyword) async {
    setStateIfMounted(() {
      isSearching = true;
      searchResults = [];
      query = keyword;
    });

    if (keyword.trim().isEmpty) {
      setStateIfMounted(() => isSearching = false);
      return;
    }

    final searchLower = removeDiacritics(keyword.toLowerCase());
    final List<Map<String, dynamic>> results = [];

    // Pas besoin de Future.delayed si la recherche est rapide. Sinon, ok.
    // await Future.delayed(Duration(milliseconds: 100));

    for (final bookKey in bibleData.keys) {
      final chapters = bibleData[bookKey] as Map<String, dynamic>;
      for (final chapterKey in chapters.keys) {
        final verses = chapters[chapterKey] as Map<String, dynamic>;
        for (final verseNumKey in verses.keys) {
          final verseText = verses[verseNumKey] as String?;
          if (verseText != null &&
              removeDiacritics(verseText.toLowerCase()).contains(searchLower)) {
            // Récupérer l'état de favori depuis Isar
            bool isFav = false;
            int? verseIsarId;
            try {
              final int chapInt = int.parse(chapterKey);
              final int verseNumInt = int.parse(verseNumKey);
              Verse? verseFromDb = await _isarService.getSingleVerse(
                bookKey,
                chapInt,
                verseNumInt,
              );
              isFav = verseFromDb?.isFavorite ?? false;
              verseIsarId = verseFromDb?.id;
            } catch (e) {
              debugPrint(
                "Erreur récupération favori pour $bookKey $chapterKey:$verseNumKey - $e",
              );
            }

            results.add({
              'book': bookKey,
              'chapter': chapterKey,
              'verseNum': verseNumKey,
              'reference': "$bookKey $chapterKey:$verseNumKey",
              'text': verseText,
              'isFavorite': isFav, // Ajout de l'état favori
              'isarId': verseIsarId, // Ajout de l'ID Isar
            });
          }
        }
      }
    }

    setStateIfMounted(() {
      searchResults = results;
      isSearching = false;
    });
  }

  Future<void> searchByReference(String input) async {
    // Changé en Future<void> pour await _isarService
    setStateIfMounted(() {
      isSearching = true; // Optionnel, car c'est généralement rapide
      searchResults = [];
      query = input;
    });

    final match = RegExp(r'^(.+?)\s+(\d+):(\d+)$').firstMatch(input.trim());
    if (match == null) {
      setStateIfMounted(() => isSearching = false);
      return;
    }

    final bookInput = match.group(1)?.trim();
    final chapterStr = match.group(2);
    final verseNumStr = match.group(3);

    if (bookInput == null || chapterStr == null || verseNumStr == null) {
      setStateIfMounted(() => isSearching = false);
      return;
    }
    final int? chapterNum = int.tryParse(chapterStr);
    final int? verseNum = int.tryParse(verseNumStr);

    if (chapterNum == null || verseNum == null) {
      setStateIfMounted(() => isSearching = false);
      return;
    }

    // Normaliser le nom du livre pour correspondre aux clés de bibleData (ou directement à Isar si possible)
    final normalizedInput = removeDiacritics(bookInput.toLowerCase());
    String? foundBookKey;

    // Trouver le nom du livre canonique (celui utilisé dans bible.json et Isar)
    // Idéalement, IsarService aurait une méthode pour cela ou on interrogerait Isar.
    // Pour l'instant, on se base sur bibleData.keys pour trouver le nom du livre.
    // Cela suppose que les noms de livres dans Isar sont les mêmes que les clés de bibleData.
    try {
      foundBookKey = bibleData.keys.firstWhere(
        (b) => removeDiacritics(b.toLowerCase()) == normalizedInput,
      );
    } catch (e) {
      // firstWhere throws StateError if no element is found
      foundBookKey = null;
    }

    if (foundBookKey == null) {
      debugPrint("Livre '$bookInput' non trouvé.");
      setStateIfMounted(() => isSearching = false);
      return;
    }

    // Récupérer le verset depuis Isar (pour le texte et l'état favori)
    Verse? verseFromDb = await _isarService.getSingleVerse(
      foundBookKey,
      chapterNum,
      verseNum,
    );

    if (verseFromDb != null) {
      setStateIfMounted(() {
        searchResults = [
          {
            'book': verseFromDb.book,
            'chapter': verseFromDb.chapter.toString(),
            'verseNum': verseFromDb.verse.toString(),
            'reference':
                "${verseFromDb.book} ${verseFromDb.chapter}:${verseFromDb.verse}",
            'text': verseFromDb.text, // Le texte vient d'Isar maintenant
            'isFavorite': verseFromDb.isFavorite,
            'isarId': verseFromDb.id,
          },
        ];
        isSearching = false;
      });
    } else {
      // Si non trouvé dans Isar, essayer de le prendre de bible.json (texte seulement)
      // et marquer comme non favori.
      final chapterData = bibleData[foundBookKey]?[chapterNum.toString()];
      final verseText = chapterData?[verseNum.toString()] as String?;
      if (verseText != null) {
        setStateIfMounted(() {
          searchResults = [
            {
              'book': foundBookKey!,
              // foundBookKey ne peut pas être null ici
              'chapter': chapterNum.toString(),
              'verseNum': verseNum.toString(),
              'reference': "$foundBookKey $chapterNum:$verseNum",
              'text': verseText,
              'isFavorite': false,
              // Par défaut non favori car non trouvé dans Isar
              'isarId': null,
            },
          ];
          isSearching = false;
        });
      } else {
        setStateIfMounted(() {
          searchResults = []; // Aucun résultat trouvé
          isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Ou Scaffold si besoin d'AppBar, etc.
      child: Column(
        children: [
          Padding(
            // Champs de recherche (inchangés)
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: keywordController,
              decoration: InputDecoration(
                labelText: 'Rechercher un mot-clé',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => searchVerses(keywordController.text),
                ),
              ),
              onSubmitted: searchVerses,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: refController,
              decoration: InputDecoration(
                labelText: 'Accès direct (ex: Jean 3:16)',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => searchByReference(refController.text),
                ),
              ),
              onSubmitted: searchByReference,
            ),
          ),
          if (isSearching)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else if (searchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                query.isEmpty
                    ? 'Entrez un mot ou une référence.'
                    : 'Aucun verset trouvé.',
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final result = searchResults[index];
                // final key = result['key']!; // L'ancienne clé 'livre|chap|verset'

                final String book = result['book'] as String;
                final String chapter =
                    result['chapter'] as String; // Déjà en String
                // final String verseNum = result['verseNum'] as String; // Déjà en String

                final String ref = result['reference'] as String;
                final String text = result['text'] as String;
                final bool isFavorite =
                    result['isFavorite'] as bool? ??
                    false; // Lire depuis le résultat enrichi

                return ListTile(
                  title: Text(
                    ref,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(text),
                  trailing: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => _toggleFavoriteForResult(
                      result,
                    ), // Passer tout l'objet result
                  ),
                  onTap: () {
                    if (widget.onVerseTap != null) {
                      widget.onVerseTap!(book, chapter);
                    }
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
