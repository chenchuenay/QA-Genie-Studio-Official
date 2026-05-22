import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/constants.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/core/utils/priority_utils.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/core/database/database_service.dart';

class MasterTable extends StatefulWidget {
  final List<TestCaseModel> testCases;
  final List<TestCaseModel> originalData;
  final bool isEditable;
  final VoidCallback? onCellEdit;
  final int? suiteId;
  final Future<List<Map<String, dynamic>>> Function()? getOtherSuites;

  const MasterTable({
    super.key,
    required this.testCases,
    required this.originalData,
    required this.isEditable,
    this.onCellEdit,
    this.suiteId,
    this.getOtherSuites,
  });

  @override
  State<MasterTable> createState() => _MasterTableState();
}

class _MasterTableState extends State<MasterTable> {
  late List<TextEditingController> idCtrls,
      titleCtrls,
      preCtrls,
      stepsCtrls,
      dataCtrls,
      expectedCtrls,
      actualCtrls,
      statusCtrls;
  final List<double> colWidths = [85, 150, 170, 180, 140, 180, 140, 110, 90];
  static const _cyanColor = Color(0xFF00D4FF);
  static const _dividerColor = Color(0xFF2A2A3A);
  static const _textPrimary = Colors.white;
  static const _textSecondary = Color(0xFFCCCCCC);
  static const _pillBg = Color(0xFF2A2A3A);
  static const _fieldBg = Color(0xFF1A1A2E);
  static const _fieldBorder = Color(0xFF00D4FF);

  BoxDecoration get _fieldDecoration => BoxDecoration(
    color: _fieldBg,
    borderRadius: BorderRadius.circular(8),
    border: Border(
      bottom: BorderSide(color: _fieldBorder.withOpacity(0.45), width: 1.2),
    ),
  );
  @override
  void initState() {
    super.initState();
    print('MASTER TABLE RUNTIME COUNT: ${widget.testCases.length}');
    _initControllers();
  }

  void _initControllers() {
    for (final tc in widget.testCases) {
      tc.priority = PriorityUtils.normalize(tc.priority);
    }
    idCtrls = widget.testCases
        .map((e) => TextEditingController(text: e.id))
        .toList();
    titleCtrls = widget.testCases
        .map((e) => TextEditingController(text: e.title))
        .toList();
    preCtrls = widget.testCases
        .map((e) => TextEditingController(text: e.preconditions.join('\n')))
        .toList();
    stepsCtrls = widget.testCases
        .map(
          (e) => TextEditingController(
            text: e.steps
                .asMap()
                .entries
                .map((entry) => "${entry.key + 1}. ${entry.value.action}")
                .join('\n'),
          ),
        )
        .toList();
    dataCtrls = widget.testCases
        .map(
          (e) => TextEditingController(
            text: e.steps
                .map((s) => s.data)
                .where((d) => d.isNotEmpty)
                .join('\n'),
          ),
        )
        .toList();
    expectedCtrls = widget.testCases
        .map((e) => TextEditingController(text: e.expectedResult))
        .toList();
    actualCtrls = widget.testCases
        .map((e) => TextEditingController(text: e.actualResult))
        .toList();
    statusCtrls = widget.testCases
        .map((e) => TextEditingController(text: e.status))
        .toList();
  }

  void _disposeControllers() {
    for (final c in [
      ...idCtrls,
      ...titleCtrls,
      ...preCtrls,
      ...stepsCtrls,
      ...dataCtrls,
      ...expectedCtrls,
      ...actualCtrls,
      ...statusCtrls,
    ]) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  double get _totalWidth => colWidths.reduce((a, b) => a + b);
  void _editted() => widget.onCellEdit?.call();

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
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: _dividerColor,
                    ),
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
    const headers = [
      'ID',
      'Title',
      'Preconditions',
      'Steps',
      'Test Data',
      'Expected Result',
      'Actual Result',
      'Status',
      'Priority',
    ];
    return Container(
      color: Colors.transparent,
      child: Row(
        children: List.generate(
          headers.length,
          (i) => SizedBox(
            width: colWidths[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                headers[i],
                style: const TextStyle(
                  color: _cyanColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(int i) {
    final tc = widget.testCases[i];
    return GestureDetector(
      onLongPress: () => _showContextMenu(i),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _idCell(i, tc),
            _plainTextCell(titleCtrls[i], colWidths[1], (v) => tc.title = v),
            _plainTextCell(preCtrls[i], colWidths[2], (v) {
              tc.preconditions = v
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }),
            _stepsCell(i, tc),
            _plainTextCell(dataCtrls[i], colWidths[4], (v) {
              final data = v
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              for (int j = 0; j < tc.steps.length; j++) {
                tc.steps[j].data = j < data.length ? data[j] : '';
              }
            }),
            _plainTextCell(
              expectedCtrls[i],
              colWidths[5],
              (v) => tc.expectedResult = v,
            ),
            _plainTextCell(
              actualCtrls[i],
              colWidths[6],
              (v) => tc.actualResult = v,
            ),
            _statusCell(tc),
            _priorityCell(tc),
          ],
        ),
      ),
    );
  }

  Widget _idCell(int i, TestCaseModel tc) {
    return SizedBox(
      width: colWidths[0],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            widget.isEditable
                ? Container(
                    decoration: _fieldDecoration,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: TextField(
                      controller: idCtrls[i],
                      style: const TextStyle(
                        color: _cyanColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) {
                        tc.id = v;
                        _editted();
                      },
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      idCtrls[i].text,
                      style: const TextStyle(
                        color: _cyanColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            const SizedBox(height: 4),
            _sourceBadge(tc.source),
          ],
        ),
      ),
    );
  }

  Widget _sourceBadge(CaseSource source) {
    String label = 'UNK';
    Color color = Colors.grey;
    switch (source) {
      case CaseSource.ai:
        label = 'AI';
        color = Colors.blue;
        break;
      case CaseSource.repairedAi:
        label = 'REP';
        color = Colors.orange;
        break;
      case CaseSource.fallback:
        label = 'FB';
        color = Colors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _stepsCell(int i, TestCaseModel tc) {
    return SizedBox(
      width: colWidths[3],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: widget.isEditable
            ? Container(
                decoration: _fieldDecoration,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: TextField(
                  controller: stepsCtrls[i],
                  maxLines: null,
                  style: const TextStyle(color: _textPrimary, fontSize: 12),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) {
                    final lines = v
                        .split('\n')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    final newSteps = <TestStep>[];
                    for (int k = 0; k < lines.length; k++) {
                      final line = lines[k];
                      final dotIndex = line.indexOf('. ');
                      final action = dotIndex != -1
                          ? line.substring(dotIndex + 2).trim()
                          : line.trim();
                      newSteps.add(
                        TestStep(
                          action: action,
                          data: k < tc.steps.length ? tc.steps[k].data : '',
                          expected: k < tc.steps.length
                              ? tc.steps[k].expected
                              : '',
                        ),
                      );
                    }
                    if (newSteps.isNotEmpty) tc.steps = newSteps;
                    _editted();
                  },
                ),
              )
            : Text(
                stepsCtrls[i].text,
                style: const TextStyle(color: _textSecondary, fontSize: 12),
              ),
      ),
    );
  }

  Widget _plainTextCell(
    TextEditingController ctrl,
    double w,
    Function(String) onChanged,
  ) {
    return SizedBox(
      width: w,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: widget.isEditable
            ? Container(
                decoration: _fieldDecoration,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: TextField(
                  controller: ctrl,
                  maxLines: null,
                  style: const TextStyle(color: _textPrimary, fontSize: 12),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) {
                    onChanged(v);
                    _editted();
                  },
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  ctrl.text,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ),
      ),
    );
  }

  Widget _statusCell(TestCaseModel tc) {
    const options = ['Pass', 'Fail', 'Blocked', 'Not Executed'];
    final displayValue = tc.status.isEmpty ? '—' : tc.status;
    return SizedBox(
      width: colWidths[7],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: widget.isEditable
            ? Container(
                decoration: _fieldDecoration,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: options.toSet().contains(displayValue)
                        ? displayValue
                        : options.first,
                    dropdownColor: const Color(0xFF1E1E2E),
                    style: const TextStyle(color: _textPrimary, fontSize: 12),
                    isExpanded: true,
                    items: options
                        .toSet()
                        .toList()
                        .map(
                          (e) => DropdownMenuItem<String?>(
                            value: e,
                            child: _statusPill(e),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => tc.status = v);
                      _editted();
                    },
                  ),
                ),
              )
            : _statusPill(displayValue),
      ),
    );
  }

  Widget _statusPill(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: _pillBg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(color: _textPrimary, fontSize: 12),
      textAlign: TextAlign.center,
    ),
  );

  Widget _priorityCell(TestCaseModel tc) {
    const options = ['High', 'Medium', 'Low'];
    return SizedBox(
      width: colWidths[8],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: widget.isEditable
            ? Container(
                decoration: _fieldDecoration,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: options.contains(tc.priority) ? tc.priority : 'High',
                    dropdownColor: const Color(0xFF1E1E2E),
                    isExpanded: true,
                    items: options
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: _priorityBadge(e),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() => tc.priority = v ?? 'High');
                      _editted();
                    },
                  ),
                ),
              )
            : _priorityBadge(tc.priority.isEmpty ? 'High' : tc.priority),
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    final Color bg;
    switch (priority.toLowerCase()) {
      case 'high':
        bg = const Color(0xFFB71C1C);
        break;
      case 'medium':
        bg = const Color(0xFFE65100);
        break;
      case 'low':
        bg = const Color(0xFF2E7D32);
        break;
      default:
        bg = _pillBg;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showContextMenu(int index) async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + 20,
        offset.dy + 40,
        offset.dx + 200,
        offset.dy + 200,
      ),
      color: const Color(0xFF2C2C3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        const PopupMenuItem(
          value: 'copy',
          child: Center(
            child: Text('Copy', style: TextStyle(color: Colors.white)),
          ),
        ),
        const PopupMenuItem(
          value: 'move',
          child: Center(
            child: Text('Move', style: TextStyle(color: Colors.white)),
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Center(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
    if (result == null) return;
    final tc = widget.testCases[index];
    if (result == 'copy') {
      final newTc = tc.copy();
      newTc.id = '${tc.id}_copy';
      if (widget.getOtherSuites != null) {
        final suites = await widget.getOtherSuites!();
        final targetSuiteId = await showDialog<int>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                "Copy to Suite",
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: suites.length,
                  itemBuilder: (_, i) {
                    final s = suites[i];
                    final sid = s['id'] as int;
                    return ListTile(
                      title: Text(
                        "${s['moduleName']} · ${s['feature']}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () => Navigator.pop(ctx, sid),
                    );
                  },
                ),
              ),
            );
          },
        );
        if (targetSuiteId != null) {
          await DatabaseService.insertTestCases(targetSuiteId, [newTc]);
        }
      } else if (widget.suiteId != null) {
        // fallback: copy inside same suite if no other suites available
        await DatabaseService.insertTestCases(widget.suiteId!, [newTc]);
        setState(() {
          widget.testCases.insert(index + 1, newTc);
          _initControllers();
        });
      }
    } else if (result == 'move') {
      if (widget.getOtherSuites != null) {
        final suites = await widget.getOtherSuites!();
        final targetSuiteId = await showDialog<int>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                "Move to Suite",
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: suites.length,
                  itemBuilder: (_, i) {
                    final s = suites[i];
                    final sid = s['id'] as int;
                    if (sid == widget.suiteId) return const SizedBox.shrink();
                    return ListTile(
                      title: Text(
                        "${s['moduleName']} · ${s['feature']}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () => Navigator.pop(ctx, sid),
                    );
                  },
                ),
              ),
            );
          },
        );
        if (targetSuiteId != null) {
          await DatabaseService.insertTestCases(targetSuiteId, [tc]);
          if (tc.dbId != null) {
            await DatabaseService.deleteTestCase(tc.dbId!);
          }
          setState(() {
            widget.testCases.removeAt(index);
            _initControllers();
          });
        }
      }
    } else if (result == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            "Delete Test Case?",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Delete '${tc.title}'?",
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        if (tc.dbId != null) {
          await DatabaseService.deleteTestCase(tc.dbId!);
        }
        setState(() {
          widget.testCases.removeAt(index);
          _initControllers();
        });
      }
    }
  }
}
