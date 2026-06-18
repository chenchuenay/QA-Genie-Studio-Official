// lib/domain/enums/generation_mode.dart
import 'package:qa_genie/app/config/app_config.dart';

enum GenerationMode { core, pro }

extension GenerationModeExtension on GenerationMode {
  int get testCaseCount {
    switch (this) {
      case GenerationMode.core:
        return AppConfig.coreCasesPerBatch;

      case GenerationMode.pro:
        return AppConfig.proCasesPerBatch;
    }
  }

  /// Export limits per day.
  ///
  /// -1 = unlimited
  int get exportLimit {
    switch (this) {
      case GenerationMode.core:
        return 50;

      case GenerationMode.pro:
        return -1;
    }
  }

  /// Summary export limits per day.
  int get summaryExportLimit {
    switch (this) {
      case GenerationMode.core:
        return 50;

      case GenerationMode.pro:
        return -1;
    }
  }

  bool get isUnlimited {
    return this == GenerationMode.pro;
  }

  bool get requiresAds {
    return this == GenerationMode.core;
  }

  bool get isPro {
    return this == GenerationMode.pro;
  }

  bool get isCore {
    return this == GenerationMode.core;
  }

  String get displayName {
    switch (this) {
      case GenerationMode.core:
        return 'CORE';

      case GenerationMode.pro:
        return 'PRO';
    }
  }

  /// Used by planners/orchestrators.
  double get happyPathRatio {
    switch (this) {
      case GenerationMode.core:
        return 0.8;

      case GenerationMode.pro:
        return 0.8;
    }
  }

  /// Used by planners/orchestrators.
  double get negativePathRatio {
    switch (this) {
      case GenerationMode.core:
        return 0.2;

      case GenerationMode.pro:
        return 0.2;
    }
  }
}
