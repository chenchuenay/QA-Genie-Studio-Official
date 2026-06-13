// lib/domain/enums/export_format.dart

/// Supported deterministic export targets.
enum ExportFormat { excel, pdf, jiraCsv, xrayJson }

extension ExportFormatExtension on ExportFormat {
  String get displayName {
    switch (this) {
      case ExportFormat.excel:
        return 'Excel';

      case ExportFormat.pdf:
        return 'PDF';

      case ExportFormat.jiraCsv:
        return 'Jira CSV';

      case ExportFormat.xrayJson:
        return 'Xray JSON';
    }
  }

  String get fileExtension {
    switch (this) {
      case ExportFormat.excel:
        return '.xlsx';

      case ExportFormat.pdf:
        return '.pdf';

      case ExportFormat.jiraCsv:
        return '.csv';

      case ExportFormat.xrayJson:
        return '.json';
    }
  }

  bool get isBinaryFormat {
    return this == ExportFormat.excel || this == ExportFormat.pdf;
  }

  bool get requiresStructuredMapping {
    return this == ExportFormat.xrayJson;
  }
}
