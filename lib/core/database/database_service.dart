import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:qa_genie/data/models/test_case_model.dart';

class DatabaseService {
  static Database? _db;
  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'qa_genie.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE suites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          moduleName TEXT,
          feature TEXT,
          platform TEXT,
          created_at TEXT
        )''');
        await db.execute('''CREATE TABLE test_cases (
          db_id INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT,
          suite_id INTEGER,
          title TEXT,
          preconditions TEXT,
          steps TEXT,
          expectedResult TEXT,
          priority TEXT,
          actualResult TEXT,
          status TEXT,
          FOREIGN KEY (suite_id) REFERENCES suites(id)
        )''');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 4) {
          await db.execute("DROP TABLE IF EXISTS test_cases");
          await db.execute("DROP TABLE IF EXISTS suites");
          await db.execute('''CREATE TABLE suites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            moduleName TEXT,
            feature TEXT,
            platform TEXT,
            created_at TEXT
          )''');
          await db.execute('''CREATE TABLE test_cases (
            db_id INTEGER PRIMARY KEY AUTOINCREMENT,
            id TEXT,
            suite_id INTEGER,
            title TEXT,
            preconditions TEXT,
            steps TEXT,
            expectedResult TEXT,
            priority TEXT,
            actualResult TEXT,
            status TEXT,
            FOREIGN KEY (suite_id) REFERENCES suites(id)
          )''');
        }
        if (oldV < 5) {
          final rows = await db.query('test_cases');
          final batch = db.batch();
          for (final row in rows) {
            final dbId = row['db_id'];
            if (dbId == null) continue;
            final preconditions = _decodePreconditions(row['preconditions']);
            final steps = _decodeSteps(row['steps']);
            batch.update(
              'test_cases',
              {
                'preconditions': _encodePreconditions(preconditions),
                'steps': _encodeSteps(steps),
              },
              where: 'db_id = ?',
              whereArgs: [dbId],
            );
          }
          await batch.commit(noResult: true);
        }
      },
    );
  }

  static String _encodePreconditions(List<String> preconditions) {
    return jsonEncode(preconditions);
  }

  static String _encodeSteps(List<TestStep> steps) {
    return jsonEncode(steps.map((s) => s.toJson()).toList());
  }

  static List<String> _decodePreconditions(Object? raw) {
    final text = (raw ?? '').toString();
    if (text.trim().isEmpty) return [];
    try {
      final parsed = jsonDecode(text);
      if (parsed is List) {
        return parsed.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return text
        .split('|||')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<TestStep> _decodeSteps(Object? raw) {
    final text = (raw ?? '').toString();
    if (text.trim().isEmpty) return [];
    try {
      final parsed = jsonDecode(text);
      if (parsed is List) {
        return parsed
            .whereType<Map>()
            .map((s) => TestStep.fromJson(Map<String, dynamic>.from(s)))
            .toList();
      }
    } catch (_) {}

    final stepsRaw = text.split(';;');
    return stepsRaw.where((s) => s.isNotEmpty).map((s) {
      final parts = s.split('||');
      return TestStep(
        action: parts.isNotEmpty ? parts[0] : '',
        data: parts.length > 1 ? parts[1] : '',
        expected: parts.length > 2 ? parts[2] : '',
      );
    }).toList();
  }

  static Future<int> insertSuite(String m, String f, String p) async {
    final database = await db;
    return await database.insert('suites', {
      'moduleName': m,
      'feature': f,
      'platform': p,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> insertTestCases(
    int suiteId,
    List<TestCaseModel> cases,
  ) async {
    final database = await db;
    await database.transaction((txn) async {
      for (var tc in cases) {
        await txn.insert('test_cases', {
          'id': tc.id,
          'suite_id': suiteId,
          'title': tc.title,
          'preconditions': _encodePreconditions(tc.preconditions),
          'steps': _encodeSteps(tc.steps),
          'expectedResult': tc.expectedResult,
          'priority': tc.priority,
          'actualResult': tc.actualResult,
          'status': tc.status,
        });
      }
    });
  }

  static Future<void> updateSuiteTestCases(
    int suiteId,
    List<TestCaseModel> cases,
  ) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete(
        'test_cases',
        where: 'suite_id = ?',
        whereArgs: [suiteId],
      );
      for (var tc in cases) {
        await txn.insert('test_cases', {
          'id': tc.id,
          'suite_id': suiteId,
          'title': tc.title,
          'preconditions': _encodePreconditions(tc.preconditions),
          'steps': _encodeSteps(tc.steps),
          'expectedResult': tc.expectedResult,
          'priority': tc.priority,
          'actualResult': tc.actualResult,
          'status': tc.status,
        });
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getAllSuites() async {
    final database = await db;
    return await database.query('suites', orderBy: 'created_at DESC');
  }

  static Future<List<TestCaseModel>> getTestCasesForSuite(int suiteId) async {
    final database = await db;
    final rows = await database.query(
      'test_cases',
      where: 'suite_id = ?',
      whereArgs: [suiteId],
      orderBy: 'id ASC',
    ); // ← consistent ordering
    return rows.map((r) {
      final steps = _decodeSteps(r['steps']);
      return TestCaseModel(
        dbId: r['db_id'] as int?,
        id: r['id'] as String,
        title: r['title'] as String,
        preconditions: _decodePreconditions(r['preconditions']),
        steps: steps,
        expectedResult: r['expectedResult'] as String? ?? '',
        priority: r['priority'] as String? ?? 'Medium',
        actualResult: r['actualResult'] as String? ?? '',
        status: r['status'] as String? ?? 'Not Executed',
      );
    }).toList();
  }

  static Future<void> deleteSuite(int suiteId) async {
    final database = await db;
    await database.delete(
      'test_cases',
      where: 'suite_id = ?',
      whereArgs: [suiteId],
    );
    await database.delete('suites', where: 'id = ?', whereArgs: [suiteId]);
  }

  static Future<void> deleteTestCase(int dbId) async {
    final database = await db;
    await database.delete('test_cases', where: 'db_id = ?', whereArgs: [dbId]);
  }

  static Future<void> insertSingleTestCase(
    int suiteId,
    TestCaseModel tc,
  ) async {
    final database = await db;
    await database.insert('test_cases', {
      'id': tc.id,
      'suite_id': suiteId,
      'title': tc.title,
      'preconditions': _encodePreconditions(tc.preconditions),
      'steps': _encodeSteps(tc.steps),
      'expectedResult': tc.expectedResult,
      'priority': tc.priority,
      'actualResult': tc.actualResult,
      'status': tc.status,
    });
  }
}
