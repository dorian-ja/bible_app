// lib/pages/lecture_page.dart

import 'dart:async';
import 'package:flutter/material.dart';

// import 'package:shared_preferences/shared_preferences.dart'; // SUPPRIMER
import 'package:share_plus/share_plus.dart';
import 'package:isar/isar.dart';
import '../services/isar_service.dart';
import '../models/verse.dart';

class LecturePage extends StatefulWidget {
  final String? initialBook;
  final String? initialChapter;
  final VoidCallback? onRedirectionConsumed;

  // 2. Corrigez le constructeur
  const LecturePage({
    Key? key,
    this.initialBook,
    this.initialChapter,
    this.onRedirectionConsumed, // Rendez-le optionnel
  }) : super(key: key);

  @override
  _LecturePageState createState() => _LecturePageState();
}

class _LecturePageState extends State<LecturePage> {
  final IsarService _isarService = IsarService();

  List<String> _books = [];
  List<String> _chapters = [];
  List<Verse> _chapterVerses = [];

  String? selectedBook;
  String? selectedChapter; // Numéro du chapitre sous forme de String

  bool _isLoading = true;
  bool _isChapterLoading = false;

  StreamSubscription<List<Verse>>? _chapterVersesSubscription;

  // --- NOUVEAU pour l'état "lu" avec Isar ---
  bool _isCurrentChapterReadFromIsar = false; // État local pour l'UI
  StreamSubscription? _chapterReadStatusSubscriptionIsar;

  // --- FIN NOUVEAU ---

  // --- SUPPRIMER l'ancienne gestion SharedPreferences ---
  // Set<String> _readChaptersKeys = {}; // SUPPRIMER
  // Future<void> _loadReadStatus() async { ... } // SUPPRIMER
  // Future<void> _toggleReadStatus(String book, String chapter) async { ... } // SUPPRIMER
  // --- FIN SUPPRESSION ---

  @override
  void initState() {
    super.initState();
    debugPrint("LecturePage: initState");
    _initializePage();
    // _loadReadStatus(); // SUPPRIMER : Sera géré par le watcher Isar
  }

  @override
  void didUpdateWidget(covariant LecturePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.initialBook != null && widget.initialBook != selectedBook) ||
        (widget.initialChapter != null &&
            widget.initialChapter != selectedChapter)) {
      debugPrint(
        "LecturePage didUpdateWidget: Navigation vers ${widget.initialBook} C.${widget.initialChapter}",
      );
      selectedBook = widget.initialBook;
      selectedChapter = widget.initialChapter;
      // L'appel à _loadDataForSelection inclura la mise à jour du watcher pour l'état "lu"
      _loadDataForSelection();
    }
  }

  @override
  void dispose() {
    debugPrint("LecturePage: dispose - Annulation des abonnements.");
    _chapterVersesSubscription?.cancel();
    _chapterReadStatusSubscriptionIsar?.cancel(); // Annuler le nouveau watcher
    super.dispose();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _initializePage() async {
    setStateIfMounted(() => _isLoading = true);
    await _loadBooks();
    if (_books.isNotEmpty) {
      selectedBook = widget.initialBook ?? _books.first;
      await _loadChaptersForBook(selectedBook!);
      if (_chapters.isNotEmpty) {
        selectedChapter = widget.initialChapter ?? _chapters.first;
        // _loadAndWatchVersesForChapter et _subscribeToChapterReadStatusIsar
        // seront appelés ensemble, soit ici, soit via _loadDataForSelection.
        // Pour la première initialisation, il est bon de les appeler.
        await _loadAndWatchVersesForChapter(selectedBook!, selectedChapter!);
        _subscribeToChapterReadStatusIsar(
          selectedBook!,
          selectedChapter!,
        ); // S'abonner pour l'état "lu"
      } else {
        selectedChapter = null;
        _chapterVerses = [];
        _chapterReadStatusSubscriptionIsar
            ?.cancel(); // S'il n'y a pas de chapitre, pas besoin de watcher
        _isCurrentChapterReadFromIsar = false; // Réinitialiser
      }
    }
    setStateIfMounted(() => _isLoading = false);
    widget.onRedirectionConsumed?.call();
  }

  Future<void> _loadDataForSelection() async {
    if (selectedBook == null) {
      setStateIfMounted(() {
        _chapters = [];
        _chapterVerses = [];
        selectedChapter = null;
        _isChapterLoading = false;
        _chapterReadStatusSubscriptionIsar?.cancel();
        _isCurrentChapterReadFromIsar = false;
      });
      return;
    }

    setStateIfMounted(() => _isChapterLoading = true);
    await _loadChaptersForBook(selectedBook!);

    if (_chapters.isNotEmpty) {
      if (selectedChapter == null || !_chapters.contains(selectedChapter)) {
        selectedChapter = _chapters.first;
      }
      await _loadAndWatchVersesForChapter(selectedBook!, selectedChapter!);
      _subscribeToChapterReadStatusIsar(
        selectedBook!,
        selectedChapter!,
      ); // Mettre à jour l'abonnement
    } else {
      setStateIfMounted(() {
        selectedChapter = null;
        _chapterVerses = [];
        _chapterVersesSubscription?.cancel();
        _chapterReadStatusSubscriptionIsar?.cancel();
        _isCurrentChapterReadFromIsar = false;
      });
    }
    // _isChapterLoading sera mis à false par le watcher de _loadAndWatchVersesForChapter
    // ou ici si pas de chapitre
    if (_chapters.isEmpty) {
      setStateIfMounted(() => _isChapterLoading = false);
    }
  }

  Future<void> _loadBooks() async {
    // Note: _isarService.getBooks() n'est pas static dans votre IsarService.dart fourni précédemment.
    // Si elle l'est devenue, utilisez IsarService.getBooks(). Sinon, _isarService.getBooks() est correct.
    _books = await _isarService.getBooks();
  }

  Future<void> _loadChaptersForBook(String bookName) async {
    _chapters = await _isarService.getChaptersForBook(bookName);
  }

  Future<void> _loadAndWatchVersesForChapter(
    String bookName,
    String chapterNumberStr,
  ) async {
    // ... (votre code existant est bon, pas de changement ici)
    if (!mounted) return;

    final int? chapterNumber = int.tryParse(chapterNumberStr);
    if (chapterNumber == null) {
      debugPrint("LecturePage: Numéro de chapitre invalide: $chapterNumberStr");
      setStateIfMounted(() {
        _chapterVerses = [];
        _isChapterLoading = false;
      });
      return;
    }

    setStateIfMounted(() => _isChapterLoading = true);

    await _chapterVersesSubscription?.cancel();
    _chapterVersesSubscription = null;

    final isar = await IsarService.db;
    final query = isar.verses
        .filter()
        .bookEqualTo(bookName)
        .and()
        .chapterEqualTo(chapterNumber)
        .sortByVerse();

    _chapterVersesSubscription = query
        .watch(fireImmediately: true)
        .listen(
          (updatedVerses) {
            if (!mounted) return;
            debugPrint(
              "LecturePage (Watcher): ${updatedVerses.length} versets reçus pour $bookName $chapterNumber. Changement détecté.",
            );
            setStateIfMounted(() {
              _chapterVerses = updatedVerses;
              if (_isLoading) _isLoading = false;
              if (_isChapterLoading) _isChapterLoading = false;
            });
          },
          onError: (e, s) {
            debugPrint(
              "LecturePage (Watcher): Erreur dans le stream des versets: $e\n$s",
            );
            if (mounted) {
              setStateIfMounted(() {
                _chapterVerses = [];
                _isChapterLoading = false;
              });
            }
          },
        );
  }

  // --- NOUVELLES MÉTHODES POUR L'ÉTAT "LU" AVEC ISAR ---
  void _subscribeToChapterReadStatusIsar(String book, String chapterStr) {
    _chapterReadStatusSubscriptionIsar
        ?.cancel(); // Annuler l'ancienne souscription

    final int? chapterNum = int.tryParse(chapterStr);
    if (chapterNum == null) {
      debugPrint(
        "LecturePage: Impossible de s'abonner à l'état lu, chapitre invalide: $chapterStr",
      );
      setStateIfMounted(() => _isCurrentChapterReadFromIsar = false);
      return;
    }

    _chapterReadStatusSubscriptionIsar =
        IsarService.watchChapterReadStatus(book, chapterNum).listen(
          (isRead) {
            if (mounted) {
              setState(() {
                _isCurrentChapterReadFromIsar = isRead;
                debugPrint(
                  "LecturePage: Statut 'lu' pour $book $chapterNum mis à jour par watcher: $isRead",
                );
              });
            }
          },
          onError: (error) {
            debugPrint(
              "LecturePage: Erreur dans le stream watchChapterReadStatus: $error",
            );
            if (mounted) {
              setState(() {
                _isCurrentChapterReadFromIsar =
                    false; // Valeur par défaut en cas d'erreur
              });
            }
          },
        );
  }

  Future<void> _toggleCurrentChapterReadStatusIsar() async {
    if (selectedBook == null || selectedChapter == null) return;

    final int? chapterNum = int.tryParse(selectedChapter!);
    if (chapterNum == null) {
      debugPrint(
        "LecturePage: Impossible de basculer l'état lu, chapitre invalide: $selectedChapter",
      );
      return;
    }

    debugPrint(
      "LecturePage: Bascule de l'état 'lu' pour $selectedBook! $chapterNum via IsarService.",
    );
    await IsarService.toggleChapterReadStatus(selectedBook!, chapterNum);
    // Le watcher _chapterReadStatusSubscriptionIsar mettra à jour l'état _isCurrentChapterReadFromIsar
  }

  // --- FIN NOUVELLES MÉTHODES ISAR ---

  Future<void> _toggleFavoriteInPage(Verse verseToToggle) async {
    // ... (votre code existant est bon)
    Verse? updatedVerse = await _isarService.toggleFavorite(verseToToggle);
    if (updatedVerse != null) {
      debugPrint(
        "LecturePage: Favori basculé via service pour ID ${updatedVerse.id}. Le watcher devrait mettre à jour l'UI.",
      );
    } else {
      debugPrint(
        "LecturePage: Erreur lors du toggle du favori via service pour ID ${verseToToggle.id}.",
      );
    }
  }

  void showNoteDialogForVerse(Verse verse) {
    // ... (votre code existant est bon)
    if (verse.id == Isar.autoIncrement || verse.id < 1) {
      debugPrint(
        "LecturePage: showNoteDialog - ID de verset invalide (${verse.id}). Impossible d'ajouter/modifier la note.",
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ID du verset invalide.")));
      return;
    }

    final String initialNoteText = verse.noteText ?? '';
    final Color? initialNoteColor = verse.noteColorAsColor;

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
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulBuilderContext, setStateDialog) {
            return AlertDialog(
              title: Text(
                "Note pour ${verse.book} ${verse.chapter}:${verse.verse}",
              ),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("Annuler"),
                ),
                TextButton(
                  onPressed: () async {
                    final String newText = controller.text.trim();
                    final String? newColorHex = selectedDialogColor != null
                        ? '#${selectedDialogColor!.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
                        : null;
                    Verse? updatedVerse = await _isarService.updateVerseNote(
                      verse,
                      newText.isEmpty ? null : newText,
                      newColorHex,
                    );
                    if (updatedVerse != null) {
                      debugPrint("LecturePage: Note sauvegardée via Isar.");
                    } else {
                      debugPrint(
                        "LecturePage: ERREUR sauvegarde note via Isar pour ID ${verse.id}.",
                      );
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text("Erreur sauvegarde note.")),
                      );
                    }
                    Navigator.pop(dialogContext);
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

  void goToNextChapter() async {
    // ... (votre code existant est bon, _loadDataForSelection gérera le watcher pour "lu")
    if (selectedBook == null ||
        selectedChapter == null ||
        _books.isEmpty ||
        _chapters.isEmpty)
      return;
    final currentBookIndex = _books.indexOf(selectedBook!);
    final currentChapterIndex = _chapters.indexOf(selectedChapter!);
    if (currentChapterIndex < _chapters.length - 1) {
      selectedChapter = _chapters[currentChapterIndex + 1];
    } else if (currentBookIndex < _books.length - 1) {
      selectedBook = _books[currentBookIndex + 1];
      selectedChapter = null;
    } else {
      return;
    }
    await _loadDataForSelection();
  }

  void goToPreviousChapter() async {
    // ... (votre code existant est bon, _loadDataForSelection gérera le watcher pour "lu")
    if (selectedBook == null ||
        selectedChapter == null ||
        _books.isEmpty ||
        _chapters.isEmpty)
      return;
    final currentBookIndex = _books.indexOf(selectedBook!);
    final currentChapterIndex = _chapters.indexOf(selectedChapter!);
    if (currentChapterIndex > 0) {
      selectedChapter = _chapters[currentChapterIndex - 1];
    } else if (currentBookIndex > 0) {
      selectedBook = _books[currentBookIndex - 1];
      selectedChapter = null;
    } else {
      return;
    }
    await _loadDataForSelection();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(key: ValueKey("loaderPrincipal")),
        ),
      );
    }
    if (selectedBook == null || _books.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Lecture")),
        body: Center(child: Text("Aucun livre disponible.")),
      );
    }

    // SUPPRIMER l'ancienne logique pour isCurrentChapterRead
    // final String currentChapterKeyForRead = '$selectedBook|$selectedChapter';
    // bool isCurrentChapterRead = _readChaptersKeys.contains(currentChapterKeyForRead);
    // Utiliser _isCurrentChapterReadFromIsar à la place

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedChapter != null
              ? '$selectedBook $selectedChapter'
              : selectedBook!,
        ),
        // Optionnel: Ajouter le bouton "Lu" ici si vous préférez à un Switch dans le corps
        // actions: [
        //   if (selectedBook != null && selectedChapter != null)
        //     IconButton(
        //       icon: Icon(
        //         _isCurrentChapterReadFromIsar ? Icons.visibility : Icons.visibility_off,
        //         color: _isCurrentChapterReadFromIsar ? Colors.green : Colors.grey,
        //       ),
        //       tooltip: _isCurrentChapterReadFromIsar ? 'Marquer comme non lu' : 'Marquer comme lu',
        //       onPressed: _toggleCurrentChapterReadStatusIsar,
        //     ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    key: ValueKey("dropdownBook"),
                    value: selectedBook,
                    isExpanded: true,
                    hint: Text("Choisir un livre"),
                    items: _books
                        .map(
                          (book) =>
                              DropdownMenuItem(value: book, child: Text(book)),
                        )
                        .toList(),
                    onChanged: (value) async {
                      if (value != null && value != selectedBook) {
                        selectedBook = value;
                        selectedChapter = null;
                        await _loadDataForSelection();
                      }
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    key: ValueKey("dropdownChapter"),
                    value: selectedChapter,
                    isExpanded: true,
                    hint: Text("Chap."),
                    items: _chapters
                        .map(
                          (ch) => DropdownMenuItem(
                            value: ch,
                            child: Text('Ch. $ch'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      if (value != null && value != selectedChapter) {
                        selectedChapter = value;
                        // Pas besoin de recharger tous les chapitres, juste les versets et l'état "lu"
                        if (selectedBook != null && selectedChapter != null) {
                          await _loadAndWatchVersesForChapter(
                            selectedBook!,
                            selectedChapter!,
                          ); // Recharger que les versets
                          _subscribeToChapterReadStatusIsar(
                            selectedBook!,
                            selectedChapter!,
                          ); // Re-souscrire pour le nouveau chapitre
                        } else {
                          await _loadDataForSelection(); // Fallback si selectedChapter devient null
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Switch "Lu" (utilise maintenant _isCurrentChapterReadFromIsar et _toggleCurrentChapterReadStatusIsar)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Lu'),
                Switch(
                  value: _isCurrentChapterReadFromIsar,
                  // UTILISER LA NOUVELLE VARIABLE D'ÉTAT
                  onChanged: (selectedBook != null && selectedChapter != null)
                      ? (value) {
                          _toggleCurrentChapterReadStatusIsar(); // APPELER LA NOUVELLE MÉTHODE
                        }
                      : null,
                ),
              ],
            ),
            Expanded(
              child: _isChapterLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        key: ValueKey("loaderChapitre"),
                      ),
                    )
                  : _chapterVerses.isEmpty
                  ? Center(
                      child: Text(
                        selectedChapter == null
                            ? "Sélectionnez un chapitre."
                            : "Aucun verset pour ce chapitre.",
                      ),
                    )
                  : ListView.builder(
                      key: PageStorageKey("$selectedBook-$selectedChapter"),
                      itemCount: _chapterVerses.length,
                      itemBuilder: (context, index) {
                        final verse = _chapterVerses[index];
                        final String? noteText = verse.noteText;
                        final Color? noteDisplayColor = verse.noteColorAsColor;
                        Color? tileHighlightColor;
                        Color? borderHighlightColor;
                        if (noteDisplayColor != null) {
                          tileHighlightColor = noteDisplayColor.withOpacity(
                            0.05,
                          );
                          borderHighlightColor = noteDisplayColor;
                        }
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color:
                                    borderHighlightColor ?? Colors.transparent,
                                width: 6,
                              ),
                            ),
                            color: tileHighlightColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${verse.verse}. ${verse.text}',
                                style: TextStyle(fontSize: 17, height: 1.5),
                              ),
                              if (noteText != null && noteText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 6.0,
                                    left: 0,
                                  ),
                                  child: Text(
                                    noteText,
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 14,
                                      color:
                                          Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color
                                              ?.withOpacity(0.9) ??
                                          Colors.black54,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_note_outlined,
                                      size: 20,
                                      color: Colors.blueGrey,
                                    ),
                                    tooltip: 'Note',
                                    onPressed: () =>
                                        showNoteDialogForVerse(verse),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      verse.isFavorite
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 20,
                                      color: verse.isFavorite
                                          ? Colors.amber
                                          : Colors.grey,
                                    ),
                                    tooltip: 'Favori',
                                    onPressed: () =>
                                        _toggleFavoriteInPage(verse),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.share,
                                      size: 20,
                                      color: Colors.blueGrey,
                                    ),
                                    tooltip: 'Partager',
                                    onPressed: () {
                                      final textToShare =
                                          "${verse.book} ${verse.chapter}:${verse.verse}\n\"${verse.text}\"";
                                      Share.share(textToShare);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      (_isChapterLoading ||
                          (selectedBook == _books.first &&
                              selectedChapter == _chapters.first))
                      ? null
                      : goToPreviousChapter,
                  icon: Icon(Icons.arrow_back),
                  label: Text('Précédent'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      (_isChapterLoading ||
                          (selectedBook == _books.last &&
                              selectedChapter == _chapters.last))
                      ? null
                      : goToNextChapter,
                  label: Text('Suivant'),
                  icon: Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
