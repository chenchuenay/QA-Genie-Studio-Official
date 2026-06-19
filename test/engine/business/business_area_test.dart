import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/business/business_area.dart';

void main() {
  group('BusinessArea', () {
    test('can be created with all fields', () {
      final area = BusinessArea(
        id: 'fin-001',
        domain: 'Finance',
        riskProfile: 'HIGH',
      );
      expect(area.id, 'fin-001');
      expect(area.domain, 'Finance');
      expect(area.riskProfile, 'HIGH');
    });

    test('BusinessArea is const', () {
      const area = BusinessArea(
        id: 'test',
        domain: 'Test',
        riskProfile: 'LOW',
      );
      expect(area.id, 'test');
    });

    test('can create with different risk profiles', () {
      final low = BusinessArea(id: '1', domain: 'D1', riskProfile: 'LOW');
      final medium = BusinessArea(id: '2', domain: 'D2', riskProfile: 'MEDIUM');
      final high = BusinessArea(id: '3', domain: 'D3', riskProfile: 'HIGH');
      expect(low.riskProfile, 'LOW');
      expect(medium.riskProfile, 'MEDIUM');
      expect(high.riskProfile, 'HIGH');
    });
  });
}
