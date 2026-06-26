package com.enaykumar.qagenie

import com.google.firebase.appcheck.FirebaseAppCheck
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "com.enaykumar.qagenie/app_check"
    ).setMethodCallHandler { call, result ->
      if (call.method == "installDevAppCheckProvider") {
        FirebaseAppCheck.getInstance().installAppCheckProviderFactory(DevAppCheckProviderFactory())
        result.success(true)
      } else {
        result.notImplemented()
      }
    }
  }
}
