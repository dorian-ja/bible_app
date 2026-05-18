import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/database_service.dart';
import '../utils/prayer_constants.dart';

class PrayerCard extends StatelessWidget {
  final Prayer prayer;
  final PrayerCategory? category;
  final VoidCallback onEdit;
  final VoidCallback onToggleAnswered;
  final VoidCallback onDelete;

  const PrayerCard({
    super.key,
    required this.prayer,
    this.category,
    required this.onEdit,
    required this.onToggleAnswered,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = prayerPriorityColors[prayer.priority];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: category != null
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: hexToColor(category!.color),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        title: Row(
          children: [
            Expanded(
              child: Text(
                prayer.title,
                style: GoogleFonts.lora(
                  fontWeight: FontWeight.bold,
                  decoration: prayer.isAnswered ? TextDecoration.lineThrough : null,
                  color: prayer.isAnswered ? Colors.grey : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor?.withAlpha(51),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                prayerPriorityLabels[prayer.priority] ?? 'Normale',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: priorityColor,
                ),
              ),
            ),
          ],
        ),
        children: [
          if (prayer.description?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  prayer.description!,
                  style: TextStyle(color: Colors.grey[700], height: 1.4),
                ),
              ),
            ),
          StreamBuilder<List<Verse>>(
            stream: DatabaseService.db.watchPrayerVerses(prayer.id),
            builder: (context, snapshot) {
              final linked = snapshot.data ?? const [];
              if (linked.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: Colors.brown.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.brown.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final v in linked)
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: v == linked.last ? 0 : 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.menu_book_outlined,
                                size: 14, color: Colors.brown),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${v.book} ${v.chapter}:${v.verse}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    v.textContent,
                                    style: GoogleFonts.lora(
                                        fontSize: 12,
                                        color: Colors.brown.shade700,
                                        height: 1.4),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.close, size: 16,
                                  color: Colors.brown),
                              tooltip: 'Retirer ce verset',
                              padding: EdgeInsets.zero,
                              constraints:
                                  const BoxConstraints(minWidth: 28, minHeight: 28),
                              onPressed: () => DatabaseService.db
                                  .removeVerseFromPrayer(prayer.id, v.id),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Row(
            children: [
              if (category != null)
                Chip(
                  avatar: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: hexToColor(category!.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  label: Text(category!.name, style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              const Spacer(),
              Text(
                '${prayer.dateAdded.day}/${prayer.dateAdded.month}/${prayer.dateAdded.year}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: Icon(
                  prayer.isAnswered ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: prayer.isAnswered ? Colors.green : null,
                ),
                label: Text(
                  prayer.isAnswered ? 'Exaucée' : 'En attente',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onToggleAnswered();
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                onPressed: onEdit,
              ),
              TextButton.icon(
                icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
                label: Text('Supprimer',
                    style: TextStyle(fontSize: 12, color: Colors.red[400])),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onDelete();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
