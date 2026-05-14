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
  int _atTotalChapters = 0;
  int _ntTotalChapters = 0;

  // Premier livre du NT dans kCanonicalBookOrder
  static const String _kFirstNtBook = 'Matthieu';

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
        // Calculer les totaux AT / NT
        final ntStartIdx = kCanonicalBookOrder.indexOf(_kFirstNtBook);
        _atTotalChapters = 0;
        _ntTotalChapters = 0;
        for (final book in sorted) {
          final bookIdx = kCanonicalBookOrder.indexOf(book);
          final chs = chapters[book]?.length ?? 0;
          if (bookIdx >= 0 && bookIdx < ntStartIdx) {
            _atTotalChapters += chs;
          } else {
            _ntTotalChapters += chs;
          }
        }
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

  int get _atReadChapters {
    final ntStartIdx = kCanonicalBookOrder.indexOf(_kFirstNtBook);
    return _readChapters.where((key) {
      final book = key.split('|').first;
      final idx = kCanonicalBookOrder.indexOf(book);
      return idx >= 0 && idx < ntStartIdx;
    }).length;
  }

  int get _ntReadChapters => _readChapters.length - _atReadChapters;

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

    // Material transparent local : les InkWell peignent sur ce Material-ci
    // (à l'intérieur de l'IndexedStack) et non sur le Material racine du Scaffold,
    // ce qui empêche les effets d'encre de persister sur les autres onglets.
    return Material(
      type: MaterialType.transparency,
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Rings AT/NT ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TestamentRing(
                    label: 'Ancien Testament',
                    read: _atReadChapters,
                    total: _atTotalChapters,
                    color: const Color(0xFF3F51B5),
                  ),
                  _TestamentRing(
                    label: 'Nouveau Testament',
                    read: _ntReadChapters,
                    total: _ntTotalChapters,
                    color: const Color(0xFFFFB300),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Progression : $chaptersReadCount / $totalChapters chapitres lus',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: totalChapters > 0 ? chaptersReadCount / totalChapters : 0,
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
          // Theme override : supprime hover et highlight gris persistants sur Flutter Web.
          // hoverColor/highlightColor transparents + overlayColor sur ListTileTheme.
          child: Theme(
            data: Theme.of(context).copyWith(
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: ListView.builder(
            itemCount: _books.length,
            itemBuilder: (context, index) {
              final book = _books[index];
              final chapters = _chapters[book] ?? [];
              final bookState = _bookReadState(book);

              return ExpansionTile(
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
                textColor: Theme.of(context).colorScheme.onSurface,
                collapsedTextColor: Theme.of(context).colorScheme.onSurface,
                iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                title: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
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
                              ? Theme.of(context).colorScheme.outline
                              : Theme.of(context).colorScheme.primary,
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
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                children: chapters.map((ch) {
                  final key = '$book|$ch';
                  final isRead = _readChapters.contains(key);
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 48, right: 16),
                    title: Text('Chapitre $ch'),
                    onTap: () => Future.microtask(() => widget.onChapterTap?.call(book, ch)),
                    trailing: Checkbox(
                      value: isRead,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (_) => DatabaseService.toggleChapterReadStatus(book, int.parse(ch)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          ),
        ),
      ],
      ),
    );
  }
}

enum _BookReadState { none, partial, full }

class _TestamentRing extends StatelessWidget {
  final String label;
  final int read;
  final int total;
  final Color color;

  const _TestamentRing({
    required this.label,
    required this.read,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? read / total : 0.0;
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: pct,
                strokeWidth: 7,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  '${(pct * 100).round()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        Text(
          '$read / $total ch.',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
