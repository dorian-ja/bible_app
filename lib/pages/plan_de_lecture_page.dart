// lib/pages/plan_de_lecture_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/isar_service.dart';

class PlanDeLecturePage extends StatefulWidget {
  final Function(String book, String chapter)? onChapterTap;

  const PlanDeLecturePage({Key? key, this.onChapterTap}) : super(key: key);

  @override
  _PlanDeLecturePageState createState() => _PlanDeLecturePageState();
}

class _PlanDeLecturePageState extends State<PlanDeLecturePage>
    with WidgetsBindingObserver {
  Map<String, dynamic> bibleData = {};
  Set<String> _readChapterKeysFromIsar = {};
  StreamSubscription? _readChaptersSubscriptionIsar;

  int totalChapitres = 0;
  bool showOnlyUnread = false;
  bool allExpanded = false;

  Map<String, ExpansionTileController> _expansionTileControllers = {};
  int _globalExpansionCounter = 0; // Pour forcer la réinitialisation des clés

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadBible().then((_) {
      _initializeExpansionTileControllers();
      _subscribeToReadChapterKeysIsar();
      _loadUiPreferences();
    });
  }

  void _initializeExpansionTileControllers() {
    if (bibleData.isNotEmpty) {
      _expansionTileControllers = {
        for (var book in bibleData.keys) book: ExpansionTileController(),
      };
      // Pas besoin d'appeler _updateControllersToMatchAllExpandedState ici
      // car _loadUiPreferences le fera après avoir chargé allExpanded.
    }
  }

  void _updateControllersToMatchAllExpandedState() {
    // Cette fonction est appelée par _loadUiPreferences et didChangeAppLifecycleState
    // pour synchroniser les contrôleurs avec l'état `allExpanded` sauvegardé/actuel.
    // Elle est moins cruciale si on change les clés, mais la garder ne nuit pas.
    _expansionTileControllers.forEach((book, controller) {
      if (allExpanded) {
        if (!controller.isExpanded) {
          controller.expand();
        }
      } else {
        if (controller.isExpanded) {
          controller.collapse();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _readChaptersSubscriptionIsar?.cancel();
    for (var controller in _expansionTileControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      debugPrint(
        "PlanDeLecturePage: App resumed. Re-subscribing to read status (Isar) & loading UI prefs.",
      );
      _subscribeToReadChapterKeysIsar();
      _loadUiPreferences().then((_) {
        // On s'assure que les contrôleurs sont synchronisés si l'état allExpanded a changé
        // pendant que l'app était en pause (improbable mais possible).
        // Le changement de clé dans toggleAllExpanded est le principal mécanisme
        // pour les actions de l'utilisateur.
        if (_expansionTileControllers.isNotEmpty) {
          _updateControllersToMatchAllExpandedState();
        }
      });
    }
  }

  Future<void> _loadUiPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      final bool savedAllExpanded = prefs.getBool('plan_all_expanded') ?? false;
      if (allExpanded != savedAllExpanded) {
        allExpanded = savedAllExpanded;
        _globalExpansionCounter++; // S'assurer que les clés changent si l'état initial a été restauré
      }
      setState(() {});

      if (_expansionTileControllers.isNotEmpty) {
        _updateControllersToMatchAllExpandedState();
      }
    }
  }

  Future<void> loadBible() async {
    final String data = await rootBundle.loadString('assets/bible.json');
    final Map<String, dynamic> decoded = json.decode(data);
    int total = 0;
    decoded.forEach((book, chapters) {
      total += (chapters as Map<String, dynamic>).length;
    });
    if (mounted) {
      bibleData = decoded;
      totalChapitres = total;
      // Initialiser les contrôleurs ici après que bibleData soit chargé et avant le premier build.
      if (_expansionTileControllers.isEmpty && bibleData.isNotEmpty) {
        _initializeExpansionTileControllers();
      }
      setState(() {});
    }
  }

  void _subscribeToReadChapterKeysIsar() {
    _readChaptersSubscriptionIsar?.cancel();
    _readChaptersSubscriptionIsar = IsarService.watchAllFullyReadChapterKeys()
        .listen(
          (Set<String> readKeys) {
            if (mounted) {
              if (_readChapterKeysFromIsar.length != readKeys.length ||
                  !_readChapterKeysFromIsar.containsAll(readKeys) ||
                  !readKeys.containsAll(_readChapterKeysFromIsar)) {
                setState(() {
                  _readChapterKeysFromIsar = readKeys;
                });
              }
            }
          },
          onError: (error) {
            debugPrint(
              "PlanDeLecturePage: Error in watchAllFullyReadChapterKeys stream: $error",
            );
            if (mounted) {
              setState(() {
                _readChapterKeysFromIsar = {};
              });
            }
          },
        );
  }

  Future<void> toggleLu(String book, String chapterStr) async {
    final int? chapterNum = int.tryParse(chapterStr);
    if (chapterNum == null) return;
    await IsarService.toggleChapterReadStatus(book, chapterNum);
  }

  Future<void> resetProgression() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Réinitialiser la progression ?'),
          content: const Text(
            'Toute votre progression de lecture sera effacée. Cette action est irréversible.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Réinitialiser',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await IsarService.resetAllReadStatus();
    }
  }

  Future<void> toggleAllExpanded() async {
    final newAllExpandedState = !allExpanded;
    debugPrint(
      "PlanDeLecturePage: toggleAllExpanded START - Current allExpanded: $allExpanded, New desired state: $newAllExpandedState",
    );
    final prefs = await SharedPreferences.getInstance();

    allExpanded = newAllExpandedState;
    await prefs.setBool('plan_all_expanded', allExpanded);

    _globalExpansionCounter++; // Force le changement de clé pour les ExpansionTiles

    // Les commandes expand/collapse sur les contrôleurs sont toujours utiles pour
    // assurer que leur état interne est cohérent, même si la clé change.
    _expansionTileControllers.forEach((book, controller) {
      if (newAllExpandedState) {
        if (!controller.isExpanded) {
          controller.expand();
        }
      } else {
        if (controller.isExpanded) {
          controller.collapse();
        }
      }
    });

    if (mounted) {
      // Pas besoin de postFrameCallback ici si le changement de clé fait le travail.
      // Un simple setState suffit pour reconstruire avec les nouvelles clés et le nouvel état allExpanded.
      debugPrint(
        "PlanDeLecturePage: toggleAllExpanded - Triggering setState. Current allExpanded: $allExpanded, globalCounter: $_globalExpansionCounter",
      );
      setState(() {});
    }
    debugPrint(
      "PlanDeLecturePage: toggleAllExpanded END - Commanded all to $newAllExpandedState. Global allExpanded: $allExpanded. setState triggered.",
    );
  }

  @override
  Widget build(BuildContext context) {
    final int chapitresLusCount = _readChapterKeysFromIsar.length;

    if (bibleData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    // S'assurer que les contrôleurs sont initialisés si ce n'est pas déjà fait
    if (_expansionTileControllers.isEmpty && bibleData.isNotEmpty) {
      _initializeExpansionTileControllers();
      _updateControllersToMatchAllExpandedState(); // S'assurer qu'ils sont synchronisés avec l'état `allExpanded` initial
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progression : $chapitresLusCount / $totalChapitres chapitres lus',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: totalChapitres == 0
                    ? 0.0
                    : chapitresLusCount / totalChapitres,
                backgroundColor: Colors.grey[300],
                color: Colors.indigo,
                minHeight: 8,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Afficher seulement non lus'),
                  Switch(
                    value: showOnlyUnread,
                    onChanged: (value) {
                      if (mounted) {
                        setState(() {
                          showOnlyUnread = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: resetProgression,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Réinitialiser"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: toggleAllExpanded,
                    icon: Icon(
                      allExpanded ? Icons.unfold_less : Icons.unfold_more,
                    ),
                    label: Text(
                      allExpanded ? "Réduire tout" : "Développer tout",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: bibleData.keys.length,
            itemBuilder: (context, index) {
              final book = bibleData.keys.elementAt(index);
              final chaptersData = bibleData[book] as Map<String, dynamic>;
              final List<String> chapters = chaptersData.keys.toList();
              chapters.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

              final visibleChapters = chapters.where((chapter) {
                final key = '$book|$chapter';
                return !showOnlyUnread ||
                    !_readChapterKeysFromIsar.contains(key);
              }).toList();

              final lusDansLivre = chapters
                  .where((ch) => _readChapterKeysFromIsar.contains('$book|$ch'))
                  .length;
              final totalDansLivre = chapters.length;
              final progress = totalDansLivre == 0
                  ? 0.0
                  : lusDansLivre / totalDansLivre;

              if (showOnlyUnread && visibleChapters.isEmpty) {
                return const SizedBox.shrink();
              }

              final controller = _expansionTileControllers[book];
              if (controller == null) {
                debugPrint(
                  "ERREUR FATALE: Contrôleur non trouvé pour le livre $book dans build.",
                );
                return SizedBox.shrink();
              }

              Key tileKey = ValueKey<String>("$book$_globalExpansionCounter");
              debugPrint(
                "PlanDeLecturePage: Building ExpansionTile for $book. Key: $tileKey, controller.isExpanded: ${controller.isExpanded}, global allExpanded: $allExpanded (avant return ExpansionTile)",
              );

              return ExpansionTile(
                key: tileKey,
                // Utilise la clé dynamique
                controller: controller,
                initiallyExpanded: allExpanded,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      color: Colors.indigo,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$lusDansLivre / $totalDansLivre chapitres lus',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                children: visibleChapters.map((chapter) {
                  final key = '$book|$chapter';
                  final isLu = _readChapterKeysFromIsar.contains(key);
                  return CheckboxListTile(
                    title: Text('Chapitre $chapter'),
                    value: isLu,
                    onChanged: (_) {
                      if (widget.onChapterTap != null) {
                        widget.onChapterTap!(book, chapter);
                      }
                      toggleLu(book, chapter);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
