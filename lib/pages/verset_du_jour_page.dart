// lib/pages/verset_du_jour_page.dart

import 'dart:async'; // Importer pour StreamSubscription
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Gardé pour rootBundle (chargement texte verset initial)
import 'package:isar/isar.dart'; // Importer Isar
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../models/verse.dart';
import '../services/isar_service.dart';

class VersetDuJourPage extends StatefulWidget {
  final void Function(String book, String chapter)? onVerseTap;

  VersetDuJourPage({Key? key, this.onVerseTap}) : super(key: key);

  @override
  _VersetDuJourPageState createState() => _VersetDuJourPageState();
}

class _VersetDuJourPageState extends State<VersetDuJourPage> {
  final IsarService _isarService = IsarService();
  Verse?
  _currentVerseObject; // Cet objet contiendra TOUT (texte, favori, noteText, noteColor)
  StreamSubscription<Verse?>? _verseSubscription;

  // Ces variables peuvent être utilisées pour le chargement initial du texte du verset
  // mais l'état favori et les notes viendront de _currentVerseObject.
  String?
  bookNameState; // Renommé pour éviter conflit avec _currentVerseObject.book
  String? chapterNumState;
  String? verseNumState;
  String? textState;

  // Map<String, dynamic>? noteData; // *** SUPPRIMER : les notes seront dans _currentVerseObject ***

  // _isCurrentVerseFavorite peut être maintenu pour simplicité dans le build,
  // mais il doit être synchronisé avec _currentVerseObject.isFavorite.
  // Idéalement, on lirait _currentVerseObject?.isFavorite directement dans build().
  bool _isCurrentVerseFavorite = false;

  @override
  void initState() {
    super.initState();
    debugPrint("VersetDuJourPage: initState");
    loadOrGenerateVerse();
  }

  @override
  void dispose() {
    debugPrint(
      "VersetDuJourPage: dispose - Annulation de l'abonnement au verset.",
    );
    _verseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchCurrentVerseDataFromIsar({
    bool setupWatcher = false,
  }) async {
    debugPrint(
      "VersetDuJourPage: _fetchCurrentVerseDataFromIsar CALLED (setupWatcher: $setupWatcher)",
    );
    await _verseSubscription?.cancel();
    _verseSubscription = null;

    if (bookNameState != null &&
        chapterNumState != null &&
        verseNumState != null) {
      try {
        final int chapInt = int.parse(chapterNumState!);
        final int verseInt = int.parse(verseNumState!);

        _currentVerseObject = await _isarService.getSingleVerse(
          bookNameState!,
          chapInt,
          verseInt,
        );
        // Le textState est déjà chargé depuis le JSON, on ne le met pas à jour ici
        // sauf si on veut que le texte vienne aussi d'Isar (ce qui est une bonne pratique à terme)

        if (mounted) {
          setState(() {
            _isCurrentVerseFavorite = _currentVerseObject?.isFavorite ?? false;
            // Les notes (_currentVerseObject.noteText, _currentVerseObject.noteColor)
            // seront lues directement dans le build ou dans showNoteDialog.
            debugPrint(
              "VersetDuJourPage: Objet Verset Isar chargé/mis à jour: ID ${_currentVerseObject?.id}, Fav: $_isCurrentVerseFavorite, Note: '${_currentVerseObject?.noteText}'",
            );
          });

          if (setupWatcher && _currentVerseObject != null) {
            _setupVerseWatcher(_currentVerseObject!);
          } else if (_currentVerseObject == null) {
            debugPrint(
              "VersetDuJourPage: _currentVerseObject est null APRÈS fetch, watcher non configuré.",
            );
            // Cela peut arriver si le verset du jour n'est pas encore dans Isar la toute première fois
            // et que l'import n'a pas eu lieu. Gérer ce cas.
            // Pour l'instant, on suppose que l'import a eu lieu.
          }
        }
      } catch (e, s) {
        debugPrint(
          "VersetDuJourPage: ERREUR _fetchCurrentVerseDataFromIsar: $e\n$s",
        );
        if (mounted) {
          setState(() {
            _currentVerseObject = null;
            _isCurrentVerseFavorite = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _currentVerseObject = null;
          _isCurrentVerseFavorite = false;
        });
      }
      debugPrint(
        "VersetDuJourPage: _fetchCurrentVerseDataFromIsar - infos manquantes pour charger.",
      );
    }
  }

  void _setupVerseWatcher(Verse verseToWatch) async {
    // S'assurer que verseToWatch.id est valide (non null et > 0 si autoIncrement)
    if (verseToWatch.id == Isar.autoIncrement || verseToWatch.id < 1) {
      debugPrint(
        "VersetDuJourPage: Tentative de watch avec ID invalide: ${verseToWatch.id}. Peut arriver si l'objet n'est pas encore sauvegardé.",
      );
      // Peut-être essayer de re-fetcher l'objet Verse ici pour obtenir un ID valide
      // si on suspecte qu'il a été sauvegardé entre-temps.
      Verse? fetchedVerse = await _isarService.getSingleVerse(
        verseToWatch.book,
        verseToWatch.chapter,
        verseToWatch.verse,
      );
      if (fetchedVerse != null &&
          fetchedVerse.id != Isar.autoIncrement &&
          fetchedVerse.id > 0) {
        debugPrint(
          "VersetDuJourPage: Verset re-fetché avec ID valide ${fetchedVerse.id} pour le watcher.",
        );
        verseToWatch = fetchedVerse;
      } else {
        debugPrint(
          "VersetDuJourPage: Échec du re-fetch pour ID valide. Watcher non configuré.",
        );
        return;
      }
    }

    debugPrint(
      "VersetDuJourPage: _setupVerseWatcher pour ID ${verseToWatch.id}",
    );
    final isar = await IsarService.db;
    _verseSubscription = isar.verses.watchObject(verseToWatch.id, fireImmediately: false).listen((
      updatedVerse,
    ) {
      if (!mounted) return; // Ne rien faire si le widget est disposé

      if (updatedVerse != null) {
        debugPrint(
          "VersetDuJourPage (Watcher): Changement détecté ID ${updatedVerse.id}. Fav: ${updatedVerse.isFavorite}, Note: '${updatedVerse.noteText}', Couleur: ${updatedVerse.noteColor}",
        );

        // Comparer tous les champs pertinents
        bool favoriteChanged =
            updatedVerse.isFavorite != _currentVerseObject?.isFavorite;
        bool noteTextChanged =
            updatedVerse.noteText != _currentVerseObject?.noteText;
        bool noteColorChanged =
            updatedVerse.noteColor != _currentVerseObject?.noteColor;
        // bool textContentChanged = updatedVerse.text != textState; // Si le texte du verset peut aussi changer

        if (favoriteChanged ||
            noteTextChanged ||
            noteColorChanged /*|| textContentChanged*/ ) {
          setState(() {
            _currentVerseObject =
                updatedVerse; // TRÈS IMPORTANT: Mettre à jour l'objet local
            _isCurrentVerseFavorite = updatedVerse.isFavorite;
            // textState = updatedVerse.text; // Si applicable
            // Les notes seront lues de _currentVerseObject mis à jour dans build()
          });
          debugPrint(
            "VersetDuJourPage (Watcher): setState appelé. Nouvel état local mis à jour.",
          );
        } else {
          debugPrint(
            "VersetDuJourPage (Watcher): Changement détecté mais aucun champ pertinent pour l'UI n'a varié ou état déjà à jour.",
          );
        }
      } else {
        debugPrint(
          "VersetDuJourPage (Watcher): Le verset ID ${verseToWatch.id} a été supprimé ou non trouvé.",
        );
        setState(() {
          _currentVerseObject = null;
          _isCurrentVerseFavorite = false;
          // Gérer la suppression, peut-être recharger un nouveau verset du jour
        });
      }
    });
    debugPrint(
      "VersetDuJourPage: Watcher configuré pour l'objet Verse ID ${verseToWatch.id}",
    );
  }

  Future<void> _toggleCurrentVerseFavorite() async {
    debugPrint("VersetDuJourPage: _toggleCurrentVerseFavorite CALLED");
    if (_currentVerseObject == null) {
      debugPrint(
        "VersetDuJourPage: _currentVerseObject est NULL. Tentative de chargement...",
      );
      // Assurer que bookNameState etc. sont bien initialisés avant d'appeler _fetch...
      if (bookNameState == null ||
          chapterNumState == null ||
          verseNumState == null) {
        debugPrint(
          "VersetDuJourPage: Impossible de fetch, infos de base manquantes. Abandon.",
        );
        return;
      }
      await _fetchCurrentVerseDataFromIsar(setupWatcher: true);
      if (_currentVerseObject == null) {
        debugPrint(
          "VersetDuJourPage: Tentative de chargement échouée, _currentVerseObject toujours NULL. Abandon.",
        );
        return;
      }
    }
    // S'assurer que l'ID est valide avant de toggle
    if (_currentVerseObject!.id == Isar.autoIncrement ||
        _currentVerseObject!.id < 1) {
      debugPrint(
        "VersetDuJourPage: _toggleCurrentVerseFavorite - ID Invalide pour currentVerseObject. Tentative de re-fetch.",
      );
      Verse? fetchedVerse = await _isarService.getSingleVerse(
        _currentVerseObject!.book,
        _currentVerseObject!.chapter,
        _currentVerseObject!.verse,
      );
      if (fetchedVerse != null) {
        _currentVerseObject = fetchedVerse;
      } else {
        debugPrint(
          "VersetDuJourPage: _toggleCurrentVerseFavorite - Échec re-fetch. Abandon.",
        );
        return;
      }
    }

    debugPrint(
      "VersetDuJourPage AVANT appel service: ID=${_currentVerseObject!.id}, isFavorite=${_currentVerseObject!.isFavorite}",
    );

    // Appel au service Isar. Le service met à jour la DB.
    Verse? updatedVerse = await _isarService.toggleFavorite(
      _currentVerseObject!,
    );

    // Le watcher (_setupVerseWatcher) devrait détecter ce changement dans la DB et mettre à jour l'UI.
    // L'UI se mettra à jour via le setState dans le callback du watcher.
    // Si updatedVerse est retourné par toggleFavorite, on pourrait l'utiliser pour une MàJ optimiste
    // mais il est préférable de laisser le watcher faire son travail pour une source de vérité unique.
    if (updatedVerse != null) {
      debugPrint(
        "VersetDuJourPage APRÈS appel service: Le watcher devrait mettre à jour l'UI pour l'ID ${updatedVerse.id}. Nouveau statut DB (attendu): ${updatedVerse.isFavorite}",
      );
    } else {
      debugPrint(
        "VersetDuJourPage: Erreur lors du toggle ou verset non trouvé par le service.",
      );
    }
  }

  Future<void> loadOrGenerateVerse() async {
    debugPrint("VersetDuJourPage: loadOrGenerateVerse CALLED");
    final prefs =
        await SharedPreferences.getInstance(); // Gardé pour la logique du "verset du jour"
    final today = DateTime.now();
    final keyDate = "${today.year}-${today.month}-${today.day}";
    final storedDate = prefs.getString('verset_date');
    final storedBook = prefs.getString('verset_book');
    final storedChapter = prefs.getString('verset_chapter');
    final storedVerseNum = prefs.getString('verset_verse');

    if (storedDate == keyDate &&
        storedBook != null &&
        storedChapter != null &&
        storedVerseNum != null) {
      debugPrint(
        "VersetDuJourPage: Chargement du verset du jour depuis SharedPreferences: $storedBook $storedChapter:$storedVerseNum",
      );
      await loadVerseTextAndSetStateVars(
        storedBook,
        storedChapter,
        storedVerseNum,
      );
    } else {
      debugPrint("VersetDuJourPage: Génération d'un nouveau verset du jour.");
      await generateNewVerseAndSetStateVars(prefs, keyDate);
    }

    // Une fois que bookNameState, chapterNumState, verseNumState sont définis,
    // récupérer l'objet Verse complet d'Isar (qui inclut favori et notes).
    if (bookNameState != null &&
        chapterNumState != null &&
        verseNumState != null) {
      await _fetchCurrentVerseDataFromIsar(setupWatcher: true);
    } else {
      debugPrint(
        "VersetDuJourPage: Infos du verset non disponibles après load/generate pour fetcher les données Isar.",
      );
      if (mounted) {
        setState(() {
          _currentVerseObject = null;
          _isCurrentVerseFavorite = false;
        });
      }
    }
  }

  // Charge SEULEMENT le texte du verset depuis bible.json et met à jour les state vars
  Future<void> loadVerseTextAndSetStateVars(
    String b,
    String c,
    String vNum,
  ) async {
    final String data = await rootBundle.loadString('assets/bible.json');
    final Map<String, dynamic> bibleData = json.decode(data);
    final String verseTextContent =
        bibleData[b]?[c]?[vNum] ?? 'Texte non trouvé';

    // Mettre à jour les variables d'état pour l'affichage initial et pour _fetchCurrentVerseDataFromIsar
    // Pas de setState ici si _fetchCurrentVerseDataFromIsar va être appelé et fera le setState.
    // Ou alors un setState partiel pour le texte seulement.
    bookNameState = b;
    chapterNumState = c;
    verseNumState = vNum;
    if (mounted) {
      // Mettre à jour le texte affiché immédiatement
      setState(() {
        textState = verseTextContent;
      });
    } else {
      textState = verseTextContent;
    }
    debugPrint(
      "VersetDuJourPage: Texte du verset chargé (variables d'état): $bookNameState $chapterNumState:$verseNumState",
    );
    // *** SUPPRIMER l'appel à loadNote() d'ici, les notes viennent d'Isar via _currentVerseObject ***
  }

  Future<void> generateNewVerseAndSetStateVars(
    SharedPreferences prefs,
    String keyDate,
  ) async {
    final String data = await rootBundle.loadString('assets/bible.json');
    final Map<String, dynamic> bibleData = json.decode(data);
    final books = bibleData.keys.toList();
    final randomBook = books[Random().nextInt(books.length)];
    final chaptersMap = bibleData[randomBook] as Map<String, dynamic>;
    final chaptersKeys = chaptersMap.keys.toList();
    final randomChapterKey =
        chaptersKeys[Random().nextInt(chaptersKeys.length)];
    final versesMap = chaptersMap[randomChapterKey] as Map<String, dynamic>;
    final versesKeys = versesMap.keys.toList();
    final randomVerseKey = versesKeys[Random().nextInt(versesKeys.length)];
    final String verseTextContent =
        versesMap[randomVerseKey] ?? 'Texte non trouvé';

    await prefs.setString('verset_date', keyDate);
    await prefs.setString('verset_book', randomBook);
    await prefs.setString('verset_chapter', randomChapterKey);
    await prefs.setString('verset_verse', randomVerseKey);

    bookNameState = randomBook;
    chapterNumState = randomChapterKey;
    verseNumState = randomVerseKey;
    if (mounted) {
      setState(() {
        textState = verseTextContent;
      });
    } else {
      textState = verseTextContent;
    }
    debugPrint(
      "VersetDuJourPage: Nouveau verset généré (variables d'état): $bookNameState $chapterNumState:$verseNumState",
    );
    // *** SUPPRIMER l'appel à loadNote() d'ici ***
  }

  // *** SUPPRIMER TOUTE LA MÉTHODE loadNote() car SharedPreferences n'est plus utilisé pour ça ***
  // Future<void> loadNote() async { ... }

  void showNoteDialog() {
    if (_currentVerseObject == null) {
      debugPrint(
        "VersetDuJourPage: showNoteDialog appelé mais _currentVerseObject est null.",
      );
      // Optionnel: Afficher un message ou essayer de recharger
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Données du verset non encore chargées.")),
      );
      return;
    }
    // S'assurer que l'ID est valide
    if (_currentVerseObject!.id == Isar.autoIncrement ||
        _currentVerseObject!.id < 1) {
      debugPrint(
        "VersetDuJourPage: showNoteDialog - ID Invalide. Le verset n'est peut-être pas encore dans Isar.",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Impossible d'ajouter une note, ID du verset invalide.",
          ),
        ),
      );
      return;
    }

    final String initialNoteText = _currentVerseObject?.noteText ?? '';
    final Color? initialNoteColor =
        _currentVerseObject?.noteColorAsColor; // Utilise le getter du modèle

    final controller = TextEditingController(text: initialNoteText);
    Color? selectedDialogColor = initialNoteColor;

    final List<Color?> colorOptions = [
      null,
      Colors.yellow,
      Colors.green,
      Colors.red,
      Colors.blue,
    ];

    showDialog(
      context: context,
      builder: (contextDialog) {
        // Renommer context pour éviter shadowing
        return StatefulBuilder(
          // Pour la sélection de couleur dans le dialogue
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Note personnelle"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    decoration: InputDecoration(hintText: "Votre note..."),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: colorOptions.map((colorOption) {
                      final isSelected =
                          selectedDialogColor?.value == colorOption?.value;
                      return GestureDetector(
                        onTap: () => setStateDialog(
                          () => selectedDialogColor = colorOption,
                        ),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: isSelected ? 36 : 30,
                          height: isSelected ? 36 : 30,
                          decoration: BoxDecoration(
                            color: colorOption ?? Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: colorOption == null
                              ? Center(
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(contextDialog),
                  child: Text("Annuler"),
                ),
                TextButton(
                  onPressed: () async {
                    if (_currentVerseObject == null) return;

                    final String newText = controller.text.trim();
                    // Convertir Color? en String? (hex) pour IsarService
                    final String? newColorHex = selectedDialogColor != null
                        ? '#${selectedDialogColor!.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}' // RRGGBB
                        : null;

                    debugPrint(
                      "VersetDuJourPage: Sauvegarde de la note - Texte: '$newText', CouleurHex: '$newColorHex' pour ID ${_currentVerseObject!.id}",
                    );

                    // Appeler le service Isar pour sauvegarder
                    Verse? updatedVerse = await _isarService.updateVerseNote(
                      _currentVerseObject!,
                      newText.isEmpty ? null : newText,
                      // Stocker null si le texte est vide
                      newColorHex,
                    );

                    // Le watcher devrait mettre à jour _currentVerseObject et l'UI.
                    if (updatedVerse != null) {
                      debugPrint(
                        "VersetDuJourPage: Note sauvegardée via Isar. Le watcher devrait mettre à jour l'UI.",
                      );
                    } else {
                      debugPrint(
                        "VersetDuJourPage: ERREUR lors de la sauvegarde de la note via Isar.",
                      );
                      ScaffoldMessenger.of(contextDialog).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Erreur lors de la sauvegarde de la note.",
                          ),
                        ),
                      );
                    }
                    Navigator.pop(contextDialog); // Fermer le dialogue
                  },
                  child: Text("Enregistrer"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void openChapter() {
    if (widget.onVerseTap != null &&
        bookNameState != null &&
        chapterNumState != null) {
      widget.onVerseTap!(bookNameState!, chapterNumState!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lire les données de note directement depuis _currentVerseObject
    final String? currentNoteText = _currentVerseObject?.noteText;
    final Color? currentNoteDisplayColor =
        _currentVerseObject?.noteColorAsColor; // Utilise le getter

    debugPrint(
      "VersetDuJourPage: build. Fav: $_isCurrentVerseFavorite (lu de variable locale, devrait être ${_currentVerseObject?.isFavorite}), Note: '$currentNoteText', CouleurNoteObj: $currentNoteDisplayColor, _currentVerseObject: ${_currentVerseObject != null ? 'PRESENT' : 'NULL'}",
    );

    if (textState == null ||
        bookNameState == null ||
        chapterNumState == null ||
        verseNumState == null) {
      debugPrint(
        "VersetDuJourPage: build - Données textuelles manquantes, affichage CircularProgressIndicator.",
      );
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ); // Mettre un Scaffold pour éviter erreur "no media query"
    }

    return Scaffold(
      // Ajouter un Scaffold si ce n'est pas déjà un enfant d'un Scaffold
      // appBar: AppBar(title: Text("Verset du Jour")), // Optionnel
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$bookNameState $chapterNumState:$verseNumState",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                "“$textState”", // Utiliser textState pour le texte du verset
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            // Affichage de la note si elle existe dans _currentVerseObject
            if (currentNoteText != null && currentNoteText.isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: 12),
                padding: EdgeInsets.all(12), // Un peu plus de padding
                decoration: BoxDecoration(
                  color:
                      currentNoteDisplayColor?.withOpacity(0.2) ??
                      Colors.grey.shade200,
                  // Opacité sur la couleur de la note
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    // Ajouter une petite bordure
                    color: currentNoteDisplayColor ?? Colors.grey.shade400,
                    width: 1,
                  ),
                ),
                child: Text(
                  currentNoteText,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 24),
            IconButton(
              iconSize: 36,
              icon: Icon(
                _currentVerseObject?.isFavorite ?? false
                    ? Icons.star
                    : Icons
                          .star_border, // Lire directement de _currentVerseObject
                color: _currentVerseObject?.isFavorite ?? false
                    ? Colors.amber
                    : Colors.grey,
              ),
              onPressed: _toggleCurrentVerseFavorite,
            ),
            ElevatedButton.icon(
              onPressed: openChapter,
              icon: Icon(Icons.menu_book),
              label: Text("Lire le chapitre complet"),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.share),
              label: Text("Partager"),
              onPressed: () {
                if (bookNameState != null &&
                    chapterNumState != null &&
                    verseNumState != null &&
                    textState != null) {
                  final verseToShare =
                      "$bookNameState $chapterNumState:$verseNumState\n\"$textState\"";
                  Share.share(verseToShare);
                }
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.edit_note),
              // Icône plus spécifique pour les notes
              label: Text("Note"),
              // Plus court
              onPressed: showNoteDialog,
            ),
          ],
        ),
      ),
    );
  }
}
