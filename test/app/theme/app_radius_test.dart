import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/app/theme/app_radius.dart';

void main() {
  group('AppRadius', () {
    test('input radius is 22', () {
      expect(AppRadius.input, 22);
    });

    test('button radius is 22', () {
      expect(AppRadius.button, 22);
    });

    test('card radius is 24', () {
      expect(AppRadius.card, 24);
    });

    test('bottomSheet radius is 30', () {
      expect(AppRadius.bottomSheet, 30);
    });

    test('dialog radius is 34', () {
      expect(AppRadius.dialog, 34);
    });

    test('chip radius is 18', () {
      expect(AppRadius.chip, 18);
    });
  });
}
