import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';

class ExportPreviewDialog extends StatefulWidget {
  final String type;
  final List<FinalizedTestCase> cases;
  final String moduleName;
  final String featureName;
  final Function(List<FinalizedTestCase> updatedCases) onSave;
  final Function(List<FinalizedTestCase> updatedCases) onShare;

  const ExportPreviewDialog({
    super.key,
    required this.type,
    required this.cases,
    required this.moduleName,
    required this.featureName,
    required this.onSave,
    required this.onShare,
  });

  @override
  State<ExportPreviewDialog> createState() => _ExportPreviewDialogState();
}

class _ExportPreviewDialogState extends State<ExportPreviewDialog> {
  late List<List<String>> _data;
  late List<List<TextEditingController>> _controllers;
  bool _editing = false;

  static const List<double> _colWidths = [120, 100, 100, 200, 150, 130, 350, 160, 120, 100, 100];

  double _totalWidth(int count) {
    double total = 0;
    for (int i = 0; i < count && i < _colWidths.length; i++) total += _colWidths[i];
    return total;
  }

  @override
  void initState() {
    super.initState();
    _data = _getMappedData();
    _controllers = _data.map((row) => row.map((cell) => TextEditingController(text: cell)).toList()).toList();
  }

  @override
  void dispose() {
    for (final row in _controllers) for (final ctrl in row) ctrl.dispose();
    super.dispose();
  }

  List<List<String>> _getMappedData() {
    switch (widget.type) {
      case "excel":
        return ExportMapper.toExcel(widget.cases, moduleName: widget.moduleName, featureName: widget.featureName);
      case "jira":
        return ExportMapper.toJira(widget.cases, featureName: widget.featureName);
      case "xray":
        final jsonData = ExportMapper.toXray(widget.cases, moduleName: widget.moduleName, featureName: widget.featureName);
        if (jsonData.isEmpty) return [];
        final keys = ["issueId", "summary", "testType", "description", "precondition", "priority", "status", "steps"];
        final rows = <List<String>>[keys];
        for (final obj in jsonData) {
          final row = <String>[];
          for (final k in keys) {
            if (k == "steps") {
              dynamic stepsRaw = obj[k];
              List stepsList = [];
              if (stepsRaw is String) try { stepsList = jsonDecode(stepsRaw); } catch(_) {}
              else if (stepsRaw is List) stepsList = stepsRaw;
              final buffer = StringBuffer();
              for (int i = 0; i < stepsList.length; i++) {
                final step = stepsList[i];
                buffer.writeln('${i+1}. ${step['action'] ?? ''}');
                if ((step['data'] ?? '').isNotEmpty) buffer.writeln('   Data: ${step['data']}');
                if ((step['expected'] ?? '').isNotEmpty) buffer.writeln('   Expected: ${step['expected']}');
              }
              row.add(buffer.toString().trim());
            } else {
              row.add((obj[k] ?? '').toString());
            }
          }
          rows.add(row);
        }
        return rows;
      case "pdf":
        final pdfData = ExportMapper.toPdf(widget.cases);
        if (pdfData.isEmpty) return [];
        final keys = ["ID", "Title", "Preconditions", "Steps", "Test Data", "Expected Result", "Actual", "Status"];
        final rows = <List<String>>[keys];
        for (final obj in pdfData) rows.add(keys.map((k) => (obj[k] ?? '').toString()).toList());
        return rows;
      default: return [];
    }
  }

  List<List<String>> _collectEditedData() => _controllers.map((row) => row.map((ctrl) => ctrl.text).toList()).toList();

  List<FinalizedTestCase> _updateOriginalCasesFromEditedData(List<List<String>> editedData) {
    if (editedData.length <= 1) return widget.cases;
    final headers = editedData.first;
    final updatedCases = <FinalizedTestCase>[];
    for (int rowIdx = 0; rowIdx < editedData.length - 1; rowIdx++) {
      if (rowIdx >= widget.cases.length) break;
      final original = widget.cases[rowIdx];
      final row = editedData[rowIdx + 1];
      var updated = original;
      for (int colIdx = 0; colIdx < headers.length && colIdx < row.length; colIdx++) {
        final header = headers[colIdx].toLowerCase();
        final newValue = row[colIdx];
        if (newValue == _data[rowIdx + 1][colIdx]) continue;
        switch (header) {
          case "id": case "issueid": updated = updated.copyWith(id: newValue); break;
          case "title": case "summary": updated = updated.copyWith(title: newValue); break;
          case "module": updated = updated.copyWith(module: newValue); break;
          case "feature": updated = updated.copyWith(feature: newValue); break;
          case "platform": updated = updated.copyWith(platform: newValue); break;
          case "priority": updated = updated.copyWith(priority: newValue); break;
          case "type": case "testtype": updated = updated.copyWith(type: newValue); break;
          case "preconditions": case "precondition": case "description":
            updated = updated.copyWith(preconditions: newValue.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()); break;
          case "expected result": updated = updated.copyWith(expectedResult: newValue); break;
          case "actual result": case "actual": updated = updated.copyWith(actualResult: newValue); break;
          case "status": updated = updated.copyWith(status: newValue); break;
        }
      }
      // Preserve the original dbId so database replacement works correctly
      if (original.dbId != null) updated = updated.copyWith(dbId: original.dbId);
      updatedCases.add(updated);
    }
    return updatedCases;
  }

  void _performSave() {
    final editedData = _collectEditedData();
    final updatedCases = _updateOriginalCasesFromEditedData(editedData);
    widget.onSave(updatedCases);
  }

  void _performShare() {
    final editedData = _collectEditedData();
    final updatedCases = _updateOriginalCasesFromEditedData(editedData);
    widget.onShare(updatedCases);
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
                Text("Export View – ${widget.type}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(_editing ? Icons.visibility : Icons.edit, color: AppColors.accentLight, size: 22),
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
                      Row(children: List.generate(headers.length, (col) => Container(
                        width: col < _colWidths.length ? _colWidths[col] : 100,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        color: AppColors.card,
                        child: Text(headers[col], style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                      ))),
                      Expanded(
                        child: ListView.builder(
                          itemCount: rowCount,
                          itemBuilder: (context, rowIdx) => Row(
                            children: List.generate(headers.length, (col) {
                              final w = col < _colWidths.length ? _colWidths[col] : 100.0;
                              return Container(
                                width: w,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                child: _editing
                                  ? TextField(
                                      controller: _controllers[rowIdx + 1][col],
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                      maxLines: null,
                                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4), border: OutlineInputBorder()),
                                    )
                                  : Text(_controllers[rowIdx + 1][col].text, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!_editing)
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                ElevatedButton(onPressed: _performShare, style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent), child: const Text("Share", style: TextStyle(color: Colors.black))),
              ]),
            if (_editing)
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary))),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _performSave, style: ElevatedButton.styleFrom(backgroundColor: AppColors.success), child: const Text("Save", style: TextStyle(color: Colors.black))),
              ]),
          ],
        ),
      ),
    );
  }
}