import 'package:flutter/material.dart';

class NoteColorOption {
  final String? hex;
  final String label;
  const NoteColorOption(this.hex, this.label);
}

const List<NoteColorOption> kNoteColorOptions = [
  NoteColorOption(null, 'Aucune'),
  NoteColorOption('#FFF59D', 'Jaune'),
  NoteColorOption('#C8E6C9', 'Vert'),
  NoteColorOption('#BBDEFB', 'Bleu'),
  NoteColorOption('#F8BBD0', 'Rose'),
  NoteColorOption('#FFE0B2', 'Orange'),
];

Color? parseNoteColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length != 6) return null;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}
