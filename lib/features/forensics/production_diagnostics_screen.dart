import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';

class ProductionDiagnosticsScreen extends StatefulWidget {
  const ProductionDiagnosticsScreen({super.key});

  @override
  State<ProductionDiagnosticsScreen> createState() =>
      _ProductionDiagnosticsScreenState();
}

class _ProductionDiagnosticsScreenState
    extends State<ProductionDiagnosticsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final forensicsDir = Directory('${dir.path}/QA_Genie/Forensics');
      final file = File('${forensicsDir.path}/latest_run.json');
      if (!await file.exists()) {
        setState(() {
          _error = 'No forensic data available. Generate a test suite first.';
          _loading = false;
        });
        return;
      }
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);
      setState(() {
        _data = json;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load forensic data: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Production Diagnostics',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _error.isNotEmpty
          ? Center(
              child: Text(
                _error,
                style: const TextStyle(color: AppColors.error),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('ENVIRONMENT CONTEXT'),
                  _infoRow('App Tier', _getString('generation_info.app_tier')),
                  _infoRow('Quota Snapshot', _getString('generation_info.quota_snapshot')),
                  _infoRow('Ad Latency (ms)', _getString('generation_info.ad_load_latency_ms')),
                  _infoRow('Constraints Hash', _getString('generation_info.constraints_hash')),
                  _infoRow('App Version', _getString('generation_info.app_version')),

                  const SizedBox(height: 16),
                  _sectionTitle('GENERATION INFO'),
                  _infoRow('Trace ID', _getString('generation_info.trace_id')),
                  _infoRow(
                    'Timestamp',
                    _getString('generation_info.timestamp'),
                  ),
                  _infoRow('Module', _getString('generation_info.module')),
                  _infoRow('Feature', _getString('generation_info.feature')),
                  _infoRow('Platform', _getString('generation_info.platform')),
                  _infoRow(
                    'Requested Count',
                    _getString('generation_info.requested_count'),
                  ),

                  const SizedBox(height: 16),
                  _sectionTitle('PIPELINE SUMMARY'),
                  _infoRow(
                    'AI Returned',
                    _getString('pipeline_summary.ai_returned'),
                  ),
                  _infoRow(
                    'AI Accepted',
                    _getString('pipeline_summary.ai_accepted'),
                  ),
                  _infoRow(
                    'AI Rejected',
                    _getString('pipeline_summary.ai_rejected'),
                  ),
                  _infoRow(
                    'Fallback Generated',
                    _getString('pipeline_summary.fallback_generated'),
                  ),
                  _infoRow(
                    'Finalized Cases',
                    _getString('pipeline_summary.finalized_cases'),
                  ),

                  const SizedBox(height: 16),
                  _sectionTitle('AI ERROR DETAILS'),
                  _infoRow('Model', _getString('ai_error_details.model_name')),
                  _infoRow('API URL', _getString('ai_error_details.api_url')),
                  _infoRow(
                    'HTTP Status',
                    _getString('ai_error_details.http_status_code'),
                  ),
                  _infoRow(
                    'Error Code',
                    _getString('ai_error_details.error_code'),
                  ),
                  _infoRow(
                    'Error Message',
                    _getString('ai_error_details.error_message'),
                  ),
                  _infoRow(
                    'Network Error Type',
                    _getString('ai_error_details.network_error_type'),
                  ),
                  _infoRow(
                    'Total Retries',
                    _getString('ai_error_details.total_retries'),
                  ),
                  _infoRow(
                    'Malformed Response',
                    _getString('ai_error_details.was_response_malformed'),
                  ),
                  if (_getList('ai_error_details.parser_errors').isNotEmpty)
                    _errorList(
                      'Parser Errors',
                      _getList('ai_error_details.parser_errors'),
                    ),

                  const SizedBox(height: 16),
                  _sectionTitle('CLOUD FUNCTION'),
                  _infoRow('Name', _getString('cloud_function.name')),
                  _infoRow('Region', _getString('cloud_function.region')),
                  _infoRow(
                    'Request ID',
                    _getString('cloud_function.request_id'),
                  ),
                  _infoRow('Version', _getString('cloud_function.version')),
                  _infoRow(
                    'Latency (ms)',
                    _getString('cloud_function.latency_ms'),
                  ),

                  const SizedBox(height: 16),
                  _sectionTitle('AI USAGE'),
                  _infoRow(
                    'Prompt Tokens',
                    _getString('ai_usage.prompt_tokens'),
                  ),
                  _infoRow(
                    'Completion Tokens',
                    _getString('ai_usage.completion_tokens'),
                  ),
                  _infoRow('Total Tokens', _getString('ai_usage.total_tokens')),

                  const SizedBox(height: 16),
                  _sectionTitle('FAILURE REASON'),
                  _infoRow('Reason', _getString('failure_reason')),

                  const SizedBox(height: 16),
                  _sectionTitle('REPAIR LOG (first 5)'),
                  _buildRepairLog(),

                  const SizedBox(height: 16),
                  _sectionTitle('FALLBACK TRIGGERS'),
                  _buildFallbackTriggers(),
                ],
              ),
            ),
    );
  }

  String _getString(String path) {
    final parts = path.split('.');
    dynamic current = _data;
    for (final part in parts) {
      if (current == null) return 'N/A';
      current = current[part];
    }
    return current?.toString() ?? 'N/A';
  }

  List<String> _getList(String path) {
    final parts = path.split('.');
    dynamic current = _data;
    for (final part in parts) {
      if (current == null) return [];
      current = current[part];
    }
    if (current is List) return current.map((e) => e.toString()).toList();
    return [];
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      title,
      style: const TextStyle(
        color: AppColors.accent,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    ),
  );

  Widget _errorList(String title, List<String> errors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(color: AppColors.warning, fontSize: 12),
        ),
        const SizedBox(height: 4),
        ...errors.map(
          (e) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              '• $e',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepairLog() {
    final audit = _data?['full_pipeline_audit'];
    final repairLog = audit?['repairLog'] as List? ?? [];
    if (repairLog.isEmpty)
      return const Text('None', style: TextStyle(color: AppColors.textHint));
    return Column(
      children: repairLog
          .take(5)
          .map<Widget>(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $e',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFallbackTriggers() {
    final audit = _data?['full_pipeline_audit'];
    final triggers = audit?['fallbackTriggers'] as List? ?? [];
    if (triggers.isEmpty)
      return const Text('None', style: TextStyle(color: AppColors.textHint));
    return Column(
      children: triggers
          .map<Widget>(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $e',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
