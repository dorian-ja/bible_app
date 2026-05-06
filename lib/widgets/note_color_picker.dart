import 'package:flutter/material.dart';
import '../utils/note_colors.dart';

class NoteColorPicker extends StatelessWidget {
  final String? selectedHex;
  final ValueChanged<String?> onChanged;

  const NoteColorPicker({super.key, required this.selectedHex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: kNoteColorOptions.map((option) {
        final color = parseNoteColor(option.hex);
        final isSelected = option.hex == selectedHex;
        return GestureDetector(
          onTap: () => onChanged(option.hex),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color ?? Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.indigo : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: color == null
                ? const Icon(Icons.format_color_reset, size: 18, color: Colors.grey)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
