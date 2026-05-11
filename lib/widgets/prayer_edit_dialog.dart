import 'package:flutter/material.dart';
import '../database/database.dart';
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

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.prayer?.title ?? '');
    descriptionController = TextEditingController(text: widget.prayer?.description ?? '');
    selectedPriority = widget.prayer?.priority ?? 1;
    selectedCategoryId = widget.prayer?.categoryId;
    hasReminder = widget.prayer?.hasReminder ?? false;
    reminderTime = widget.prayer?.reminderTime;
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
            DropdownButtonFormField<int?>(
              value: selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Catégorie (optionnel)',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Aucune catégorie'),
                ),
                ...widget.categories.map((cat) => DropdownMenuItem<int?>(
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
