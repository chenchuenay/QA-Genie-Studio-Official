import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/export/folder/export_folder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getTemporaryDirectory') {
          return Directory.systemTemp.path;
        }
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );
  });

  group('ExportFolderService', () {
    test('getTempDirectory returns a directory', () async {
      final dir = await ExportFolderService.getTempDirectory();
      expect(dir.existsSync(), true);
      expect(dir.path, endsWith('qa_genie_exports'));
      dir.deleteSync(recursive: true);
    });

    test('getPersistentDirectory returns a directory', () async {
      final dir = await ExportFolderService.getPersistentDirectory();
      expect(dir.existsSync(), true);
      expect(dir.path, endsWith('qa_genie_exports'));
      dir.deleteSync(recursive: true);
    });

    test('clearTempExports does not throw', () async {
      await expectLater(
        () => ExportFolderService.clearTempExports(),
        returnsNormally,
      );
    });

    test('fileExists returns false for non-existent file', () async {
      final exists = await ExportFolderService.fileExists(
        'nonexistent',
        extension: 'txt',
      );
      expect(exists, false);
    });

    test('fileExists returns true for existing file', () async {
      final dir = await ExportFolderService.getTempDirectory();
      final file = File('${dir.path}/exists_test.txt');
      await file.writeAsString('test');
      final exists = await ExportFolderService.fileExists(
        'exists_test',
        extension: 'txt',
      );
      expect(exists, true);
      await file.delete();
      dir.deleteSync(recursive: true);
    });

    test('resolveFile returns a File at the correct path', () async {
      final file = await ExportFolderService.resolveFile(
        'myfile',
        extension: 'pdf',
      );
      expect(file.path, endsWith('qa_genie_exports/myfile.pdf'));
    });
  });
}
