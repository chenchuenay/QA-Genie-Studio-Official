import 'package:flutter/material.dart';
import 'package:qa_app/app/theme/constants_premium.dart';
import 'package:qa_app/design_preview/home_preview.dart';

void main() {
  runApp(const DesignPreviewApp());
}

class DesignPreviewApp extends StatelessWidget {
  const DesignPreviewApp({super.key});
  @override Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QA Genie Design Preview',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(primary: Color(0xFF3DDCFF), secondary: Color(0xFF3DDCFF), surface: Color(0xFF0D1018)),
      ),
      home: const HomePreview(),
    );
  }
}
