

import 'package:drift/drift.dart';

part 'database.g.dart';

class Prayers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(1))(); // 1=Normale, 2=Importante, 3=Critique
  IntColumn get categoryId => integer().nullable()(); // Référence à PrayerCategories
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get dateAnswered => dateTime().nullable()();
  BoolColumn get isAnswered => boolean().withDefault(const Constant(false))();
  BoolColumn get hasReminder => boolean().withDefault(const Constant(false))();
  DateTimeColumn get reminderTime => dateTime().nullable()();
}

class PrayerCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant('0xFFB39DDB'))(); // Couleur hex
}

class Verses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get book => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get textContent => text()();
  TextColumn get textContentNormalized => text().withDefault(const Constant(''))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get noteText => text().nullable()();
  TextColumn get noteColor => text().nullable()();
  BoolColumn get isChapterRead => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Verses, Prayers, PrayerCategories])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Constructeur réservé aux tests unitaires (base en mémoire).
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  static const _defaultCategories = [
    ('Famille', '0xFF42A5F5'),
    ('Santé', '0xFF66BB6A'),
    ('Travail', '0xFFFFA726'),
    ('Personnel', '0xFFAB47BC'),
    ('Église', '0xFFEF5350'),
    ('Remerciements', '0xFFFFEE58'),
  ];

  Future<void> _insertDefaultCategories() async {
    for (final (name, color) in _defaultCategories) {
      await into(prayerCategories).insert(
        PrayerCategoriesCompanion(name: Value(name), color: Value(color)),
      );
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _insertDefaultCategories();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(prayers, prayers.priority);
        await m.addColumn(prayers, prayers.categoryId);
        await m.addColumn(prayers, prayers.hasReminder);
        await m.addColumn(prayers, prayers.reminderTime);
        await m.create(prayerCategories);
      }
      if (from < 3) {
        // Migration v2 → v3 : colonne de recherche normalisée (sans accents)
        await m.addColumn(verses, verses.textContentNormalized);
        // Le backfill est effectué par DatabaseService.ensureNormalizedText()
      }
      if (from < 4) {
        // Migration v3 → v4 : ajout des catégories par défaut
        final existing = await select(prayerCategories).get();
        if (existing.isEmpty) {
          await _insertDefaultCategories();
        }
      }
    },
  );

  // === Gestion des catégories ===
  Stream<List<PrayerCategory>> watchAllCategories() =>
      (select(prayerCategories)..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();

  Future<int> insertCategory(String name, String color) {
    return into(prayerCategories).insert(
      PrayerCategoriesCompanion(name: Value(name), color: Value(color)),
    );
  }

  Future<void> deleteCategory(int id) => transaction(() async {
    await (update(prayers)..where((tbl) => tbl.categoryId.equals(id)))
        .write(const PrayersCompanion(categoryId: Value(null)));
    await (delete(prayerCategories)..where((tbl) => tbl.id.equals(id))).go();
  });

  // === Carnet de prières ===
  Stream<List<Prayer>> watchAllPrayers() =>
      (select(prayers)..orderBy([(t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc), (t) => OrderingTerm(expression: t.dateAdded, mode: OrderingMode.desc)])).watch();

  Stream<List<Prayer>> watchFilteredPrayers({
    bool? isAnswered,
    int? categoryId,
    String? searchQuery,
  }) {
    return (select(prayers)
      ..where((tbl) {
        Expression<bool> condition = const Constant(true);
        if (isAnswered != null) condition = condition & tbl.isAnswered.equals(isAnswered);
        if (categoryId != null) condition = condition & tbl.categoryId.equals(categoryId);
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final q = '%${searchQuery.toLowerCase()}%';
          condition = condition & (tbl.title.like(q) | tbl.description.like(q));
        }
        return condition;
      })
      ..orderBy([
        (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.dateAdded, mode: OrderingMode.desc),
      ]))
        .watch();
  }

  /// Cherche des versets thématiquement proches en se basant sur les mots
  /// significatifs (5+ caractères) du verset source, hors livre courant.
  Future<List<Verse>> findRelatedVerses(Verse sourceVerse, {int limit = 8}) async {
    final words = sourceVerse.textContentNormalized
        .split(RegExp(r'[^a-z]+'))
        .where((w) => w.length >= 5)
        .toSet()
        .take(3)
        .toList();

    if (words.isEmpty) return [];

    final results = <Verse>[];
    final seen = <int>{sourceVerse.id};

    for (final word in words) {
      if (results.length >= limit) break;
      final found = await (select(verses)
            ..where((t) =>
                t.textContentNormalized.like('%$word%') &
                t.book.isNotValue(sourceVerse.book))
            ..limit(limit - results.length))
          .get();
      for (final v in found) {
        if (seen.add(v.id)) results.add(v);
      }
    }

    return results;
  }

  Future<List<Prayer>> getPrayersWithReminders() {
    return (select(prayers)
      ..where((tbl) => tbl.hasReminder.equals(true) & tbl.isAnswered.equals(false)))
        .get();
  }

  Stream<List<Prayer>> watchPrayersByStatus({required bool answered}) =>
      (select(prayers)
        ..where((tbl) => tbl.isAnswered.equals(answered))
        ..orderBy([(t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc), (t) => OrderingTerm(expression: t.dateAdded, mode: OrderingMode.desc)]))
          .watch();

  Stream<List<Prayer>> watchPrayersByCategory(int categoryId) =>
      (select(prayers)
        ..where((tbl) => tbl.categoryId.equals(categoryId))
        ..orderBy([(t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc), (t) => OrderingTerm(expression: t.dateAdded, mode: OrderingMode.desc)]))
          .watch();

  Future<List<Prayer>> searchPrayers(String query) async {
    final lowerQuery = '%${query.toLowerCase()}%';
    return (select(prayers)
      ..where((tbl) => tbl.title.like(lowerQuery) | tbl.description.like(lowerQuery))
      ..orderBy([(t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc), (t) => OrderingTerm(expression: t.dateAdded, mode: OrderingMode.desc)]))
        .get();
  }

  Future<int> insertPrayer(
    String title,
    String description, {
    int priority = 1,
    int? categoryId,
    bool hasReminder = false,
    DateTime? reminderTime,
  }) {
    return into(prayers).insert(PrayersCompanion(
      title: Value(title),
      description: Value(description.isEmpty ? null : description),
      priority: Value(priority),
      categoryId: Value(categoryId),
      hasReminder: Value(hasReminder),
      reminderTime: Value(reminderTime),
    ));
  }

  Future<void> updatePrayer(Prayer prayer) async {
    await update(prayers).replace(prayer);
  }

  Future<void> togglePrayerAnswered(Prayer p) async {
    final isNowAnswered = !p.isAnswered;
    await update(prayers).replace(p.copyWith(
      isAnswered: isNowAnswered,
      dateAnswered: Value(isNowAnswered ? DateTime.now() : null),
    ));
  }

  Future<void> deletePrayer(int id) async {
    await (delete(prayers)..where((tbl) => tbl.id.equals(id))).go();
  }

  // === Statistiques ===

  Future<int> getPrayerCount() async {
    final c = countAll();
    return await (selectOnly(prayers)..addColumns([c])).map((r) => r.read(c)!).getSingle();
  }

  Future<int> getAnsweredCount() async {
    final c = countAll();
    return await (selectOnly(prayers)..where(prayers.isAnswered.equals(true))..addColumns([c])).map((r) => r.read(c)!).getSingle();
  }

  Future<int> getUnansweredCount() async {
    final c = countAll();
    return await (selectOnly(prayers)..where(prayers.isAnswered.equals(false))..addColumns([c])).map((r) => r.read(c)!).getSingle();
  }

  Future<double> getAnswerRate() async {
    final total = countAll();
    final answered = countAll(filter: prayers.isAnswered.equals(true));
    final row = await (selectOnly(prayers)..addColumns([total, answered])).getSingle();
    final t = row.read(total)!;
    if (t == 0) return 0.0;
    return (row.read(answered)! / t) * 100;
  }
}


