import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_text.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/theme/app_radius.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/features/summary/ui/summary_report_preview_screen.dart';
import 'package:qa_genie/app/startup/app_dependencies.dart';

class SummaryReportScreen extends StatefulWidget {
  final GenerationSession session;
  final String moduleName;
  final String feature;
  final String platform;
  final int? suiteId;

  const SummaryReportScreen({
    super.key,
    required this.session,
    required this.moduleName,
    required this.feature,
    required this.platform,
    this.suiteId,
  });

  @override
  State<SummaryReportScreen> createState() => _SummaryReportScreenState();
}

class _SummaryReportScreenState extends State<SummaryReportScreen> {
  final _testerCtrl = TextEditingController(text: 'QA Tester');
  final _envCtrl = TextEditingController(text: 'Staging');
  bool _editing = false;
  int _total = 0;
  int _passed = 0;
  int _failed = 0;
  int _blocked = 0;
  String _passRate = '0.0';

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  @override
  void dispose() {
    _testerCtrl.dispose();
    _envCtrl.dispose();
    super.dispose();
  }

  void _recompute() {
    _total = widget.session.testCases.length;
    _passed =
        widget.session.testCases.where((c) => c.status == 'Pass').length;
    _failed =
        widget.session.testCases.where((c) => c.status == 'Fail').length;
    _blocked =
        widget.session.testCases.where((c) => c.status == 'Blocked').length;
    final executed = _passed + _failed + _blocked;
    _passRate = executed == 0
        ? '0.0'
        : (_passed / executed * 100).toStringAsFixed(1);
  }

  String get _tester => _testerCtrl.text.trim();
  String get _environment => _envCtrl.text.trim();

  void _toggleEdit() => setState(() => _editing = !_editing);

  Future<void> _saveStatus() async {
    if (widget.suiteId == null) return;
    try {
      await AppDependencies.saveSuiteUseCase.saveSuite(
        suiteId: widget.suiteId!,
        cases: widget.session.testCases,
      );
    } catch (_) {}
  }

  void _navigateToPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryReportPreviewScreen(
          session: widget.session,
          moduleName: widget.moduleName,
          feature: widget.feature,
          platform: widget.platform,
          testerName: _tester,
          environment: _environment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Summary Report',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: _editing ? 'Done' : 'Edit',
            onPressed: _toggleEdit,
            icon: Icon(
              _editing ? Icons.visibility : Icons.edit,
              color: AppColors.accentLight,
              size: 22,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.moduleName} · ${widget.feature}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.platform} · ${widget.session.testCases.length} cases',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildField('Tester Name', 'e.g. John Doe', _testerCtrl),
                  const SizedBox(height: 12),
                  _buildField(
                    'Environment',
                    'e.g. Staging / iOS 17 / Chrome',
                    _envCtrl,
                  ),
                  const SizedBox(height: 24),
                  _buildStatRow(),
                  const SizedBox(height: 16),
                  _buildPassRateBar(),
                  const SizedBox(height: 24),
                  const Text(
                    'Priority Breakdown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPriorityBreakdown(),
                  const SizedBox(height: 24),
                  const Text(
                    'Detailed Results',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailedTable(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _editing ? null : _navigateToPreview,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
                  label: const Text(
                    'Export Summary Report',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _editing
                        ? AppColors.textHint
                        : AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      readOnly: !_editing,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintText: hint,
        hintStyle: AppText.hint,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildStatRow() {
    return Row(
      children: [
        _statCard('Total', _total, AppColors.accent),
        _statCard('Passed', _passed, AppColors.success),
        _statCard('Failed', _failed, AppColors.error),
        _statCard('Blocked', _blocked, AppColors.warning),
      ].map((e) => Expanded(child: e)).toList(),
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassRateBar() {
    final executed = _passed + _failed + _blocked;
    final rate = executed > 0 ? _passed / executed : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pass Rate',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            Text(
              '$_passRate%',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 8,
            backgroundColor: AppColors.card,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBreakdown() {
    final cases = widget.session.testCases;
    return Column(
      children: [
        _priorityRow(
          'High',
          AppColors.error,
          cases.where((c) => c.priority == 'High'),
        ),
        _priorityRow(
          'Medium',
          AppColors.warning,
          cases.where((c) => c.priority == 'Medium'),
        ),
        _priorityRow(
          'Low',
          AppColors.success,
          cases.where((c) => c.priority == 'Low'),
        ),
      ],
    );
  }

  Widget _priorityRow(
    String label,
    Color color,
    Iterable<FinalizedTestCase> cases,
  ) {
    final p = cases.where((c) => c.status == 'Pass').length;
    final f = cases.where((c) => c.status == 'Fail').length;
    final b = cases.where((c) => c.status == 'Blocked').length;
    final n = cases
        .where((c) => c.status == 'Not Executed' || c.status.isEmpty)
        .length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ${cases.length} cases ($p Passed, $f Failed, $b Blocked, $n Not Executed)',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedTable() {
    return Column(
      children: widget.session.testCases.map((tc) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  tc.id,
                  style: const TextStyle(
                    color: AppColors.accentLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  tc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              Expanded(flex: 1, child: _priorityBadge(tc.priority)),
              const SizedBox(width: 6),
              Expanded(
                flex: 1,
                child: _editing ? _statusDropdown(tc) : _statusText(tc.status),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _priorityBadge(String p) {
    Color bg;
    switch (p) {
      case 'High':
        bg = const Color(0xFFB71C1C);
        break;
      case 'Medium':
        bg = const Color(0xFFE65100);
        break;
      case 'Low':
        bg = const Color(0xFF2E7D32);
        break;
      default:
        bg = AppColors.card;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        p,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statusText(String s) {
    late final Color c;
    switch (s) {
      case 'Pass':
        c = AppColors.success;
        break;
      case 'Fail':
        c = AppColors.error;
        break;
      case 'Blocked':
        c = AppColors.warning;
        break;
      default:
        c = AppColors.textHint;
    }
    return Text(
      s.isEmpty ? 'Not Executed' : s,
      style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w500),
    );
  }

  Widget _statusDropdown(FinalizedTestCase tc) {
    const options = ['Pass', 'Fail', 'Blocked', 'Not Executed'];
    final currentValue = options.contains(tc.status)
        ? tc.status
        : 'Not Executed';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          bottom: BorderSide(
            color: AppColors.accent.withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 11),
          dropdownColor: AppColors.card,
          items: options
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 11)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              tc.status = v;
              _recompute();
            });
            _saveStatus();
          },
        ),
      ),
    );
  }
}
