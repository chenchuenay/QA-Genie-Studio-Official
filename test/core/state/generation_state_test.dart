import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/state/generation_state.dart';

void main() {
  group('GenerationState', () {
    test('isGenerating starts as false', () {
      expect(GenerationState.isGenerating.value, false);
    });

    test('isGenerating can be set to true', () {
      GenerationState.isGenerating.value = true;
      expect(GenerationState.isGenerating.value, true);
      GenerationState.isGenerating.value = false;
    });

    test('isGenerating notifies listeners', () {
      int notified = 0;
      final listener = () { notified++; };
      GenerationState.isGenerating.addListener(listener);
      GenerationState.isGenerating.value = true;
      expect(notified, 1);
      GenerationState.isGenerating.value = false;
      expect(notified, 2);
      GenerationState.isGenerating.removeListener(listener);
    });
  });
}
