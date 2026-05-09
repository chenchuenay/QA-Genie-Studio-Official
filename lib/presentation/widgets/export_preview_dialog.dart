import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qa_app/features/export/common/export_mapper.dart';
import 'package:qa_app/core/theme/constants.dart';
import 'package:qa_app/data/models/test_case_model.dart';

class ExportPreviewDialog extends StatefulWidget {
  final String type;
  final List<TestCaseModel> cases;
  final String moduleName;
  final String featureName;
  final Function(List<List<String>> editedData) onConfirm;

  const ExportPreviewDialog({
    super.key,
    required this.type,
    required this.cases,
    required this.moduleName,
    required this.featureName,
    required this.onConfirm,
  });

  @override
  State<ExportPreviewDialog> createState() => _ExportPreviewDialogState();
}

class _ExportPreviewDialogState extends State<ExportPreviewDialog> {
  late List<List<String>> _data;
  late List<List<TextEditingController>> _controllers;
  bool _editing = false;

  // Column widths – generous for IDs and descriptions
  static const List<double> _colWidths = [
    90, // ID (wider to avoid truncation)
    80, // Module / TestType
    80, // Feature / IssueType
    160, // Title / Summary
    120, // Preconditions / Description
    110, // Test Data / Priority
    130, // Test Steps / Status
    120, // Expected Result
    100, // Actual Result
    90, // Status
    80, // Priority
  ];

  double _totalWidth(int count) {
    double total = 0;
    for (int i = 0; i < count && i < _colWidths.length; i++) {
      total += _colWidths[i];
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _data = _getMappedData();
    _controllers = _data
        .map(
          (row) =>
              row.map((cell) => TextEditingController(text: cell)).toList(),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final row in _controllers) {
      for (final ctrl in row) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  List<List<String>> _getMappedData() {
    switch (widget.type) {
      case "excel":
        return ExportMapper.toExcel(
          widget.cases,
          moduleName: widget.moduleName,
          featureName: widget.featureName,
        );
      case "jira":
        return ExportMapper.toJira(
          widget.cases,
          featureName: widget.featureName,
        );
      case "xray":
        final jsonData = ExportMapper.toXray(
          widget.cases,
          moduleName: widget.moduleName,
          featureName: widget.featureName,
        );
        if (jsonData.isEmpty) return [];
        final keys = [
          "issueId",
          "summary",
          "testType",
          "description",
          "precondition",
          "priority",
          "status",
          "steps",
        ];
        final rows = <List<String>>[keys];
        for (final obj in jsonData) {
          rows.add(
            keys.map((k) {
              if (k == "steps") {
                return jsonEncode(obj[k] ?? []);
              }
              return (obj[k] ?? '').toString();
            }).toList(),
          );
        }
        return rows;
      case "pdf":
        final pdfData = ExportMapper.toPdf(widget.cases);
        if (pdfData.isEmpty) return [];
        final keys = [
          "ID",
          "Title",
          "Preconditions",
          "Steps",
          "Test Data",
          "Expected Result",
          "Actual",
          "Status",
        ];
        final rows = <List<String>>[keys];
        for (final obj in pdfData) {
          rows.add(keys.map((k) => (obj[k] ?? '').toString()).toList());
        }
        return rows;
      default:
        return [];
    }
  }

  List<List<String>> _collectEditedData() {
    return _controllers
        .map((row) => row.map((ctrl) => ctrl.text).toList())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final headers = _data.isNotEmpty ? _data.first : <String>[];
    final rowCount = _controllers.length - 1;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Export View – ${widget.type}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _editing ? Icons.visibility : Icons.edit,
                    color: AppColors.accentLight,
                    size: 22,
                  ),
                  tooltip: _editing ? 'Done' : 'Edit',
                  onPressed: () => setState(() => _editing = !_editing),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _totalWidth(headers.length),
                  child: Column(
                    children: [
                      // Header row
                      Row(
                        children: List.generate(headers.length, (col) {
                          return Container(
                            width: col < _colWidths.length
                                ? _colWidths[col]
                                : 100,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            color: AppColors.card,
                            child: Text(
                              headers[col],
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ),
                      // Data rows
                      Expanded(
                        child: ListView.builder(
                          itemCount: rowCount,
                          itemBuilder: (context, rowIdx) {
                            return Row(
                              children: List.generate(headers.length, (col) {
                                final w = col < _colWidths.length
                                    ? _colWidths[col]
                                    : 100.0;
                                return Container(
                                  width: w,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  child: _editing
                                      ? TextField(
                                          controller:
                                              _controllers[rowIdx + 1][col],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                          maxLines: null,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 4,
                                                ),
                                            border: OutlineInputBorder(),
                                          ),
                                        )
                                      : Text(
                                          _controllers[rowIdx + 1][col].text,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onConfirm(_collectEditedData());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  child: const Text(
                    "Share",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
