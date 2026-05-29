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
  static int platformIndex = 0; // 0 = WEB, 1 = MOBILE, 2 = API

  // Mode: false = core (8 cases), true = pro (16 cases)
  static bool isPro = false;

  // Cooldown between platforms in live mass test
  static const cooldownBetweenPlatforms = Duration(seconds: 60);
}
