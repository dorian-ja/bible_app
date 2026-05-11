import 'package:flutter/material.dart';

// Palettes de couleurs disponibles pour les catégories
const List<Color> prayerCategoryColors = [
  Color(0xFFB39DDB), // Violet
  Color(0xFF81C784), // Vert
  Color(0xFFFFB74D), // Orange
  Color(0xFFEF5350), // Rouge
  Color(0xFF4DD0E1), // Cyan
  Color(0xFF64B5F6), // Bleu
  Color(0xFFBA68C8), // Magenta
  Color(0xFFFFA726), // Orange foncé
];

Map<int, String> prayerPriorityLabels = {
  1: 'Normale',
  2: 'Importante',
  3: 'Critique',
};

Map<int, Color> prayerPriorityColors = {
  1: Colors.grey,
  2: Colors.orange,
  3: Colors.red,
};

String colorToHex(Color color) {
  return '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

Color hexToColor(String hexString) {
  try {
    return Color(int.parse(hexString.replaceFirst('0x', ''), radix: 16));
  } catch (e) {
    return prayerCategoryColors[0];
  }
}
