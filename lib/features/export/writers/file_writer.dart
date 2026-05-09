import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileWriter {
  static Future<void> writeAndShare(String content, String fileName,
      {String extension = 'txt'}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.$extension');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)]);
  }
}
