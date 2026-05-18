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

/// Renvoie une couleur de texte lisible sur un fond surligné.
///
/// Les couleurs de surlignage [kNoteColorOptions] sont toutes des pastels
/// clairs : du texte clair (mode sombre par défaut) y est illisible. Si le
/// fond est défini on force une teinte sombre ; sinon on rend la couleur
/// par défaut du thème pour rester adaptatif.
Color? readableTextOn(Color? highlight, BuildContext context) {
  if (highlight == null) return null;
  return const Color(0xDD000000); // ~87 % opaque, comme un onSurface clair
}
