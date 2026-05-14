import 'package:qa_genie/domain/usecases/export_validation_service.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/features/export/adapters/json_adapter.dart';
import 'package:qa_genie/features/export/adapters/csv_adapter.dart';
import 'package:qa_genie/features/export/adapters/excel_adapter.dart';
import 'package:qa_genie/features/export/adapters/pdf_adapter.dart';
import 'package:qa_genie/features/export/folder/export_folder_service.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';
import 'package:qa_genie/core/utils/priority_utils.dart';

class ExportTestCasesUseCase {
  static const _formatNames = {
    'excel': 'Excel',
    'jira': 'Jira',
    'xray': 'Xray',
    'pdf': 'PDF',
  };

  String _shortCode() {
    final r = DateTime.now().millisecondsSinceEpoch % 10000;
    return r.toString().padLeft(4, '0');
  }

  String _safeModulePrefix(String moduleName) {
    final cleaned = moduleName
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final fallback = cleaned.isEmpty ? 'MODULE' : cleaned;
    return fallback.length > 20 ? fallback.substring(0, 20) : fallback;
  }

  void _validateOrThrow(List<TestCaseModel> cases) {
    final validation = ExportValidationService.validate(cases);
    if (!validation.isValid) {
      throw Exception('Export validation failed:\n${validation.errors.map((e) => '  - $e').join('\n')}');
    }
  }

  Future<void> execute({
    required String type,
    required List<TestCaseModel> cases,
    required String moduleName,
    String? featureName,
  }) async {
    _validateOrThrow(cases);
    await ExportFolderService.getTestCaseDirectory(
      _formatNames[type] ?? type.toUpperCase(),
    );
    final code = _shortCode();
    final safeModule = _safeModulePrefix(moduleName);
    final fileName = 'TC_${safeModule}_${type}_$code';

    switch (type) {
      case 'excel':
        await ExcelAdapter.export(
          cases,
          fileName: fileName,
          moduleName: moduleName,
          featureName: featureName ?? '',
        );
        break;
      case 'jira':
        await CsvAdapter.export(
          cases,
          fileName: fileName,
          moduleName: moduleName,
          featureName: featureName ?? '',
        );
        break;
      case 'xray':
        await JsonAdapter.export(
          cases,
          fileName: fileName,
          moduleName: moduleName,
          featureName: featureName ?? '',
        );
        break;
      case 'pdf':
        await PdfAdapter.export(
          cases,
          fileName: fileName,
          moduleName: moduleName,
          featureName: featureName ?? '',
        );
        break;
      default:
        throw Exception('Unsupported format');
    }
  }

  Future<void> exportSummaryReport({
    required List<TestCaseModel> cases,
    required String moduleName,
    required String featureName,
    required String platform,
    required String testerName,
    required String environment,
  }) async {
    final data = ExportMapper.toSummaryReport(
      cases,
      moduleName,
      featureName,
      platform,
      testerName,
      environment,
    );
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (ctx) => [
          pw.Text(
            'Test Summary Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            "Suite: ${data['suiteName']}",
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.Text(
            "Platform: ${data['platform']}",
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.Text(
            "Date: ${data['date']}",
            style: const pw.TextStyle(fontSize: 11),
          ),
          if (data['testerName'].toString().isNotEmpty)
            pw.Text(
              "Tester: ${data['testerName']}",
              style: const pw.TextStyle(fontSize: 11),
            ),
          if (data['environment'].toString().isNotEmpty)
            pw.Text(
              "Environment: ${data['environment']}",
              style: const pw.TextStyle(fontSize: 11),
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Execution Summary',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _summaryTable(data),
          pw.SizedBox(height: 16),
          if (data['priorityBreakdown'] is List)
            ...(data['priorityBreakdown'] as List).map(
              (line) => pw.Text(
                line.toString(),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Detailed Results',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _detailedTable(data['details'] as List),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'Generated by QA Genie',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );

    final dir = await ExportFolderService.getSummaryReportDirectory();
    final code = _shortCode();
    final safeModule = _safeModulePrefix(moduleName);
    final file = File('${dir.path}/TSR_${safeModule}_$code.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)]);
  }

  pw.Widget _summaryTable(Map<String, dynamic> data) {
    final labels = [
      'Total',
      'Passed',
      'Failed',
      'Blocked',
      'Not Executed',
      'Pass Rate',
    ];
    final keys = [
      'total',
      'passed',
      'failed',
      'blocked',
      'notExecuted',
      'passRate',
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1)},
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: ['Metric', 'Value']
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...List.generate(labels.length, (i) {
          final key = keys[i];
          final val = key == 'passRate'
              ? '${data['passRate']}%'
              : (data[key] ?? 0).toString();
          return pw.TableRow(
            children: [labels[i], val]
                .map(
                  (t) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(t, style: const pw.TextStyle(fontSize: 10)),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  pw.Widget _detailedTable(List details) {
    final safeDetails = List.from(details);
    if (safeDetails.isEmpty) return pw.Container();
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: pw.FixedColumnWidth(90),
        1: pw.FlexColumnWidth(3),
        2: pw.FixedColumnWidth(55),
        3: pw.FixedColumnWidth(75),
        4: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: ['ID', 'Title', 'Priority', 'Status', 'Actual Result']
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...safeDetails.map((d) {
          final id = (d['id'] ?? '').toString();
          final title = (d['title'] ?? '').toString();
          final prio = PriorityUtils.normalize(
            (d['priority'] ?? 'Medium').toString(),
          );
          final status = (d['status'] ?? 'Not Executed').toString();
          final actual = (d['actualResult'] ?? '').toString();
          return pw.TableRow(
            children: [id, title, prio, status, actual]
                .map(
                  (t) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      t.toString(),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }
}
