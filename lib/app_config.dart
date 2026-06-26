class AppConfig {
  AppConfig._();

  /// When true, the app connects to the dev Firebase project
  /// (qa-genie-ai-dev) and uses debug AppCheck. Pass at build time:
  ///
  ///     flutter run --dart-define=IS_DEV=true
  ///
  /// Defaults to false → production (qa-genie-ai).
  static const bool isDev = bool.fromEnvironment('IS_DEV', defaultValue: false);
}
