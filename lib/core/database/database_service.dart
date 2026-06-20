import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

class DatabaseService {
  static Database? _db;
  static String? _currentIdentity;
  static bool _isInitializing = false;
  static final Completer<void> _initCompleter = Completer();
  static const String _dbName = 'qa_genie.db';
  static const int _version = 3;
  static List<Map<String, dynamic>>? _suitesCache;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    if (_isInitializing) {
      await _initCompleter.future.timeout(const Duration(seconds: 10));
      if (_db != null) return _db!;
    }
    throw Exception('Database not initialized. Call initDatabase first.');
  }

  static Future<void> initDatabase(String identity) async {
    if (_db != null && _currentIdentity == identity) return;
    
    if (_isInitializing) {
      await _initCompleter.future;
      if (_currentIdentity == identity) return;
    }

    _isInitializing = true;

    if (_db != null) await _db!.close();

    try {
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
      await _db!.execute('PRAGMA journal_mode=WAL');
      await _db!.execute('PRAGMA busy_timeout=5000');
    } finally {
      _isInitializing = false;
      if (!_initCompleter.isCompleted) _initCompleter.complete();
    }
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
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS test_cases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          suite_id INTEGER NOT NULL,
          case_json TEXT NOT NULL,
          FOREIGN KEY (suite_id) REFERENCES suites(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reported_issues (
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
  }
  
  static Future<int> insertSuite({required String moduleName, required String feature, required String platform}) async {
    final db = await DatabaseService.db;
    // Check for existing suite with same (moduleName, feature, platform)
    final existing = await db.query('suites',
        where: 'moduleName = ? AND feature = ? AND platform = ?',
        whereArgs: [moduleName, feature, platform]);
    if (existing.isNotEmpty) return existing.first['id'] as int;
    final id = await db.insert('suites', {'moduleName': moduleName, 'feature': feature, 'platform': platform});
    invalidateSuitesCache();
    return id;
  }

  static Future<List<Map<String, dynamic>>> getAllSuites() async {
    if (_suitesCache != null) return _suitesCache!;
    final db = await DatabaseService.db;
    _suitesCache = await db.query('suites', orderBy: 'created_at DESC');
    return _suitesCache!;
  }

  static void invalidateSuitesCache() {
    _suitesCache = null;
  }

  static Future<void> renameSuite(int id, String newName) async {
    final db = await DatabaseService.db;
    await db.update('suites', {'moduleName': newName}, where: 'id = ?', whereArgs: [id]);
    invalidateSuitesCache();
  }

  static Future<void> deleteSuite(int id) async {
    final db = await DatabaseService.db;
    await db.delete('test_cases', where: 'suite_id = ?', whereArgs: [id]);
    await db.delete('suites', where: 'id = ?', whereArgs: [id]);
    invalidateSuitesCache();
  }

  static Future<void> insertTestCases({required int suiteId, required List<FinalizedTestCase> cases}) async {
    final db = await DatabaseService.db;
    final batch = db.batch();
    for (final tc in cases) {
      batch.insert('test_cases', {'suite_id': suiteId, 'case_json': _encodeTestCase(tc)});
    }
    await batch.commit(noResult: true);
  }

  static Future<List<FinalizedTestCase>> getTestCasesForSuite(int suiteId) async {
    final db = await DatabaseService.db;
    final rows = await db.query('test_cases', where: 'suite_id = ?', whereArgs: [suiteId]);
    return rows.map((row) {
      final tc = _decodeTestCase(row['case_json'] as String);
      return tc.copyWith(dbId: row['id'] as int?);
    }).toList();
  }

  static Future<void> replaceAllTestCases({required int suiteId, required List<FinalizedTestCase> cases}) async {
    final db = await DatabaseService.db;
    await db.transaction((txn) async {
      await txn.delete('test_cases', where: 'suite_id = ?', whereArgs: [suiteId]);
      final batch = txn.batch();
      for (final tc in cases) {
        batch.insert('test_cases', {'suite_id': suiteId, 'case_json': _encodeTestCase(tc)});
      }
      await batch.commit(noResult: true);
    });
  }

  static Future<void> updateSingleCase({required int dbId, required FinalizedTestCase tc}) async {
    final db = await DatabaseService.db;
    await db.update(
      'test_cases',
      {'case_json': _encodeTestCase(tc)},
      where: 'id = ?',
      whereArgs: [dbId],
    );
  }

  static Future<void> deleteTestCase(int id) async {
    final db = await DatabaseService.db;
    await db.delete('test_cases', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> batchDeleteTestCases(List<int> ids) async {
    final db = await DatabaseService.db;
    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.delete('test_cases', where: 'id = ?', whereArgs: [id]);
      }
    });
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
  
  static Future<void> updateIssueStatus(int id, String status, [String? lastSyncAttempt]) async {
    final db = await DatabaseService.db;
    await db.update('reported_issues', {
      'status': status,
      'lastSyncAttempt': lastSyncAttempt ?? DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  /// Migrates all suites & test cases from [fromIdentity]'s database into the
  /// currently active database. Duplicate suites (same moduleName+feature+platform)
  /// are skipped; their test cases are merged under the existing suite.
  static Future<void> migrateDataToCurrentDb(String fromIdentity) async {
    final sanitized = sha256.convert(utf8.encode(fromIdentity)).toString();
    final appDir = await getApplicationSupportDirectory();
    final oldDbPath = '${appDir.path}/data/qa_genie/$sanitized/$_dbName';

    final oldFile = File(oldDbPath);
    if (!await oldFile.exists()) return;

    Database? oldDb;
    try {
      oldDb = await openDatabase(oldDbPath);
      final suites = await oldDb.query('suites');
      if (suites.isEmpty) return;

      final allTestCases = await oldDb.query('test_cases');
      final target = await DatabaseService.db;
      final Map<int, int> suiteIdMap = {};

      for (final suite in suites) {
        final oldId = suite['id'] as int;
        final existing = await target.query(
          'suites',
          where: 'moduleName = ? AND feature = ? AND platform = ?',
          whereArgs: [suite['moduleName'], suite['feature'], suite['platform']],
        );

        int newId;
        if (existing.isNotEmpty) {
          newId = existing.first['id'] as int;
        } else {
          newId = await target.insert('suites', {
            'moduleName': suite['moduleName'],
            'feature': suite['feature'],
            'platform': suite['platform'],
            'created_at': suite['created_at'],
          });
        }
        suiteIdMap[oldId] = newId;
      }

      for (final tc in allTestCases) {
        final oldSuiteId = tc['suite_id'] as int;
        final newSuiteId = suiteIdMap[oldSuiteId];
        if (newSuiteId != null) {
          await target.insert('test_cases', {
            'suite_id': newSuiteId,
            'case_json': tc['case_json'],
          });
        }
      }

      invalidateSuitesCache();
    } finally {
      await oldDb?.close();
    }
  }

  static Future<void> clearAll() async {
    final db = await DatabaseService.db;
    await db.delete('suites');
    await db.delete('test_cases');
    await db.delete('reported_issues');
    await db.execute('DELETE FROM sqlite_sequence');
    invalidateSuitesCache();
  }

  /// Syncs only `status` field for already-submitted reports, once per week on Monday.
  /// Never resends full reports — only pulls latest status from Firestore.
  static Future<void> syncPendingReports() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    if (now.weekday != DateTime.monday) return;
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final lastSync = prefs.getInt('last_status_sync_day') ?? 0;
    if (lastSync >= todayStart) return;
    await prefs.setInt('last_status_sync_day', todayStart);

    final db = await DatabaseService.db;
    final rows = await db.query('reported_issues', where: 'firestoreId IS NOT NULL AND firestoreId != ?', whereArgs: ['']);
    for (final row in rows) {
      final firestoreId = row['firestoreId'] as String?;
      if (firestoreId == null || firestoreId.isEmpty) continue;
      try {
        final snap = await FirebaseFirestore.instance
            .collection('issue_reports')
            .doc(firestoreId)
            .get();
        if (snap.exists) {
          final remoteStatus = snap.data()?['status'] as String? ?? 'open';
          await db.update('reported_issues',
            {'status': remoteStatus, 'lastSyncAttempt': DateTime.now().toIso8601String()},
            where: 'id = ?', whereArgs: [row['id']]);
        }
      } catch (_) {
        // Will retry next week
      }
    }
  }
}
