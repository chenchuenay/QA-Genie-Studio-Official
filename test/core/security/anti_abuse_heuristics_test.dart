import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/security/anti_abuse_heuristics.dart';

void main() {
  group('AntiAbuseHeuristics', () {
    setUp(() {
      AntiAbuseHeuristics.reset();
    });

    test('passes for first valid request', () {
      final result = AntiAbuseHeuristics.validate(module: 'Auth', feature: 'Login', platform: 'Web', count: 5);
      expect(result.blocked, false);
      expect(result.riskScore, 0);
    });

    test('detects excessive generation count', () {
      final result = AntiAbuseHeuristics.validate(module: 'M', feature: 'F', platform: 'W', count: 50);
      expect(result.findings, contains('excessive_generation_count'));
    });

    test('detects rapid fire requests', () {
      AntiAbuseHeuristics.validate(module: 'M', feature: 'F', platform: 'W', count: 5);
      final result = AntiAbuseHeuristics.validate(module: 'M', feature: 'F2', platform: 'W', count: 5);
      expect(result.findings, contains('rapid_fire_detected'));
    });
  });
}
