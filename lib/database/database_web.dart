import 'package:drift/wasm.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'database.dart';

/// Crée une instance AppDatabase pour le web
AppDatabase createAppDatabase() {
  return AppDatabase(
    DatabaseConnection.delayed(
      Future(() async {
        final result = await WasmDatabase.open(
          databaseName: 'bible_app_db',
          sqlite3Uri: Uri.parse('sqlite3.wasm'),
          driftWorkerUri: Uri.parse('drift_worker.dart.js'),
        );

        if (result.missingFeatures.isNotEmpty) {
          debugPrint('Drift Web utilise: ${result.chosenImplementation}');
          debugPrint('Fonctionnalités manquantes: ${result.missingFeatures}');
        }

        return result.resolvedExecutor;
      }),
    ),
  );
}
