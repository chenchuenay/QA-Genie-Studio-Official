import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkGuard {
  static Future<bool> hasInternet() async {
    final results = await Connectivity().checkConnectivity();
    // ConnectivityResult is now a set, check if not empty
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return false;
    }
    // Verify actual internet reachability
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<void> requireInternet() async {
    if (!await hasInternet()) throw Exception('No internet connection');
  }
}
