import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> share(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }
}
