import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_text.dart';

void main() {
  group('AppText', () {
    test('appTitle has correct fontSize', () {
      expect(AppText.appTitle.fontSize, 24);
      expect(AppText.appTitle.fontWeight, FontWeight.w700);
    });

    test('screenTitle has correct fontSize', () {
      expect(AppText.screenTitle.fontSize, 20);
      expect(AppText.screenTitle.fontWeight, FontWeight.w700);
    });

    test('section has correct properties', () {
      expect(AppText.section.fontSize, 15);
      expect(AppText.section.fontWeight, FontWeight.w600);
      expect(AppText.section.letterSpacing, 3.5);
    });

    test('cardTitle has correct fontSize', () {
      expect(AppText.cardTitle.fontSize, 16);
      expect(AppText.cardTitle.fontWeight, FontWeight.w600);
    });

    test('body has correct fontSize', () {
      expect(AppText.body.fontSize, 14);
      expect(AppText.body.fontWeight, FontWeight.w500);
    });

    test('label has correct properties', () {
      expect(AppText.label.fontSize, 13);
      expect(AppText.label.fontWeight, FontWeight.w500);
    });

    test('input has correct fontSize', () {
      expect(AppText.input.fontSize, 17);
      expect(AppText.input.fontWeight, FontWeight.w500);
    });

    test('button has correct properties', () {
      expect(AppText.button.fontSize, 16);
      expect(AppText.button.fontWeight, FontWeight.w700);
      expect(AppText.button.color, Colors.black);
    });

    test('chip has correct fontSize', () {
      expect(AppText.chip.fontSize, 11);
      expect(AppText.chip.fontWeight, FontWeight.w700);
    });

    test('hint has correct properties', () {
      expect(AppText.hint.fontSize, 13);
      expect(AppText.hint.color, const Color(0xFF72798A));
    });

    test('subheading has correct properties', () {
      expect(AppText.subheading.fontSize, 15);
      expect(AppText.subheading.fontWeight, FontWeight.w600);
      expect(AppText.subheading.letterSpacing, 3.5);
    });
  });
}
