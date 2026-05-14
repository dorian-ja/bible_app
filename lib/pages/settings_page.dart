import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../main.dart' show themeService;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifEnabled = false;
  bool _loading = true;
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await NotificationService.isEnabled();
    if (mounted) {
      setState(() {
        _notifEnabled = enabled;
        _themeMode = themeService.themeMode;
        _fontSize = themeService.bibleFontSize;
        _loading = false;
      });
    }
  }

  Future<void> _exportData() async {
    try {
      final favorites = await DatabaseService.getFavoriteVerses();
      final notes = await DatabaseService.db.watchAnnotatedVerses().first;
      final prayers = await DatabaseService.db.select(DatabaseService.db.prayers).get();

      final data = {
        'exported_at': DateTime.now().toIso8601String(),
        'favorites': favorites.map((v) => {
          'book': v.book,
          'chapter': v.chapter,
          'verse': v.verse,
          'text': v.textContent,
        }).toList(),
        'notes': notes.map((v) => {
          'book': v.book,
          'chapter': v.chapter,
          'verse': v.verse,
          'text': v.textContent,
          'note': v.noteText,
          'color': v.noteColor,
        }).toList(),
        'prayers': prayers.map((p) => {
          'title': p.title,
          'description': p.description,
          'priority': p.priority,
          'is_answered': p.isAnswered,
          'date_added': p.dateAdded.toIso8601String(),
          'date_answered': p.dateAnswered?.toIso8601String(),
          'linked_verse': p.linkedVerseRef,
          'linked_verse_text': p.linkedVerseText,
        }).toList(),
      };

      final json = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final filename =
          'myownbible_export_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(json);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        text: 'Mes données MyOwnBible',
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export : $e')),
        );
      }
    }
  }

  Future<void> _toggleNotif(bool value) async {
    if (value && !kIsWeb) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission de notifications refusée.')),
          );
        }
        return;
      }
    }
    setState(() => _notifEnabled = value);
    await NotificationService.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Rappels du verset du jour',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Activer les rappels'),
                  subtitle: const Text(
                    'Notification à 7h00 (heure française)\n'
                    'Rappel à 12h00 si le verset n\'a pas encore été lu',
                  ),
                  isThreeLine: true,
                  value: _notifEnabled,
                  onChanged: _toggleNotif,
                ),
                const Divider(),
                // ---- Apparence ----
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Apparence',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thème', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('Auto')),
                          ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Clair')),
                          ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Sombre')),
                        ],
                        selected: {_themeMode},
                        onSelectionChanged: (s) async {
                          setState(() => _themeMode = s.first);
                          await themeService.setThemeMode(s.first);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Taille du texte biblique', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('${_fontSize.round()} pt',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.primary,
                              )),
                        ],
                      ),
                      Slider(
                        value: _fontSize,
                        min: 12,
                        max: 26,
                        divisions: 14,
                        label: '${_fontSize.round()} pt',
                        onChanged: (v) async {
                          setState(() => _fontSize = v);
                          await themeService.setBibleFontSize(v);
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '« Voici, les jours viennent, dit le Seigneur Éternel, '
                          'où j\'enverrai la famine dans le pays. »',
                          style: GoogleFonts.lora(fontSize: _fontSize, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                // ---- Export ----
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Données', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Exporter mes données'),
                  subtitle: const Text('Favoris, notes et prières au format JSON'),
                  onTap: _exportData,
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 18,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 6),
                          const Text('Comment cela fonctionne',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 7h00 : invitation à découvrir votre verset du jour.\n'
                        '• 12h00 : rappel envoyé uniquement si le verset n\'a pas '
                        'encore été consulté dans la journée.\n'
                        '• Le verset est considéré comme « lu » dès l\'ouverture '
                        'de l\'onglet « Verset du jour ».',
                        style: const TextStyle(height: 1.4),
                      ),
                      if (kIsWeb) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Sur navigateur web, les rappels apparaissent sous forme '
                            'de bannière à l\'ouverture de l\'application '
                            '(les notifications système ne sont pas possibles sans '
                            'serveur dédié).',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
