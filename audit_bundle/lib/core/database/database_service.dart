import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

class DatabaseService {
  static Database? _db;
  static String? _currentIdentity;
  static const String _dbName = 'qa_genie.db';
  static const int _version = 3;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    throw Exception('Database not initialized. Call initDatabase first.');
  }

  static Future<void> initDatabase(String identity) async {
    if (_db != null && _currentIdentity == identity) return;
    
    if (_db != null) await _db!.close();

    final sanitizedIdentity = sha256.convert(utf8.encode(identity)).toString();
    final appDir = await getApplicationSupportDirectory();
    final dbDir = Directory('${appDir.path}/data/qa_genie/$sanitizedIdentity');
    
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    _currentIdentity = identity;
    _db = await openDatabase(
      '${dbDir.path}/$_dbName',
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE suites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        moduleName TEXT NOT NULL,
        feature TEXT NOT NULL,
        platform TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE test_cases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        suite_id INTEGER NOT NULL,
        case_json TEXT NOT NULL,
        FOREIGN KEY (suite_id) REFERENCES suites(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE reported_issues (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firestoreId TEXT,
        issueType TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT DEFAULT 'open',
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        isSynced INTEGER DEFAULT 0,
        lastSyncAttempt TEXT,
        platform TEXT,
        deviceModel TEXT,
        appVersion TEXT,
        screen TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Simplified for this scope, assuming existing migration logic
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

  static Future<List<FinalizedTestCase>> getTestCasesForSuite(int suiteId) async {
    final db = await DatabaseService.db;
    final rows = await db.query('test_cases', where: 'suite_id = ?', whereArgs: [suiteId]);
    return rows.map((row) => _decodeTestCase(row['case_json'] as String)).toList();
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

  static Future<void> deleteTestCase(int id) async {
    final db = await DatabaseService.db;
    await db.delete('test_cases', where: 'id = ?', whereArgs: [id]);
  }

  static String _encodeTestCase(FinalizedTestCase tc) {
    final map = {
      'dbId': tc.dbId,
      'id': tc.id,
      'title': tc.title,
      'module': tc.module,
      'feature': tc.feature,
      'platform': tc.platform,
      'priority': tc.priority,
      'type': tc.type,
      'preconditions': tc.preconditions,
      'testData': tc.testData,
      'steps': tc.steps.map((s) => {'action': s.action, 'data': s.data, 'expected': s.expected}).toList(),
      'expectedResult': tc.expectedResult,
      'actualResult': tc.actualResult,
      'status': tc.status,
      'source': tc.source.name,
    };
    return jsonEncode(map);
  }

  static FinalizedTestCase _decodeTestCase(String jsonStr) {
    final map = jsonDecode(jsonStr);
    return FinalizedTestCase(
      dbId: map['dbId'],
      id: map['id'],
      title: map['title'],
      module: map['module'],
      feature: map['feature'],
      platform: map['platform'],
      priority: map['priority'],
      type: map['type'],
      preconditions: List<String>.from(map['preconditions']),
      testData: map['testData'],
      steps: (map['steps'] as List).map((s) => TestStep(action: s['action'], data: s['data'], expected: s['expected'])).toList(),
      expectedResult: map['expectedResult'],
      actualResult: map['actualResult'] ?? '',
      status: map['status'] ?? 'Not Executed',
      source: CaseSource.values.firstWhere((e) => e.name == map['source'], orElse: () => CaseSource.ai),
    );
  }
  
  static Future<int> insertReportedIssue(Map<String, dynamic> issue) async {
    final db = await DatabaseService.db;
    return await db.insert('reported_issues', issue);
  }
  
  static Future<void> updateIssueStatus(int id, String status) async {
    final db = await DatabaseService.db;
    await db.update('reported_issues', {'status': status, 'lastSyncAttempt': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
  }
}
