/// test/forensic_tests/support/test_pipeline_observer.dart
library;

import 'dart:io';
import 'package:qa_genie/engine/forensics/pipeline_observer.dart';

class TestPipelineObserver implements PipelineObserver {
  final File _file = File('test_results/gen_results/ai_forensic_trace.txt');

  void clear() {
    if (_file.existsSync()) {
      _file.deleteSync();
    }
    if (!_file.parent.existsSync()) {
      _file.parent.createSync(recursive: true);
    }
    _file.writeAsStringSync('', mode: FileMode.write);
  }

  @override
  void onStageEvent(String category, Map<String, dynamic> data) {
    _file.writeAsStringSync('\n[$category]\n', mode: FileMode.append);
    data.forEach((key, value) {
      _file.writeAsStringSync('$key=$value\n', mode: FileMode.append);
    });
  }

  @override
  void onTraceEvent(String message) {
    _file.writeAsStringSync('$message\n', mode: FileMode.append);
  }
}
