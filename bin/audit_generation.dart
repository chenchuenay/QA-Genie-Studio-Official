
import 'package:qa_app/application/services/generation_service.dart';
import 'package:qa_app/data/models/test_case_model.dart';

void main() async {
  final service = GenerationService();

  print('--- AUDIT START ---');

  // 1. Web Login Suite
  print('\n[1] Generating Web Login Suite...');
  final resultWeb = await service.execute(
    module: 'Authentication',
    feature: 'Login',
    platform: 'Web',
    maxCases: 3,
  );
  _auditSuite('Web', resultWeb.cases);

  // 2. Mobile Login Suite
  print('\n[2] Generating Mobile Login Suite...');
  final resultMobile = await service.execute(
    module: 'Authentication',
    feature: 'Login',
    platform: 'Mobile',
    maxCases: 3,
  );
  _auditSuite('Mobile', resultMobile.cases);

  // 3. API Login Suite
  print('\n[3] Generating API Login Suite...');
  final resultApi = await service.execute(
    module: 'Authentication',
    feature: 'Login',
    platform: 'API',
    maxCases: 3,
  );
  _auditSuite('API', resultApi.cases);

  print('\n--- AUDIT COMPLETE ---');
}

void _auditSuite(String platform, List<TestCaseModel> cases) {
  print('Suite Size: ${cases.length}');
  for (var i = 0; i < cases.length; i++) {
    final tc = cases[i];
    print('  Case ${i + 1}: ${tc.title}');
    print('    Priority: ${tc.priority}');
    print('    Steps: ${tc.steps.length}');
    print('    Expected: ${tc.expectedResult}');
    
    // Check for platform contamination (basic check)
    final combined = '${tc.title} ${tc.expectedResult} ${tc.steps.map((s) => s.action).join(" ")}'.toLowerCase();
    if (platform == 'Web') {
      if (combined.contains('tap') || combined.contains('swipe') || combined.contains('biometric')) {
        print('    !!! ERROR: Mobile contamination found in Web case');
      }
    } else if (platform == 'Mobile') {
      if (combined.contains('right click') || combined.contains('hover') || combined.contains('ctrl+f5')) {
        print('    !!! ERROR: Web contamination found in Mobile case');
      }
    } else if (platform == 'API') {
      if (combined.contains('click') || combined.contains('tap') || combined.contains('screen')) {
        print('    !!! ERROR: UI contamination found in API case');
      }
    }
  }
}
