import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/canonical_books.dart';

class PlanDeLecturePage extends StatefulWidget {
  final Function(String book, String chapter)? onChapterTap;

  const PlanDeLecturePage({super.key, this.onChapterTap});

  @override
  State<PlanDeLecturePage> createState() => _PlanDeLecturePageState();
}

class _PlanDeLecturePageState extends State<PlanDeLecturePage> {
  List<String> _books = [];
  Map<String, List<String>> _chapters = {};
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

    // Tri canonique des livres
    final sorted = sortBooksCanonically(decoded.keys.toList());

    final Map<String, List<String>> chapters = {};
    int count = 0;
    for (final book in sorted) {
      final chaptersMap = decoded[book] as Map<String, dynamic>;
      final chs = chaptersMap.keys.toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      chapters[book] = chs;
      count += chs.length;
    }

    if (mounted) {
      setState(() {
        _books = sorted;
        _chapters = chapters;
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

  /// none = 0 chapitres lus, partial = quelques-uns, full = tous
  _BookReadState _bookReadState(String book) {
    final chs = _chapters[book] ?? [];
    if (chs.isEmpty) return _BookReadState.none;
    final readCount = chs.where((ch) => _readChapters.contains('$book|$ch')).length;
    if (readCount == 0) return _BookReadState.none;
    if (readCount == chs.length) return _BookReadState.full;
    return _BookReadState.partial;
  }

  @override
  Widget build(BuildContext context) {
    if (_books.isEmpty) return const Center(child: CircularProgressIndicator());

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
            itemCount: _books.length,
            itemBuilder: (context, index) {
              final book = _books[index];
              final chapters = _chapters[book] ?? [];
              final bookState = _bookReadState(book);

              return ExpansionTile(
                title: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => DatabaseService.toggleBookReadStatus(book),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          bookState == _BookReadState.full
                              ? Icons.check_box
                              : bookState == _BookReadState.partial
                                  ? Icons.indeterminate_check_box
                                  : Icons.check_box_outline_blank,
                          color: bookState == _BookReadState.none
                              ? Colors.grey
                              : Colors.indigo,
                          size: 22,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        book,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${chapters.where((ch) => _readChapters.contains('$book|$ch')).length}/${chapters.length}',
                      style: TextStyle(
                        fontSize: 13,
                        color: bookState == _BookReadState.full
                            ? Colors.indigo
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                children: chapters.map((ch) {
                  final key = '$book|$ch';
                  final isRead = _readChapters.contains(key);
                  return ListTile(
                    title: Text('Chapitre $ch'),
                    onTap: () => widget.onChapterTap?.call(book, ch),
                    trailing: Checkbox(
                      value: isRead,
                      activeColor: Colors.indigo,
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

enum _BookReadState { none, partial, full }
