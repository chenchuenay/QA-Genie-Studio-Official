import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/enums/export_format.dart';

void main() {
  group('ExportFormat', () {
    test('excel displayName', () {
      expect(ExportFormat.excel.displayName, 'Excel');
    });

    test('pdf displayName', () {
      expect(ExportFormat.pdf.displayName, 'PDF');
    });

    test('jiraCsv displayName', () {
      expect(ExportFormat.jiraCsv.displayName, 'Jira CSV');
    });

    test('xrayJson displayName', () {
      expect(ExportFormat.xrayJson.displayName, 'Xray JSON');
    });
  });

  group('fileExtension', () {
    test('excel extension', () {
      expect(ExportFormat.excel.fileExtension, '.xlsx');
    });

    test('pdf extension', () {
      expect(ExportFormat.pdf.fileExtension, '.pdf');
    });

    test('jiraCsv extension', () {
      expect(ExportFormat.jiraCsv.fileExtension, '.csv');
    });

    test('xrayJson extension', () {
      expect(ExportFormat.xrayJson.fileExtension, '.json');
    });
  });

  group('isBinaryFormat', () {
    test('excel is binary', () {
      expect(ExportFormat.excel.isBinaryFormat, true);
    });

    test('pdf is binary', () {
      expect(ExportFormat.pdf.isBinaryFormat, true);
    });

    test('jiraCsv is not binary', () {
      expect(ExportFormat.jiraCsv.isBinaryFormat, false);
    });

    test('xrayJson is not binary', () {
      expect(ExportFormat.xrayJson.isBinaryFormat, false);
    });
  });

  group('requiresStructuredMapping', () {
    test('xrayJson requires mapping', () {
      expect(ExportFormat.xrayJson.requiresStructuredMapping, true);
    });

    test('others do not require mapping', () {
      expect(ExportFormat.excel.requiresStructuredMapping, false);
      expect(ExportFormat.pdf.requiresStructuredMapping, false);
      expect(ExportFormat.jiraCsv.requiresStructuredMapping, false);
    });
  });
}
