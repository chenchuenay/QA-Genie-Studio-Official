import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';

FinalizedTestCase _makeCase({
  String id = 'TC-001',
  String title = 'Test login',
  String module = 'Auth',
  String feature = 'Login',
  String platform = 'Android',
  String priority = 'High',
  String status = 'Not Executed',
  String expectedResult = 'User is logged in',
  String actualResult = '',
  List<TestStep>? steps,
}) {
  return FinalizedTestCase(
    dbId: 1,
    id: id,
    title: title,
    module: module,
    feature: feature,
    platform: platform,
    priority: priority,
    status: status,
    expectedResult: expectedResult,
    actualResult: actualResult,
    type: 'Functional',
    steps: steps ?? [TestStep(action: 'Enter credentials', data: 'user@test.com', expected: 'Success')],
    preconditions: ['User is on login screen'],
    testData: 'valid credentials',
  );
}

void main() {
  group('ExportMapper.safe', () {
    test('returns empty string for null', () {
      expect(ExportMapper.safe(null), '');
    });

    test('trims and collapses whitespace', () {
      expect(ExportMapper.safe('  hello   world  '), 'hello world');
    });

    test('replaces control characters', () {
      expect(ExportMapper.safe('line1\r\nline2\tend'), 'line1 line2 end');
    });
  });

  group('ExportMapper.toExcel', () {
    test('returns header row and data rows', () {
      final cases = [_makeCase()];
      final rows = ExportMapper.toExcel(cases);
      expect(rows.length, 2);
      expect(rows[0][0], 'Test Case ID');
      expect(rows[1][0], 'TC-001');
      expect(rows[1][3], 'Test login');
    });

    test('uses moduleName and featureName from args when tc fields are empty', () {
      final cases = [_makeCase(module: '', feature: '')];
      final rows = ExportMapper.toExcel(cases, moduleName: 'FallbackMod', featureName: 'FallbackFeat');
      expect(rows[1][1], 'FallbackMod');
      expect(rows[1][2], 'FallbackFeat');
    });

    test('prefers tc fields over args', () {
      final cases = [_makeCase(module: 'RealMod', feature: 'RealFeat')];
      final rows = ExportMapper.toExcel(cases, moduleName: 'FallbackMod', featureName: 'FallbackFeat');
      expect(rows[1][1], 'RealMod');
      expect(rows[1][2], 'RealFeat');
    });
  });

  group('ExportMapper.toJira', () {
    test('returns header and data rows with correct columns', () {
      final cases = [_makeCase()];
      final rows = ExportMapper.toJira(cases);
      expect(rows.length, 2);
      expect(rows[0][0], 'Summary');
      expect(rows[1][0], 'Test login');
      expect(rows[1][1], 'Test');
    });

    test('uses featureName when tc.feature is empty', () {
      final cases = [_makeCase(feature: '')];
      final rows = ExportMapper.toJira(cases, featureName: 'DefaultFeat');
      expect(rows[1][2], 'DefaultFeat');
    });
  });

  group('ExportMapper.toXray', () {
    test('returns list of maps with correct structure', () {
      final cases = [_makeCase()];
      final result = ExportMapper.toXray(cases);
      expect(result.length, 1);
      expect(result[0]['issueId'], 'TC-001');
      expect(result[0]['summary'], 'Test login');
      expect(result[0]['testType'], 'Manual');
      expect(result[0]['steps'], isA<List>());
    });

    test('includes step details in Xray format', () {
      final cases = [_makeCase()];
      final result = ExportMapper.toXray(cases);
      final steps = result[0]['steps'] as List;
      expect(steps.length, 1);
      expect(steps[0]['action'], 'Enter credentials');
      expect(steps[0]['data'], 'user@test.com');
      expect(steps[0]['result'], 'Success');
    });
  });

  group('ExportMapper.toPdf', () {
    test('returns list of maps with PDF-specific keys', () {
      final cases = [_makeCase()];
      final result = ExportMapper.toPdf(cases);
      expect(result.length, 1);
      expect(result[0]['Test Case ID'], 'TC-001');
      expect(result[0]['Title'], 'Test login');
      expect(result[0]['Preconditions'], 'User is on login screen');
    });
  });

  group('ExportMapper.toSummaryReport', () {
    test('returns summary with correct counts', () {
      final cases = [
        _makeCase(status: 'Pass'),
        _makeCase(id: 'TC-002', status: 'Fail'),
        _makeCase(id: 'TC-003', status: 'Not Executed'),
      ];
      final report = ExportMapper.toSummaryReport(cases, 'Auth', 'Login', 'Android', 'Tester', 'Production');
      expect(report['suiteName'], 'Auth · Login');
      expect(report['total'], 3);
      expect(report['passed'], 1);
      expect(report['failed'], 1);
      expect(report['notExecuted'], 1);
    });

    test('handles zero executed cases for pass rate', () {
      final cases = [_makeCase(status: 'Not Executed')];
      final report = ExportMapper.toSummaryReport(cases, 'M', 'F', 'iOS', '', '');
      expect(report['passRate'], '0.0');
    });

    test('includes priority breakdown', () {
      final cases = [
        _makeCase(priority: 'High'),
        _makeCase(id: 'TC-002', priority: 'Medium'),
        _makeCase(id: 'TC-003', priority: 'Low'),
      ];
      final report = ExportMapper.toSummaryReport(cases, 'M', 'F', 'A', 'T', 'P');
      expect(report['priorityBreakdown']['HIGH'], 1);
      expect(report['priorityBreakdown']['MEDIUM'], 1);
      expect(report['priorityBreakdown']['LOW'], 1);
    });

    test('includes details list', () {
      final cases = [_makeCase()];
      final report = ExportMapper.toSummaryReport(cases, 'M', 'F', 'A', 'T', 'P');
      expect(report['details'], isA<List>());
      expect((report['details'] as List).length, 1);
    });

    test('expected result fallback: uses last step expected when tc.expectedResult is empty', () {
      final cases = [
        _makeCase(expectedResult: '', steps: [
          TestStep(action: 'Step 1', data: '', expected: ''),
          TestStep(action: 'Step 2', data: '', expected: 'Final expected'),
        ]),
      ];
      final excelRows = ExportMapper.toExcel(cases);
      expect(excelRows[1][7], 'Final expected');
    });

    test('expected result fallback: uses default text when no expected available', () {
      final cases = [
        _makeCase(expectedResult: '', steps: [
          TestStep(action: 'Click', data: '', expected: ''),
        ]),
      ];
      final excelRows = ExportMapper.toExcel(cases);
      expect(excelRows[1][7], 'Expected behavior is observed.');
    });
  });
}
