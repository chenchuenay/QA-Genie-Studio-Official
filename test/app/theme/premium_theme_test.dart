import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/app/theme/premium_theme.dart';

void main() {
  test('premium_theme exports are accessible', () {
    expect(AppColors, isNotNull);
    expect(AppText, isNotNull);
    expect(AppSpacing, isNotNull);
    expect(AppRadius, isNotNull);
  });
}
