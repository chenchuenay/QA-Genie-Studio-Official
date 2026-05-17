import 'package:qa_genie/app/config/app_config.dart';

class LoggingConfig {
  static bool get forensicLogging => AppConfig.forensicLogging;

  static String pipelineFilePath(String mode) {
    return mode == 'core' ? 'cache/test_results/core_pipeline.txt' : 'cache/test_results/pro_pipeline.txt';
  }

  static String analyticalFilePath(String mode) {
    return mode == 'core' ? 'cache/test_results/core_analytical_logs.txt' : 'cache/test_results/pro_analytical_logs.txt';
  }
}
