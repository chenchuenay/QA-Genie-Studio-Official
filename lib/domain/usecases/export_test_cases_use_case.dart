import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:qa_genie/core/error/exceptions.dart';
import 'package:qa_genie/core/utils/priority_utils.dart';
import 'package:qa_genie/engine/utils/pdf_text_sanitizer.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/features/export/adapters/csv_adapter.dart';
import 'package:qa_genie/features/export/adapters/pdf_adapter.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';
import 'package:qa_genie/features/export/adapters/json_adapter.dart';
import 'package:qa_genie/features/export/adapters/excel_adapter.dart';
import 'package:qa_genie/domain/usecases/export_validation_service.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:qa_genie/features/export/folder/export_folder_service.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart'; // ADDED

class ExportTestCasesUseCase {
  const ExportTestCasesUseCase();

  // ============================================================
  // MAIN EXECUTION (with ad token)
  // ============================================================
  Future<void> execute({
    required String type,
    required List<FinalizedTestCase> cases,
    String? moduleName,
    String? featureName,
    String? adToken,
  }) async {
    try {
      _validateOrThrow(cases);
      final effectiveModule =
          moduleName ?? (cases.isNotEmpty ? cases.first.module : 'Unknown');
      final effectiveFeature =
          featureName ?? (cases.isNotEmpty ? cases.first.feature : 'Unknown');
      final normalizedType = type.trim().toLowerCase();
      final safeModule = _safeModulePrefix(effectiveModule);
      final code = _shortCode();
      final fileName = 'TC_${safeModule}_${normalizedType}_$code';

      // Call cloud function to track export (with token)
      await FunctionsService.call(
        functionName: 'exportTrack',
        payload: {
          'isPro': await UsageManager.isPro(),
          'adToken': adToken,
          'exportType': normalizedType,
        },
      );

      switch (normalizedType) {
        case 'excel':
          await ExcelAdapter.export(
            cases,
            fileName: fileName,
            moduleName: effectiveModule,
            featureName: effectiveFeature,
          );
          break;
        case 'jira':
          await CsvAdapter.export(
            cases,
            fileName: fileName,
            moduleName: effectiveModule,
            featureName: effectiveFeature,
          );
          break;
        case 'xray':
          await JsonAdapter.export(
            cases,
            fileName: fileName,
            moduleName: effectiveModule,
            featureName: effectiveFeature,
          );
          break;
        case 'pdf':
          await PdfAdapter.export(
            cases,
            fileName: fileName,
            moduleName: effectiveModule,
            featureName: effectiveFeature,
          );
          break;
        default:
          throw ExportException('Unsupported export format: $type');
      }
    } catch (e) {
      throw ExportException('Export execution failed: $e');
    }
  }

  // ============================================================
  // SUMMARY REPORT (with ad token)
  // ============================================================
  Future<void> exportSummaryReport({
    required List<FinalizedTestCase> cases,
    String? moduleName,
    String? featureName,
    required String platform,
    required String testerName,
    required String environment,
    required BuildContext context,
    String? adToken,
  }) async {
    try {
      final effectiveModule =
          moduleName ?? (cases.isNotEmpty ? cases.first.module : 'Unknown');
      final effectiveFeature =
          featureName ?? (cases.isNotEmpty ? cases.first.feature : 'Unknown');

      // Call cloud function to track export (with token)
      await FunctionsService.call(
        functionName: 'exportTrack',
        payload: {
          'isPro': await UsageManager.isPro(),
          'adToken': adToken,
          'exportType': 'summary',
        },
      );

      final data = ExportMapper.toSummaryReport(
        cases,
        effectiveModule,
        effectiveFeature,
        platform,
        testerName,
        environment,
      );

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (context) => [
            _buildHeader(data),
            pw.SizedBox(height: 20),
            _buildExecutionSummary(data),
            pw.SizedBox(height: 20),
            _buildPriorityBreakdown(data),
            pw.SizedBox(height: 20),
            _buildDetailedResults(data['details'] as List),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Text(
                PdfTextSanitizer.sanitize(
                  'Generated by QA Genie - Test Summary Report',
                ),
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ),
          ],
        ),
      );

      final dir = await ExportFolderService.getPersistentDirectory();
      final code = _shortCode();
      final safeModule = _safeModulePrefix(effectiveModule);
      final file = File('${dir.path}/TSR_${safeModule}_$code.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      throw ExportException('Summary export failed: $e');
    }
  }

  // Helper methods (unchanged from original)
  pw.Widget _buildHeader(Map<String, dynamic> data) {
    final suiteName = _toString(data['suiteName']);
    final platformVal = _toString(data['platform']);
    final dateVal = _toString(data['date']);
    final testerVal = _toString(data['testerName']);
    final envVal = _toString(data['environment']);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          PdfTextSanitizer.sanitize('TEST SUMMARY REPORT'),
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        _labelValue('Suite', suiteName),
        _labelValue('Platform', platformVal),
        _labelValue('Date', dateVal),
        if (testerVal.isNotEmpty) _labelValue('Tester', testerVal),
        if (envVal.isNotEmpty) _labelValue('Environment', envVal),
      ],
    );
  }

  pw.Widget _labelValue(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 90,
          child: pw.Text(
            PdfTextSanitizer.sanitize('$label :'),
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            PdfTextSanitizer.sanitize(value),
            style: pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildExecutionSummary(Map<String, dynamic> data) {
    final total = _toString(data['total']);
    final passed = _toString(data['passed']);
    final failed = _toString(data['failed']);
    final blocked = _toString(data['blocked']);
    final notExecuted = _toString(data['notExecuted']);
    final passRate = _toString(data['passRate']);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          PdfTextSanitizer.sanitize('Execution Summary'),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _cell('Metric', bold: true),
                _cell('Value', bold: true),
              ],
            ),
            _metricRow('Total', total),
            _metricRow('Passed', passed),
            _metricRow('Failed', failed),
            _metricRow('Blocked', blocked),
            _metricRow('Not Executed', notExecuted),
            _metricRow('Pass Rate', '$passRate%'),
          ],
        ),
      ],
    );
  }

  pw.TableRow _metricRow(String label, dynamic value) =>
      pw.TableRow(children: [_cell(label), _cell(_toString(value))]);

  pw.Widget _buildPriorityBreakdown(Map<String, dynamic> data) {
    final breakdown = data['priorityBreakdown'] as Map<String, dynamic>? ?? {};
    final high = _toString(breakdown['HIGH']);
    final medium = _toString(breakdown['MEDIUM']);
    final low = _toString(breakdown['LOW']);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          PdfTextSanitizer.sanitize('Priority Breakdown'),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        _priorityLine('High', high),
        _priorityLine('Medium', medium),
        _priorityLine('Low', low),
      ],
    );
  }

  pw.Widget _priorityLine(String label, String count) => pw.Row(
    children: [
      pw.SizedBox(
        width: 60,
        child: pw.Text(
          PdfTextSanitizer.sanitize(label),
          style: pw.TextStyle(fontSize: 10),
        ),
      ),
      pw.Expanded(child: pw.Text(count, style: pw.TextStyle(fontSize: 10))),
    ],
  );

  pw.Widget _buildDetailedResults(List<dynamic> details) {
    if (details.isEmpty) return pw.Container();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          PdfTextSanitizer.sanitize('Detailed Results'),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(90),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FixedColumnWidth(60),
            3: const pw.FixedColumnWidth(80),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _cell('ID', bold: true),
                _cell('Title', bold: true),
                _cell('Priority', bold: true),
                _cell('Status', bold: true),
                _cell('Actual Result', bold: true),
              ],
            ),
            for (final item in details)
              pw.TableRow(
                children: [
                  _cell(_toString(item['id'])),
                  _cell(_toString(item['title'])),
                  _cell(PriorityUtils.normalize(_toString(item['priority']))),
                  _cell(_toString(item['status']).toUpperCase()),
                  _cell(_toString(item['actualResult'])),
                ],
              ),
          ],
        ),
      ],
    );
  }

  String _toString(dynamic value) => (value ?? '').toString();
  pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      PdfTextSanitizer.sanitize(text),
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  void _validateOrThrow(List<FinalizedTestCase> cases) {
    final validation = ExportValidationService.validate(cases);
    if (!validation.isValid)
      throw ExportException(validation.errors.join('\n'));
  }

  String _safeModulePrefix(String moduleName) {
    final cleaned = moduleName
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (cleaned.isEmpty) return 'MODULE';
    return cleaned.length > 20 ? cleaned.substring(0, 20) : cleaned;
  }

  String _shortCode() => (DateTime.now().millisecondsSinceEpoch % 10000)
      .toString()
      .padLeft(4, '0');
}
