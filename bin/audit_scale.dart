
import 'package:qa_app/application/services/generation_service.dart';
import 'package:qa_app/data/models/test_case_model.dart';

void main() async {
  final service = GenerationService();
  final platforms = ['Web', 'Mobile', 'API'];
  final scopes = {'CORE': 10, 'PRO': 20};

  print('--- AUDIT START ---');

  for (var scope in scopes.entries) {
    print('\n[Scope: ${scope.key} - ${scope.value} cases per platform]');
    for (var platform in platforms) {
      print('\nGenerating $platform suite...');
      final cases = await service.execute(
        module: 'Authentication',
        feature: 'Login',
        platform: platform,
        maxCases: scope.value,
      );
      _auditSuite(platform, scope.key, cases);
    }
  }

  print('\n--- AUDIT COMPLETE ---');
}

void _auditSuite(String platform, String scope, List<TestCaseModel> cases) {
  print('  Suite Size: ${cases.length}');
  
  // Issues tracking
  final titles = <String>{};
  final steps = <String>{};
  
  for (var i = 0; i < cases.length; i++) {
    final tc = cases[i];
    
    // Check uniqueness (duplicate intent)
    if (titles.contains(tc.title)) {
      print('    !!! DUPLICATE TITLE: ${tc.title}');
    }
    titles.add(tc.title);
    
    // Check for implementation assumptions
    final combined = '${tc.title} ${tc.expectedResult} ${tc.steps.map((s) => s.action).join(" ")}'.toLowerCase();
    final forbidden = ['dom', 'css', 'hero', 'cookie', 'haptic', 'devtools', 'rfc', 'status code', 'jwt', 'bearer', 'keychain'];
    for (var term in forbidden) {
      if (combined.contains(term)) {
        print('    !!! ASSUMPTION FOUND ($term) in case: ${tc.title}');
      }
    }
  }
}
