import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/router/app_router.dart';

void main() {
  group('AppRouter', () {
    test('startupRoute is /', () {
      expect(AppRouter.startupRoute, '/');
    });

    test('generateRoute returns route for /', () {
      final route = AppRouter.generateRoute(const RouteSettings(name: '/'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('generateRoute returns unknown route for undefined path', () {
      final route = AppRouter.generateRoute(const RouteSettings(name: '/undefined'));
      expect(route, isA<MaterialPageRoute>());
    });
  });
}
