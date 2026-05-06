import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Verses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get book => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get textContent => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get noteText => text().nullable()();
  TextColumn get noteColor => text().nullable()();
  BoolColumn get isChapterRead => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Verses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructeur réservé aux tests unitaires (base en mémoire).
  // ignore: use_super_parameters
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Exemple pour une future v2 :
      // if (from < 2) { await m.addColumn(verses, verses.newColumn); }
    },
  );
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'bible_app_db',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
  );
}
