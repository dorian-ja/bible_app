import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kPrefThemeMode = 'theme_mode'; // 0=system, 1=light, 2=dark
const String _kPrefFontSize = 'bible_font_size'; // double

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _bibleFontSize = 18.0;

  ThemeMode get themeMode => _themeMode;
  double get bibleFontSize => _bibleFontSize;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_kPrefThemeMode) ?? 0;
    _themeMode = ThemeMode.values[modeIndex];
    _bibleFontSize = prefs.getDouble(_kPrefFontSize) ?? 18.0;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> setBibleFontSize(double size) async {
    _bibleFontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPrefFontSize, size);
    notifyListeners();
  }
}
