import 'package:sqflite/sqflite.dart';
// ============================================================
// FILE: lib/core/database/migrations/schema_v1.dart
// ============================================================

/// ===============================================================
///
/// SCHEMA V1
///
/// CANONICAL DATABASE SOURCE OF TRUTH
///
/// ===============================================================
class SchemaV1 {
  const SchemaV1._();

  // ============================================================
  // CREATE
  // ============================================================

  static Future<void> create(Database db) async {
    // ==========================================================
    // SUITES
    // ==========================================================

    await db.execute('''
    CREATE TABLE suites (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      module_name TEXT NOT NULL,
      feature TEXT NOT NULL,
      platform TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
    ''');

    // ==========================================================
    // TEST CASES
    // ==========================================================

    await db.execute('''
    CREATE TABLE test_cases (
      db_id INTEGER PRIMARY KEY AUTOINCREMENT,

      id TEXT NOT NULL,
      suite_id INTEGER NOT NULL,

      title TEXT NOT NULL,

      module TEXT,
      feature TEXT,
      platform TEXT,

      priority TEXT,
      type TEXT,

      preconditions TEXT NOT NULL,
      steps TEXT NOT NULL,

      expected_result TEXT,
      actual_result TEXT,
      status TEXT,

      source TEXT,

      created_at TEXT NOT NULL,

      FOREIGN KEY (suite_id)
      REFERENCES suites(id)
      ON DELETE CASCADE
    )
    ''');

    // ==========================================================
    // INDEXES
    // ==========================================================

    await db.execute('''
    CREATE INDEX idx_test_cases_suite
    ON test_cases(suite_id)
    ''');

    await db.execute('''
    CREATE INDEX idx_test_cases_id
    ON test_cases(id)
    ''');

    await db.execute('''
    CREATE INDEX idx_suites_created
    ON suites(created_at)
    ''');
  }

  // ============================================================
  // UPGRADE
  // ============================================================

  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Future-safe migration layer

    if (oldVersion < 1) {
      await create(db);
    }
  }
}
