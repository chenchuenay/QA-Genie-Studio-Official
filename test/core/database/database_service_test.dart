import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() {
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationSupportDirectory') {
          return Directory.systemTemp.path;
        }
        return Directory.systemTemp.path;
      },
    );
  });

  setUp(() async {
    DatabaseService.invalidateSuitesCache();
    await DatabaseService.initDatabase('test_identity');
  });

  tearDown(() async {
    await DatabaseService.clearAll();
    DatabaseService.invalidateSuitesCache();
  });

  FinalizedTestCase _makeCase({
    int? dbId,
    String id = 'TC-001',
    String title = 'Test login',
    String module = 'Auth',
    String feature = 'Login',
    String platform = 'Android',
    String priority = 'High',
    String status = 'Not Executed',
    String expectedResult = 'User is logged in',
    List<TestStep>? steps,
  }) {
    return FinalizedTestCase(
      dbId: dbId,
      id: id,
      title: title,
      module: module,
      feature: feature,
      platform: platform,
      priority: priority,
      status: status,
      expectedResult: expectedResult,
      type: 'Functional',
      steps: steps ?? [TestStep(action: 'Enter credentials', data: 'user@test.com', expected: 'Success')],
      preconditions: ['User is on login screen'],
      testData: 'valid credentials',
    );
  }

  group('DatabaseService', () {
    test('insertSuite creates a new suite and returns its id', () async {
      final id = await DatabaseService.insertSuite(
        moduleName: 'Auth',
        feature: 'Login',
        platform: 'Android',
      );
      expect(id, greaterThan(0));
    });

    test('insertSuite returns existing id for duplicate', () async {
      final id1 = await DatabaseService.insertSuite(
        moduleName: 'Auth',
        feature: 'Login',
        platform: 'Android',
      );
      final id2 = await DatabaseService.insertSuite(
        moduleName: 'Auth',
        feature: 'Login',
        platform: 'Android',
      );
      expect(id1, id2);
    });

    test('getAllSuites returns inserted suites', () async {
      await DatabaseService.insertSuite(moduleName: 'Auth', feature: 'Login', platform: 'iOS');
      final suites = await DatabaseService.getAllSuites();
      expect(suites.length, 1);
      expect(suites.first['moduleName'], 'Auth');
    });

    test('renameSuite updates the module name', () async {
      final id = await DatabaseService.insertSuite(moduleName: 'Auth', feature: 'Login', platform: 'Android');
      await DatabaseService.renameSuite(id, 'Security');
      final suites = await DatabaseService.getAllSuites();
      expect(suites.first['moduleName'], 'Security');
    });

    test('deleteSuite removes suite and its test cases', () async {
      final suiteId = await DatabaseService.insertSuite(moduleName: 'Auth', feature: 'Login', platform: 'Android');
      final cases = [_makeCase()];
      await DatabaseService.insertTestCases(suiteId: suiteId, cases: cases);
      await DatabaseService.deleteSuite(suiteId);
      final suites = await DatabaseService.getAllSuites();
      expect(suites, isEmpty);
    });

    test('insertTestCases and getTestCasesForSuite roundtrip', () async {
      final suiteId = await DatabaseService.insertSuite(moduleName: 'Auth', feature: 'Login', platform: 'Web');
      final cases = [
        _makeCase(id: 'TC-001', title: 'Test 1'),
        _makeCase(id: 'TC-002', title: 'Test 2'),
      ];
      await DatabaseService.insertTestCases(suiteId: suiteId, cases: cases);
      final retrieved = await DatabaseService.getTestCasesForSuite(suiteId);
      expect(retrieved.length, 2);
      expect(retrieved[0].title, 'Test 1');
      expect(retrieved[1].title, 'Test 2');
    });

    test('replaceAllTestCases removes old and inserts new', () async {
      final suiteId = await DatabaseService.insertSuite(moduleName: 'Auth', feature: 'Login', platform: 'Mobile');
      await DatabaseService.insertTestCases(suiteId: suiteId, cases: [_makeCase(id: 'TC-001')]);
      await DatabaseService.replaceAllTestCases(suiteId: suiteId, cases: [_makeCase(id: 'TC-002'), _makeCase(id: 'TC-003')]);
      final retrieved = await DatabaseService.getTestCasesForSuite(suiteId);
      expect(retrieved.length, 2);
      expect(retrieved[0].id, 'TC-002');
      expect(retrieved[1].id, 'TC-003');
    });

    test('updateSingleCase updates test case data', () async {
      final suiteId = await DatabaseService.insertSuite(moduleName: 'Auth', feature: 'Login', platform: 'Android');
      await DatabaseService.insertTestCases(suiteId: suiteId, cases: [_makeCase(id: 'TC-001', title: 'Original')]);
      var retrieved = await DatabaseService.getTestCasesForSuite(suiteId);
      final dbId = retrieved.first.dbId;
      await DatabaseService.updateSingleCase(dbId: dbId!, tc: _makeCase(dbId: dbId, id: 'TC-001', title: 'Updated'));
      retrieved = await DatabaseService.getTestCasesForSuite(suiteId);
      expect(retrieved.first.title, 'Updated');
    });

    test('deleteTestCase removes a single test case', () async {
      final suiteId = await DatabaseService.insertSuite(moduleName: 'Auth', feature: 'Login', platform: 'Android');
      await DatabaseService.insertTestCases(suiteId: suiteId, cases: [_makeCase(id: 'TC-001')]);
      var retrieved = await DatabaseService.getTestCasesForSuite(suiteId);
      await DatabaseService.deleteTestCase(retrieved.first.dbId!);
      retrieved = await DatabaseService.getTestCasesForSuite(suiteId);
      expect(retrieved, isEmpty);
    });

    test('batchDeleteTestCases removes multiple test cases', () async {
      final suiteId = await DatabaseService.insertSuite(moduleName: 'Auth', feature: 'Login', platform: 'Android');
      await DatabaseService.insertTestCases(suiteId: suiteId, cases: [
        _makeCase(id: 'TC-001'),
        _makeCase(id: 'TC-002'),
      ]);
      var retrieved = await DatabaseService.getTestCasesForSuite(suiteId);
      final ids = retrieved.map((c) => c.dbId!).toList();
      await DatabaseService.batchDeleteTestCases(ids);
      retrieved = await DatabaseService.getTestCasesForSuite(suiteId);
      expect(retrieved, isEmpty);
    });

    test('insertReportedIssue and updateIssueStatus', () async {
      final issueId = await DatabaseService.insertReportedIssue({
        'issueType': 'Bug',
        'title': 'Test issue',
        'description': 'Description',
      });
      expect(issueId, greaterThan(0));
      await DatabaseService.updateIssueStatus(issueId, 'resolved');
    });

    test('invalidateSuitesCache clears cache', () async {
      DatabaseService.invalidateSuitesCache();
      final suites = await DatabaseService.getAllSuites();
      expect(suites, isEmpty);
    });

    test('clearAll removes all data', () async {
      await DatabaseService.insertSuite(moduleName: 'Auth', feature: 'Login', platform: 'Android');
      await DatabaseService.clearAll();
      final suites = await DatabaseService.getAllSuites();
      expect(suites, isEmpty);
    });
  });
}
