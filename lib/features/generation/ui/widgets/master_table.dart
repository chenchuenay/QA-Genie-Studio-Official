import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/core/utils/priority_utils.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/engine/risk/risk_scorer.dart';

const _cyanColor = AppColors.accent;
const _dividerColor = Color(0xFF2A2A3A);
const _textPrimary = Colors.white;
const _textSecondary = Color(0xFFCCCCCC);
const _pillBg = Color(0xFF2A2A3A);
const _fieldBg = Color(0xFF1A1A2E);
const _counterStyle = TextStyle(fontSize: 8, color: Colors.white38, height: 1);

class MasterTable extends StatefulWidget {
  final List<FinalizedTestCase> testCases;
  final bool isEditable;
  final VoidCallback? onCellEdit;
  final int? suiteId;
  final Future<List<Map<String, dynamic>>> Function()? getOtherSuites;
  final bool selectionMode;
  final Set<int> selectedIndices;
  final ValueChanged<Set<int>>? onSelectionChanged;
  final bool riskMode;
  final Map<String, int>? riskScores;
  final ValueChanged<bool>? onDuplicateChange;

  const MasterTable({
    super.key,
    required this.testCases,
    required this.isEditable,
    this.onCellEdit,
    this.suiteId,
    this.getOtherSuites,
    this.selectionMode = false,
    this.selectedIndices = const {},
    this.onSelectionChanged,
    this.riskMode = false,
    this.riskScores,
    this.onDuplicateChange,
  });

  @override
  State<MasterTable> createState() => _MasterTableState();
}

class _MasterTableState extends State<MasterTable> {
  late _LazyCtrlList idCtrls, titleCtrls, preCtrls, stepsCtrls,
      dataCtrls, expectedCtrls, actualCtrls, statusCtrls;

  final List<double> colWidths = [85, 150, 170, 180, 140, 180, 140, 110, 90];
  final Set<int> _duplicateIndices = {};
  static const double _checkboxWidth = 44;
  static const double _riskColumnWidth = 100;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant MasterTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.testCases != widget.testCases) {
      _disposeControllers();
      _initControllers();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initControllers() {
    for (final tc in widget.testCases) {
      tc.priority = PriorityUtils.normalize(tc.priority);
      if (tc.status.trim().isEmpty) tc.status = 'Not Executed';
    }

    idCtrls = _LazyCtrlList(widget.testCases, (tc) => tc.id);
    titleCtrls = _LazyCtrlList(widget.testCases, (tc) => tc.title);
    preCtrls = _LazyCtrlList(widget.testCases, (tc) => tc.preconditions.join('\n'));
    stepsCtrls = _LazyCtrlList(widget.testCases, (tc) =>
      tc.steps.asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value.action}').join('\n'));
    dataCtrls = _LazyCtrlList(widget.testCases, (tc) =>
      tc.steps.map((s) => s.data).where((d) => d.isNotEmpty).join('\n'));
    expectedCtrls = _LazyCtrlList(widget.testCases, (tc) => tc.expectedResult);
    actualCtrls = _LazyCtrlList(widget.testCases, (tc) => tc.actualResult);
    statusCtrls = _LazyCtrlList(widget.testCases, (tc) => tc.status);
  }

  void _disposeControllers() {
    idCtrls.dispose();
    titleCtrls.dispose();
    preCtrls.dispose();
    stepsCtrls.dispose();
    dataCtrls.dispose();
    expectedCtrls.dispose();
    actualCtrls.dispose();
    statusCtrls.dispose();
  }

  double get _totalWidth =>
      (widget.selectionMode ? _checkboxWidth : 0) +
      (widget.riskMode ? _riskColumnWidth : 0) +
      colWidths.reduce((a, b) => a + b);

  static const _counterStyle = TextStyle(fontSize: 8, color: Colors.white38, height: 1);

  void _edited(int index) {
    widget.onCellEdit?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _totalWidth,
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const Divider(height: 1, thickness: 1, color: _dividerColor),
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.testCases.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: _dividerColor),
                    itemBuilder: (_, i) => _buildRow(i),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    const baseHeaders = ['ID', 'Title', 'Preconditions', 'Steps', 'Test Data', 'Expected Result', 'Actual Result', 'Status', 'Priority'];
    return Container(
      color: Colors.transparent,
      child: Row(
        children: [
          if (widget.selectionMode)
            SizedBox(
              width: _checkboxWidth,
              child: Center(
                child: Checkbox(
                  value: widget.selectedIndices.length == widget.testCases.length,
                  tristate: widget.selectedIndices.isNotEmpty && widget.selectedIndices.length < widget.testCases.length,
                  onChanged: (v) {
                    final updated = <int>{};
                    if (v == true) {
                      updated.addAll(List.generate(widget.testCases.length, (i) => i));
                    }
                    widget.onSelectionChanged?.call(updated);
                  },
                  fillColor: WidgetStateProperty.resolveWith((_) => AppColors.accent),
                  checkColor: Colors.black,
                  side: const BorderSide(color: AppColors.textHint),
                ),
              ),
            ),
          if (widget.riskMode)
            SizedBox(
              width: _riskColumnWidth,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text('Risk', style: TextStyle(color: _cyanColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ...List.generate(baseHeaders.length, (i) => SizedBox(
            width: colWidths[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(baseHeaders[i], style: const TextStyle(color: _cyanColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          )),
        ],
      ),
    );
  }

  void _toggleSelection(int i) {
    final updated = Set<int>.from(widget.selectedIndices);
    if (updated.contains(i)) {
      updated.remove(i);
    } else {
      updated.add(i);
    }
    widget.onSelectionChanged?.call(updated);
  }

  Widget _buildRow(int i) {
    final tc = widget.testCases[i];
    final isSelected = widget.selectedIndices.contains(i);
    return GestureDetector(
      onLongPress: () {
        if (widget.selectionMode) {
          _toggleSelection(i);
        } else {
          widget.onSelectionChanged?.call({i});
        }
      },
      onTap: () {
        if (widget.selectionMode) _toggleSelection(i);
      },
      child: Container(
        color: isSelected ? AppColors.accent.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.selectionMode)
              SizedBox(
                width: _checkboxWidth,
                child: Center(
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(i),
                    fillColor: WidgetStateProperty.resolveWith((_) => AppColors.accent),
                    checkColor: Colors.black,
                    side: const BorderSide(color: AppColors.textHint),
                  ),
                ),
              ),
            if (widget.riskMode) _riskBadgeCell(i, tc),
            _idCell(i, tc),
            _plainTextCell(titleCtrls[i], colWidths[1], (v) { tc.title = v; _edited(i); }, maxLength: 200),
            _plainTextCell(preCtrls[i], colWidths[2], (v) {
              tc.preconditions = v.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              _edited(i);
            }, maxLength: 1000),
            _stepsCell(i, tc),
            _plainTextCell(dataCtrls[i], colWidths[4], (v) {
              final data = v.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              for (int j = 0; j < tc.steps.length; j++) {
                if (j < data.length) tc.steps[j].data = data[j];
                else tc.steps[j].data = '';
              }
              _edited(i);
            }, maxLength: 500),
            _plainTextCell(expectedCtrls[i], colWidths[5], (v) { tc.expectedResult = v; _edited(i); }, maxLength: 500),
            _plainTextCell(actualCtrls[i], colWidths[6], (v) { tc.actualResult = v; _edited(i); }, maxLength: 500),
            _statusCell(i, tc),
            _priorityCell(i, tc),
          ],
        ),
      ),
    );
  }

  Widget _riskBadgeCell(int i, FinalizedTestCase tc) {
    final score = widget.riskScores?[tc.id] ?? 0;
    final label = RiskScorer.label(score);
    final icon = RiskScorer.icon(score);
    final Color badgeColor;
    switch (RiskScorer.tier(score)) {
      case RiskTier.mustTest: badgeColor = const Color(0xFFB71C1C); break;
      case RiskTier.shouldTest: badgeColor = const Color(0xFFE65100); break;
      case RiskTier.optional: badgeColor = const Color(0xFF2E7D32); break;
    }
    return SizedBox(
      width: _riskColumnWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: badgeColor.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.selectionMode) Text(icon, style: const TextStyle(fontSize: 11)),
              if (!widget.selectionMode) const SizedBox(width: 3),
              Flexible(
                child: Text(label,
                  style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkDuplicate(int i) {
    final id = idCtrls[i].text.trim();
    final isDup = id.isNotEmpty &&
        widget.testCases
            .where((tc) => tc.id == id)
            .length > 1;
    if (isDup) {
      _duplicateIndices.add(i);
    } else {
      _duplicateIndices.remove(i);
    }
    widget.onDuplicateChange?.call(_duplicateIndices.isNotEmpty);
  }

  Widget _idCell(int i, FinalizedTestCase tc) {
    final isDuplicate = _duplicateIndices.contains(i);
    return SizedBox(
      width: colWidths[0],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            widget.isEditable
                ? _EditField(
                    controller: idCtrls[i],
                    maxLength: 50,
                    style: TextStyle(
                      color: isDuplicate ? AppColors.error : _cyanColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      border: isDuplicate
                          ? OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.error),
                            )
                          : null,
                      errorText: isDuplicate ? 'Duplicate' : null,
                    ),
                    onChanged: (v) {
                      tc.id = v;
                      _checkDuplicate(i);
                      _edited(i);
                    },
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(idCtrls[i].text, style: const TextStyle(color: _cyanColor, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
            const SizedBox(height: 4),
            _sourceBadge(tc.source),
          ],
        ),
      ),
    );
  }

  Widget _sourceBadge(CaseSource source) {
    String label;
    Color color;
    switch (source) {
      case CaseSource.ai: label = 'AI'; color = Colors.blue; break;
      case CaseSource.repairedAi: case CaseSource.repaired: label = 'REP'; color = Colors.orange; break;
      case CaseSource.fallback: label = 'FB'; color = Colors.red; break;
      case CaseSource.emergency: label = 'EM'; color = Colors.redAccent; break;
      case CaseSource.imported: label = 'IMP'; color = Colors.purple; break;
      case CaseSource.manual: label = 'MAN'; color = Colors.green; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(label, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _stepsCell(int i, FinalizedTestCase tc) {
    return SizedBox(
      width: colWidths[3],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: widget.isEditable
            ? _EditField(
                controller: stepsCtrls[i],
                maxLength: 2000,
                onChanged: (v) {
                  final lines = v.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  final newSteps = <TestStep>[];
                  for (int k = 0; k < lines.length; k++) {
                    final line = lines[k];
                    final dotIndex = line.indexOf('. ');
                    final action = dotIndex != -1 ? line.substring(dotIndex + 2).trim() : line.trim();
                    newSteps.add(TestStep(
                      action: action,
                      data: k < tc.steps.length ? tc.steps[k].data : '',
                      expected: k < tc.steps.length ? tc.steps[k].expected : '',
                    ));
                  }
                  if (newSteps.isNotEmpty) tc.steps = newSteps;
                  _edited(i);
                },
              )
            : Text(stepsCtrls[i].text, overflow: TextOverflow.ellipsis, maxLines: 5, style: const TextStyle(color: _textSecondary, fontSize: 12)),
      ),
    );
  }

  Widget _plainTextCell(TextEditingController ctrl, double width, Function(String) onChanged, {int? maxLength}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: widget.isEditable
            ? _EditField(
                controller: ctrl,
                maxLength: maxLength,
                onChanged: (v) { onChanged(v); },
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(ctrl.text, overflow: TextOverflow.ellipsis, maxLines: 5, style: const TextStyle(color: _textSecondary, fontSize: 12)),
              ),
      ),
    );
  }

  Widget _statusCell(int i, FinalizedTestCase tc) {
    const options = ['Pass', 'Fail', 'Blocked', 'Not Executed'];
    final displayValue = tc.status.trim().isEmpty ? 'Not Executed' : tc.status;
    return SizedBox(
      width: colWidths[7],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: widget.isEditable
            ? Container(
                color: _fieldBg,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: options.contains(displayValue) ? displayValue : 'Not Executed',
                    dropdownColor: const Color(0xFF1E1E2E),
                    style: const TextStyle(color: _textPrimary, fontSize: 12),
                    isExpanded: true,
                    items: options.map((e) => DropdownMenuItem(value: e, child: _statusPill(e))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() { tc.status = v; });
                      _edited(i);
                    },
                  ),
                ),
              )
            : _statusPill(displayValue),
      ),
    );
  }

  Widget _statusPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: _pillBg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: _textPrimary, fontSize: 12), textAlign: TextAlign.center),
    );
  }

  Widget _priorityCell(int i, FinalizedTestCase tc) {
    const options = ['High', 'Medium', 'Low'];
    final value = PriorityUtils.normalize(tc.priority);
    return SizedBox(
      width: colWidths[8],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: widget.isEditable
            ? Container(
                color: _fieldBg,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: options.contains(value) ? value : 'Medium',
                    dropdownColor: const Color(0xFF1E1E2E),
                    isExpanded: true,
                    items: options.map((e) => DropdownMenuItem(value: e, child: _priorityBadge(e))).toList(),
                    onChanged: (v) {
                      setState(() { tc.priority = v ?? 'Medium'; });
                      _edited(i);
                    },
                  ),
                ),
              )
            : _priorityBadge(value),
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    final Color bg;
    switch (priority.toLowerCase()) {
      case 'high': bg = const Color(0xFFB71C1C); break;
      case 'medium': bg = const Color(0xFFE65100); break;
      case 'low': bg = const Color(0xFF2E7D32); break;
      default: bg = _pillBg;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(priority, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
    );
  }
}

class _EditField extends StatefulWidget {
  final TextEditingController controller;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final TextStyle? style;
  final ValueChanged<String> onChanged;
  final InputDecoration? decoration;

  const _EditField({
    required this.controller,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 3,
    this.style,
    required this.onChanged,
    this.decoration,
  });

  @override
  State<_EditField> createState() => _EditFieldState();
}

class _EditFieldState extends State<_EditField> {
  String _counterText = '';

  @override
  void initState() {
    super.initState();
    _counterText = _computeCounterText();
    widget.controller.addListener(_onCounterUpdate);
  }

  @override
  void didUpdateWidget(_EditField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onCounterUpdate);
      widget.controller.addListener(_onCounterUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCounterUpdate);
    super.dispose();
  }

  void _onCounterUpdate() {
    final t = _computeCounterText();
    if (t != _counterText && mounted) {
      setState(() => _counterText = t);
    }
  }

  String _computeCounterText() {
    if (widget.maxLength == null) return '';
    final len = widget.controller.text.length;
    if (len > (widget.maxLength! * 0.6).ceil()) {
      return '${widget.maxLength! - len}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final custom = widget.decoration;
    return TextField(
      controller: widget.controller,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      style: widget.style ?? const TextStyle(color: _textPrimary, fontSize: 12),
      decoration: InputDecoration(
        filled: true,
        fillColor: _fieldBg,
        border: custom?.border ?? const OutlineInputBorder(),
        errorText: custom?.errorText,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        counterText: _counterText,
        counterStyle: _counterStyle,
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _LazyCtrlList {
  final List<FinalizedTestCase> _testCases;
  final String Function(FinalizedTestCase) _textGetter;
  final Map<int, TextEditingController> _cache = {};

  _LazyCtrlList(this._testCases, this._textGetter);

  TextEditingController operator [](int index) {
    return _cache.putIfAbsent(index, () {
      return TextEditingController(text: _textGetter(_testCases[index]));
    });
  }

  int get length => _testCases.length;

  void dispose() {
    for (final c in _cache.values) c.dispose();
    _cache.clear();
  }
}
