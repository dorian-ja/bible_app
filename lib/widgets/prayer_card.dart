import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: prayerPriorityColors[prayer.priority]?.withAlpha(51),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                prayerPriorityLabels[prayer.priority] ?? 'Normale',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: prayerPriorityColors[prayer.priority],
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prayer.description?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  prayer.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Ajoutée: ${prayer.dateAdded.day}/${prayer.dateAdded.month}/${prayer.dateAdded.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
            if (category != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Catégorie: ${category!.name}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  prayer.isAnswered ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: prayer.isAnswered ? Colors.green : null,
                ),
                tooltip: prayer.isAnswered ? 'Exaucée' : 'Marquer comme exaucée',
                onPressed: onToggleAnswered,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Modifier',
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: 'Supprimer',
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}
