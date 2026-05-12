import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
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
  late final Stream<List<PrayerCategory>> _categoriesStream;
  late Stream<List<Prayer>> _filteredStream;

  String searchQuery = '';
  int? selectedCategoryFilter;
  bool showAnsweredOnly = false;
  bool showUnansweredOnly = false;

  @override
  void initState() {
    super.initState();
    _categoriesStream = DatabaseService.db.watchAllCategories();
    _rebuildStream();
  }

  void _rebuildStream() {
    _filteredStream = DatabaseService.db.watchFilteredPrayers(
      isAnswered: showAnsweredOnly ? true : (showUnansweredOnly ? false : null),
      categoryId: selectedCategoryFilter,
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
    );
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
              final newId = await DatabaseService.db.insertPrayer(
                title,
                description,
                priority: priority,
                categoryId: categoryId,
                hasReminder: hasReminder,
                reminderTime: reminderTime,
              );
              if (hasReminder && reminderTime != null) {
                await NotificationService.schedulePrayerReminder(newId, title, reminderTime);
              }
            } else {
              await DatabaseService.db.updatePrayer(prayer.copyWith(
                title: title,
                description: Value(description.isEmpty ? null : description),
                priority: priority,
                categoryId: Value(categoryId),
                hasReminder: hasReminder,
                reminderTime: Value(reminderTime),
              ));
              if (hasReminder && reminderTime != null) {
                await NotificationService.schedulePrayerReminder(prayer.id, title, reminderTime);
              } else {
                await NotificationService.cancelPrayerReminder(prayer.id);
              }
            }
          },
        ),
      );
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
        ],
      ),
      body: StreamBuilder<List<PrayerCategory>>(
        stream: _categoriesStream,
        builder: (context, catSnapshot) {
          final categories = catSnapshot.data ?? [];
          final categoriesMap = {for (final c in categories) c.id: c};

          return Column(
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
                  onChanged: (value) => setState(() {
                    searchQuery = value;
                    _rebuildStream();
                  }),
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
                        _rebuildStream();
                      }),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('En attente'),
                      selected: showUnansweredOnly,
                      onSelected: (selected) => setState(() {
                        showUnansweredOnly = selected;
                        showAnsweredOnly = false;
                        _rebuildStream();
                      }),
                    ),
                    const SizedBox(width: 8),
                    DropdownMenu<int?>(
                      key: ValueKey(categories.map((c) => c.id).join(',')),
                      initialSelection: selectedCategoryFilter,
                      onSelected: (value) => setState(() {
                        selectedCategoryFilter = value;
                        _rebuildStream();
                      }),
                      dropdownMenuEntries: [
                        const DropdownMenuEntry<int?>(value: null, label: 'Toutes catégories'),
                        ...categories.map((cat) => DropdownMenuEntry<int?>(
                              value: cat.id,
                              label: cat.name,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Liste des prières
              Expanded(
                child: StreamBuilder<List<Prayer>>(
                  stream: _filteredStream,
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
                        return PrayerCard(
                          prayer: prayer,
                          category: prayer.categoryId != null ? categoriesMap[prayer.categoryId] : null,
                          onEdit: () => _showPrayerDialog(prayer: prayer),
                          onToggleAnswered: () => DatabaseService.db.togglePrayerAnswered(prayer),
                          onDelete: () => _confirmDelete(prayer.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
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
            onPressed: () async {
              await NotificationService.cancelPrayerReminder(prayerId);
              await DatabaseService.db.deletePrayer(prayerId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
