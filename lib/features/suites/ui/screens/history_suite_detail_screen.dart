import 'package:flutter/material.dart';
import 'package:qa_genie/features/generation/ui/screens/preview_screen.dart';
import 'package:qa_genie/data/models/test_case_model.dart';

class HistorySuiteDetailScreen extends StatelessWidget {
  final List<TestCaseModel> testCases;
  final String moduleName, feature, platform;
  final int suiteId;
  const HistorySuiteDetailScreen({
    super.key,
    required this.testCases,
    required this.moduleName,
    required this.feature,
    required this.platform,
    required this.suiteId,
  });
  @override
  Widget build(BuildContext context) => PreviewScreen(
    testCases: testCases,
    moduleName: moduleName,
    feature: feature,
    platform: platform,
    suiteId: suiteId,
  );
}
