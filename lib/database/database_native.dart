import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'database.dart';

/// Crée une instance AppDatabase pour les plateformes natives (Android, iOS, macOS, Linux, Windows)
AppDatabase createAppDatabase() {
  return AppDatabase(
    LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'bible_app_db.sqlite'));
      return NativeDatabase(file);
    }),
  );
}
