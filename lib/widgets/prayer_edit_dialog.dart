import 'package:flutter/material.dart';
import '../database/database.dart';
import '../services/database_service.dart';
import '../utils/prayer_constants.dart';
import 'reminder_time_selector.dart';

class PrayerEditDialog extends StatefulWidget {
  final Prayer? prayer;
  final List<PrayerCategory> categories;
  final Function(String title, String description, int priority, int? categoryId, bool hasReminder, DateTime? reminderTime) onSave;

  const PrayerEditDialog({
    super.key,
    this.prayer,
    required this.categories,
    required this.onSave,
  });

  @override
  State<PrayerEditDialog> createState() => _PrayerEditDialogState();
}

class _PrayerEditDialogState extends State<PrayerEditDialog> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late int selectedPriority;
  late int? selectedCategoryId;
  late bool hasReminder;
  late DateTime? reminderTime;
  late List<PrayerCategory> _categories;

  static const _colorOptions = [
    ('Bleu', '0xFF42A5F5'),
    ('Vert', '0xFF66BB6A'),
    ('Orange', '0xFFFFA726'),
    ('Violet', '0xFFAB47BC'),
    ('Rouge', '0xFFEF5350'),
    ('Jaune', '0xFFFFEE58'),
    ('Rose', '0xFFEC407A'),
    ('Cyan', '0xFF26C6DA'),
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.prayer?.title ?? '');
    descriptionController = TextEditingController(text: widget.prayer?.description ?? '');
    selectedPriority = widget.prayer?.priority ?? 1;
    selectedCategoryId = widget.prayer?.categoryId;
    hasReminder = widget.prayer?.hasReminder ?? false;
    reminderTime = widget.prayer?.reminderTime;
    _categories = List.of(widget.categories);
  }

  Future<void> _showNewCategoryDialog() async {
    final nameController = TextEditingController();
    String selectedColor = _colorOptions.first.$2;

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nouvelle catégorie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorOptions.map((option) {
                  final color = hexToColor(option.$2);
                  final isSelected = selectedColor == option.$2;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = option.$2),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(width: 3, color: Colors.black54) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final id = await DatabaseService.db.insertCategory(
                  nameController.text.trim(),
                  selectedColor,
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
                if (mounted) {
                  setState(() {
                    _categories.add(PrayerCategory(id: id, name: nameController.text.trim(), color: selectedColor));
                    selectedCategoryId = id;
                  });
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.prayer == null ? 'Nouvelle prière' : 'Modifier la prière'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Sujet *',
                hintText: 'Ex: Pour ma santé, Guidance professionnelle...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Détails (optionnel)',
                hintText: 'Contexte ou détails de cette prière...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priorité',
                border: OutlineInputBorder(),
              ),
              items: prayerPriorityLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => selectedPriority = value ?? 1),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Aucune catégorie'),
                      ),
                      ..._categories.map((cat) => DropdownMenuItem<int?>(
                            value: cat.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: hexToColor(cat.color),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(cat.name),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (value) => setState(() => selectedCategoryId = value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Nouvelle catégorie',
                  onPressed: _showNewCategoryDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReminderTimeSelector(
              initialTime: reminderTime,
              initialHasReminder: hasReminder,
              onChanged: (hasRem, time) {
                setState(() {
                  hasReminder = hasRem;
                  reminderTime = time;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (titleController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Le sujet est obligatoire')),
              );
              return;
            }
            widget.onSave(
              titleController.text.trim(),
              descriptionController.text.trim(),
              selectedPriority,
              selectedCategoryId,
              hasReminder,
              reminderTime,
            );
            if (mounted) Navigator.pop(context);
          },
          child: Text(widget.prayer == null ? 'Ajouter' : 'Modifier'),
        ),
      ],
    );
  }
}
