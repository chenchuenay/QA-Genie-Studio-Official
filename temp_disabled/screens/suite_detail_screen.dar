import 'package:flutter/material.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/features/generation/ui/screens/preview_screen.dart';

class HistorySuiteDetailScreen extends StatelessWidget {
  final GenerationSession session;
  final String moduleName;
  final String feature;
  final String platform;
  final int suiteId;

  const HistorySuiteDetailScreen({
    super.key,
    required this.session,
    required this.moduleName,
    required this.feature,
    required this.platform,
    required this.suiteId,
  });

  @override
  Widget build(BuildContext context) {
    return PreviewScreen(
      session: session,
      moduleName: moduleName,
      feature: feature,
      platform: platform,
      suiteId: suiteId,
    );
  }
}
