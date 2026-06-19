import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/error/exceptions.dart';
import 'package:qa_genie/features/export/writers/file_writer.dart';

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
        return Directory.systemTemp.path;
      },
    );
  });

  group('FileWriter.write', () {
    test('writes content to a file and returns File', () async {
      const content = 'Hello, World!';
      final file = await FileWriter.write(content, 'test_file', extension: 'txt');
      expect(file.existsSync(), true);
      expect(file.readAsStringSync(), content);
      file.deleteSync();
    });

    test('sanitizes file name with illegal characters', () async {
      const content = 'test content';
      final file = await FileWriter.write(content, 'test:file/name*with?illegal chars', extension: 'txt');
      expect(file.path, contains('test_file_name_with_illegal_chars.txt'));
      file.deleteSync();
    });

    test('uses default name when sanitized name is empty', () async {
      const content = 'test content';
      final file = await FileWriter.write(content, '   ', extension: 'txt');
      expect(file.path, contains('qa_genie_export.txt'));
      file.deleteSync();
    });
  });

  group('FileWriter.writeAndShare', () {
    test('throws ExportException when file write fails', () async {
      await expectLater(
        () => FileWriter.writeAndShare('content', '', extension: ''),
        throwsA(isA<ExportException>()),
      );
    });
  });
}
