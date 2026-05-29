// lib/domain/enums/generation_mode.dart

/// QA Genie generation plans.
///
/// CORE:
/// - 1 free generation
/// - 5 rewarded ad generations/day
/// - 8 testcases/generation
/// - limited exports
///
/// PRO:
/// - 15 generations/day
/// - 16 testcases/generation
/// - unlimited exports
enum GenerationMode { core, pro }

extension GenerationModeExtension on GenerationMode {
  /// Total generations allowed per day.
  int get generationLimit {
    switch (this) {
      case GenerationMode.core:
        return 6; // 1 free + 5 rewarded

      case GenerationMode.pro:
        return 15;
    }
  }

  /// Testcases generated per request.
  int get testCaseCount {
    switch (this) {
      case GenerationMode.core:
        return 8;

      case GenerationMode.pro:
        return 16;
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
