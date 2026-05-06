import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class PlanDeLecturePage extends StatefulWidget {
  final Function(String book, String chapter)? onChapterTap;

  const PlanDeLecturePage({super.key, this.onChapterTap});

  @override
  State<PlanDeLecturePage> createState() => _PlanDeLecturePageState();
}

class _PlanDeLecturePageState extends State<PlanDeLecturePage> {
  Map<String, dynamic> bibleData = {};
  Set<String> _readChapters = {};
  StreamSubscription? _planWatcher;
  int totalChapters = 0;

  @override
  void initState() {
    super.initState();
    _initPlan();
  }

  Future<void> _initPlan() async {
    final Map<String, dynamic> decoded = await DatabaseService.getBibleData();
    int count = 0;
    decoded.forEach((_, chapters) => count += (chapters as Map).length);
    
    if (mounted) {
      setState(() {
        bibleData = decoded;
        totalChapters = count;
      });
    }

    _planWatcher = DatabaseService.watchAllFullyReadChapterKeys().listen((keys) {
      if (mounted) setState(() => _readChapters = keys);
    });
  }

  @override
  void dispose() {
    _planWatcher?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (bibleData.isEmpty) return const Center(child: CircularProgressIndicator());

    final int chaptersReadCount = _readChapters.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progression : $chaptersReadCount / $totalChapters chapitres lus',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: totalChapters > 0 ? chaptersReadCount / totalChapters : 0,
                backgroundColor: Colors.grey[300],
                color: Colors.indigo,
                minHeight: 8,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Réinitialiser ?'),
                      content: const Text('Voulez-vous effacer toute votre progression ?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Réinitialiser', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirmed == true) await DatabaseService.resetAllReadStatus();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Réinitialiser la progression"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: bibleData.keys.length,
            itemBuilder: (context, index) {
              final book = bibleData.keys.elementAt(index);
              final chaptersMap = bibleData[book] as Map<String, dynamic>;
              final chapters = chaptersMap.keys.toList();
              chapters.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

              return ExpansionTile(
                title: Text(book, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: chapters.map((ch) {
                  final key = "$book|$ch";
                  final isRead = _readChapters.contains(key);
                  return ListTile(
                    title: Text("Chapitre $ch"),
                    onTap: () => widget.onChapterTap?.call(book, ch),
                    trailing: Checkbox(
                      value: isRead,
                      onChanged: (_) => DatabaseService.toggleChapterReadStatus(book, int.parse(ch)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
