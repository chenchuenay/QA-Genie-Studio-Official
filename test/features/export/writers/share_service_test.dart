import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/error/exceptions.dart';
import 'package:qa_genie/features/export/writers/share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('share_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ShareService.shareFile', () {
    test('throws ExportException when file does not exist', () async {
      final file = File('${tempDir.path}/nonexistent.txt');
      await expectLater(
        () => ShareService.shareFile(file),
        throwsA(isA<ExportException>()),
      );
    });
  });

  group('ShareService.shareFiles', () {
    test('throws ExportException when list is empty', () async {
      await expectLater(
        () => ShareService.shareFiles([]),
        throwsA(isA<ExportException>()),
      );
    });

    test('throws ExportException when no files exist', () async {
      final files = [File('${tempDir.path}/missing.txt')];
      await expectLater(
        () => ShareService.shareFiles(files),
        throwsA(isA<ExportException>()),
      );
    });
  });
}
