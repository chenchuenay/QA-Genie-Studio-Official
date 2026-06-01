// ============================================================
// CENTRALIZED INPUT FOR ALL HEADLESS TESTS
// Edit these values manually before running tests.
// ============================================================

class GenerationInputs {
  // Basic test parameters
  static String module = 'login';
  static String feature = 'user login';
  static String constraints = ''; // empty = no constraints

  // Platform selection: index into platforms list
  static List<String> platforms = ['WEB', 'MOBILE', 'API'];
  static int platformIndex = 2; // 0 = WEB, 1 = MOBILE, 2 = API

  // Mode selection: 0 = core, 1 = pro
  static int modeCode = 0; // change to 1 for pro mode

  // Convenience getter
  static bool get isPro => modeCode == 1;

  // Cooldown between platforms in live mass test
  static const cooldownBetweenPlatforms = Duration(seconds: 60);
}
