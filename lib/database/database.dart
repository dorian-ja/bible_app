import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Verses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get book => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get text => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get noteText => text().nullable()();
  TextColumn get noteColor => text().nullable()();
  BoolColumn get isChapterRead => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Verses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return autoChooseDatabase(
    logStatements: kDebugMode,
    nativeDatabase: () async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'db.sqlite'));
      return NativeDatabase.createInBackground(file);
    },
    wasmDatabase: () async {
      return WasmDatabase.open(
        databaseName: 'bible_app_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
    },
  );
}
