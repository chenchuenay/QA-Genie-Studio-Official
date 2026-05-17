class AppConfig {
  static const bool forensicLogging = bool.fromEnvironment("FORENSIC_LOGGING", defaultValue: false);

  static const bool isProduction = false;
  static bool testProMode = false;
  static const int maxConstraintsLength = 100;
}
