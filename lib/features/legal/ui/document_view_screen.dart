import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/theme/app_spacing.dart';

class DocumentViewScreen extends StatelessWidget {
  final String title;
  final String content;

  const DocumentViewScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          content,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
