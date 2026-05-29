import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

class DatabaseService {
  static Database? _db;
  static const String _dbName = 'qa_genie.db';
  static const int _version = 2;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = await getDatabasesPath();
    return await openDatabase('$path/$_dbName', version: _version, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE suites (id INTEGER PRIMARY KEY AUTOINCREMENT, moduleName TEXT NOT NULL, feature TEXT NOT NULL, platform TEXT NOT NULL, created_at TEXT DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE test_cases (id INTEGER PRIMARY KEY AUTOINCREMENT, suite_id INTEGER NOT NULL, case_json TEXT NOT NULL, FOREIGN KEY (suite_id) REFERENCES suites(id) ON DELETE CASCADE)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try { await db.execute('ALTER TABLE test_cases ADD COLUMN case_json TEXT'); } catch(e) { print('Column case_json may already exist: $e'); }
    }
  }

  static Future<int> insertSuite({required String moduleName, required String feature, required String platform}) async {
    final db = await DatabaseService.db;
    return await db.insert('suites', {'moduleName': moduleName, 'feature': feature, 'platform': platform});
  }

  static Future<List<Map<String, dynamic>>> getAllSuites() async {
    final db = await DatabaseService.db;
    return await db.query('suites', orderBy: 'created_at DESC');
  }

  static Future<void> deleteSuite(int id) async {
    final db = await DatabaseService.db;
    await db.delete('suites', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> insertTestCases({required int suiteId, required List<FinalizedTestCase> cases}) async {
    final db = await DatabaseService.db;
    for (final tc in cases) {
      await db.insert('test_cases', {'suite_id': suiteId, 'case_json': _encodeTestCase(tc)});
    }
  }

  static Future<void> insertSingleTestCase({required int suiteId, required FinalizedTestCase testCase}) async {
    final db = await DatabaseService.db;
    await db.insert('test_cases', {'suite_id': suiteId, 'case_json': _encodeTestCase(testCase)});
  }

  static Future<void> replaceAllTestCases({required int suiteId, required List<FinalizedTestCase> cases}) async {
    final db = await DatabaseService.db;
    await db.transaction((txn) async {
      await txn.delete('test_cases', where: 'suite_id = ?', whereArgs: [suiteId]);
      for (final tc in cases) {
        await txn.insert('test_cases', {'suite_id': suiteId, 'case_json': _encodeTestCase(tc)});
      }
    });
  }

  static Future<void> updateSingleTestCase(FinalizedTestCase tc) async {
    final db = await DatabaseService.db;
    await db.update('test_cases', {'case_json': _encodeTestCase(tc)}, where: 'id = ?', whereArgs: [tc.dbId]);
  }

  static Future<List<FinalizedTestCase>> getTestCasesForSuite(int suiteId) async {
    final db = await DatabaseService.db;
    final rows = await db.query('test_cases', where: 'suite_id = ?', whereArgs: [suiteId]);
    return rows.map((row) => _decodeTestCase(row['case_json'] as String)).toList();
  }

  static Future<void> deleteTestCase(int id) async {
    final db = await DatabaseService.db;
    await db.delete('test_cases', where: 'id = ?', whereArgs: [id]);
  }

  static String _encodeTestCase(FinalizedTestCase tc) {
    final map = {
      'dbId': tc.dbId, 'id': tc.id, 'title': tc.title, 'module': tc.module, 'feature': tc.feature, 'platform': tc.platform,
      'priority': tc.priority, 'type': tc.type, 'preconditions': tc.preconditions, 'testData': tc.testData,
      'steps': tc.steps.map((s) => s.toJson()).toList(), 'expectedResult': tc.expectedResult,
      'actualResult': tc.actualResult, 'status': tc.status, 'source': tc.source.name,
    };
    return jsonEncode(map);
  }

  static FinalizedTestCase _decodeTestCase(String jsonStr) {
    final map = jsonDecode(jsonStr);
    return FinalizedTestCase(
      dbId: map['dbId'], id: map['id'], title: map['title'], module: map['module'], feature: map['feature'],
      platform: map['platform'], priority: map['priority'], type: map['type'],
      preconditions: List<String>.from(map['preconditions']), testData: map['testData'],
      steps: (map['steps'] as List).map((s) => TestStep.fromJson(s)).toList(), expectedResult: map['expectedResult'],
      actualResult: map['actualResult'], status: map['status'],
      source: CaseSource.values.firstWhere((e) => e.name == map['source'], orElse: () => CaseSource.ai),
    );
  }
}