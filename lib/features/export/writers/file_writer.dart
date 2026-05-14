import 'dart:io';
import 'package:qa_genie/features/export/folder/export_folder_service.dart';
import 'package:share_plus/share_plus.dart';

class FileWriter {
  static Future<void> writeAndShare(String content, String fileName,
      {String extension = 'txt'}) async {
    final dir = await ExportFolderService.getTempDirectory();
    final file = File('${dir.path}/$fileName.$extension');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)]);
  }
}
