import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/database_service.dart';
import '../widgets/prayer_edit_dialog.dart';
import '../widgets/prayer_card.dart';
import 'prayer_stats_page.dart';
import 'package:drift/drift.dart' hide Column;

class CarnetDePrieresPage extends StatefulWidget {
  const CarnetDePrieresPage({super.key});

  @override
  State<CarnetDePrieresPage> createState() => _CarnetDePrieresPageState();
}

class _CarnetDePrieresPageState extends State<CarnetDePrieresPage> {
  late final Stream<List<Prayer>> _prayersStream;
  late final Stream<List<PrayerCategory>> _categoriesStream;
  
  String searchQuery = '';
  int? selectedCategoryFilter;
  bool showAnsweredOnly = false;
  bool showUnansweredOnly = false;

  @override
  void initState() {
    super.initState();
    _prayersStream = DatabaseService.db.watchAllPrayers();
    _categoriesStream = DatabaseService.db.watchAllCategories();
  }

  void _showPrayerDialog({Prayer? prayer}) {
    _categoriesStream.first.then((categories) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => PrayerEditDialog(
          prayer: prayer,
          categories: categories,
          onSave: (title, description, priority, categoryId, hasReminder, reminderTime) async {
            if (prayer == null) {
              await DatabaseService.db.insertPrayer(
                title,
                description,
                priority: priority,
                categoryId: categoryId,
                hasReminder: hasReminder,
                reminderTime: reminderTime,
              );
            } else {
              await DatabaseService.db.updatePrayer(prayer.copyWith(
                title: title,
                description: Value(description.isEmpty ? null : description),
                priority: priority,
                categoryId: Value(categoryId),
                hasReminder: hasReminder,
                reminderTime: Value(reminderTime),
              ));
            }
          },
        ),
      );
    });
  }

  Stream<List<Prayer>> _getFilteredPrayers() {
    return _prayersStream.asyncMap((prayers) async {
      var filtered = prayers;

      // Filtre par statut
      if (showAnsweredOnly) {
        filtered = filtered.where((p) => p.isAnswered).toList();
      } else if (showUnansweredOnly) {
        filtered = filtered.where((p) => !p.isAnswered).toList();
      }

      // Filtre par catégorie
      if (selectedCategoryFilter != null) {
        filtered = filtered.where((p) => p.categoryId == selectedCategoryFilter).toList();
      }

      // Recherche
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        filtered = filtered
            .where((p) => p.title.toLowerCase().contains(query) || (p.description?.toLowerCase().contains(query) ?? false))
            .toList();
      }

      return filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carnet de prières', style: GoogleFonts.lora()),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Statistiques',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrayerStatsPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une prière',
            onPressed: () => _showPrayerDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une prière...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          // Filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Exaucées'),
                  selected: showAnsweredOnly,
                  onSelected: (selected) => setState(() {
                    showAnsweredOnly = selected;
                    showUnansweredOnly = false;
                  }),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('En attente'),
                  selected: showUnansweredOnly,
                  onSelected: (selected) => setState(() {
                    showUnansweredOnly = selected;
                    showAnsweredOnly = false;
                  }),
                ),
                const SizedBox(width: 8),
                StreamBuilder<List<PrayerCategory>>(
                  stream: _categoriesStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final categories = snapshot.data!;
                    return DropdownMenu<int?>(
                      initialSelection: selectedCategoryFilter,
                      onSelected: (value) => setState(() => selectedCategoryFilter = value),
                      dropdownMenuEntries: [
                        const DropdownMenuEntry<int?>(value: null, label: 'Toutes catégories'),
                        ...categories.map((cat) => DropdownMenuEntry<int?>(
                              value: cat.id,
                              label: cat.name,
                            )),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Liste des prières
          Expanded(
            child: StreamBuilder<List<Prayer>>(
              stream: _getFilteredPrayers(),
              builder: (context, snapshot) {
                final prayers = snapshot.data ?? [];
                if (prayers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty ? 'Aucune prière trouvée' : 'Aucune prière pour l\'instant',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: prayers.length,
                  itemBuilder: (context, i) {
                    final prayer = prayers[i];
                    return StreamBuilder<PrayerCategory?>(
                      stream: prayer.categoryId != null
                          ? DatabaseService.db.watchAllCategories().map((cats) {
                              try {
                                return cats.firstWhere((c) => c.id == prayer.categoryId);
                              } catch (e) {
                                return null;
                              }
                            })
                          : Stream.value(null),
                      builder: (context, catSnapshot) {
                        return PrayerCard(
                          prayer: prayer,
                          category: catSnapshot.data,
                          onEdit: () => _showPrayerDialog(prayer: prayer),
                          onToggleAnswered: () => DatabaseService.db.togglePrayerAnswered(prayer),
                          onDelete: () => _confirmDelete(prayer.id),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPrayerDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(int prayerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette prière ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              DatabaseService.db.deletePrayer(prayerId);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
