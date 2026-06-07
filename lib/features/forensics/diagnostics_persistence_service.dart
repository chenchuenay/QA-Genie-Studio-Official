import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/forensics/error_capture_utils.dart';

class DiagnosticsPersistenceService {
  static Future<Directory> _getForensicsDir() async {
    if (Platform.isAndroid) {
      final downloadsDir = Directory(
        '/storage/emulated/0/Download/QA_Genie_Forensics',
      );
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return downloadsDir;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final forensicsDir = Directory('${dir.path}/QA_Genie/Forensics');
      if (!await forensicsDir.exists())
        await forensicsDir.create(recursive: true);
      return forensicsDir;
    }
  }

  static Future<void> saveSnapshot({
    required GenerationSession session,
    required PipelineAuditReport auditReport,
    required String rawAiResponse,
  }) async {
    final dir = await _getForensicsDir();
    final timestamp = DateTime.now();
    final isoString = timestamp.toIso8601String();

    // ----- 1. latest_run.json (overwritten each time) -----
    final latestJson = {
      'generation_info': {
        'trace_id': session.traceId,
        'timestamp': isoString,
        'module': session.testCases.isNotEmpty
            ? session.testCases.first.module
            : '',
        'feature': session.testCases.isNotEmpty
            ? session.testCases.first.feature
            : '',
        'platform': session.testCases.isNotEmpty
            ? session.testCases.first.platform
            : '',
        'requested_count': auditReport.totalInputCases,
      },
      'pipeline_summary': {
        'ai_returned': auditReport.aiReturnedCount,
        'ai_accepted': auditReport.aiAcceptedCount,
        'ai_rejected':
            (auditReport.aiReturnedCount ?? 0) -
            (auditReport.aiAcceptedCount ?? 0),
        'fallback_generated': auditReport.fallbackCount,
        'finalized_cases': auditReport.finalizedCases,
      },
      'ai_error_details': {
        'model_name': auditReport.aiModelName,
        'api_url': auditReport.aiApiUrl,
        'http_status_code': auditReport.aiHttpStatusCode,
        'error_code': auditReport.aiErrorCode,
        'error_message': auditReport.aiErrorMessage,
        'error_details_map': auditReport.aiErrorDetails,
        'network_error_type': auditReport.networkErrorType,
        'total_retries': auditReport.totalRetriesAttempted,
        'was_response_malformed': auditReport.wasResponseMalformed,
        'parser_errors': auditReport.parserErrorMessages,
      },
      'cloud_function': {
        'name': auditReport.cloudFunctionName,
        'region': auditReport.cloudFunctionRegion,
        'request_id': auditReport.cloudRequestId,
        'version': auditReport.cloudFunctionVersion,
        'latency_ms': auditReport.cloudLatencyMs,
      },
      'ai_usage': {
        'prompt_tokens': auditReport.aiPromptTokens,
        'completion_tokens': auditReport.aiCompletionTokens,
        'total_tokens': auditReport.aiTotalTokens,
      },
      'failure_reason': _determineFailureReason(auditReport),
      'raw_ai_response': ErrorCaptureUtils.truncate(rawAiResponse, 10000),
      'full_pipeline_audit': auditReport.toJson(),
      'final_test_cases': session.testCases
          .map(
            (tc) => {'id': tc.id, 'title': tc.title, 'source': tc.source.name},
          )
          .toList(),
    };

    await File(
      '${dir.path}/latest_run.json',
    ).writeAsString(jsonEncode(latestJson));

    // ----- 2. latest_run.log (overwritten each time) -----
    final log = StringBuffer()
      ..writeln('[$isoString] Generation Started (traceId=${session.traceId})')
      ..writeln(
        '[$isoString] Module: ${session.testCases.isNotEmpty ? session.testCases.first.module : '?'}',
      )
      ..writeln(
        '[$isoString] Feature: ${session.testCases.isNotEmpty ? session.testCases.first.feature : '?'}',
      )
      ..writeln(
        '[$isoString] Platform: ${session.testCases.isNotEmpty ? session.testCases.first.platform : '?'}',
      )
      ..writeln(
        '[$isoString] AI Model: ${auditReport.aiModelName ?? 'unknown'}',
      )
      ..writeln('[$isoString] AI API URL: ${auditReport.aiApiUrl ?? 'unknown'}')
      ..writeln(
        '[$isoString] AI HTTP Status: ${auditReport.aiHttpStatusCode ?? 'N/A'}',
      );
    if (auditReport.aiErrorCode != null) {
      log.writeln('[$isoString] AI Error Code: ${auditReport.aiErrorCode}');
      log.writeln('[$isoString] AI Error Msg: ${auditReport.aiErrorMessage}');
    }
    if (auditReport.parserErrorMessages.isNotEmpty) {
      log.writeln(
        '[$isoString] Parser Errors: ${auditReport.parserErrorMessages.join('; ')}',
      );
    }
    log
      ..writeln('[$isoString] AI Returned: ${auditReport.aiReturnedCount}')
      ..writeln('[$isoString] AI Accepted: ${auditReport.aiAcceptedCount}')
      ..writeln(
        '[$isoString] AI Rejected: ${(auditReport.aiReturnedCount ?? 0) - (auditReport.aiAcceptedCount ?? 0)}',
      )
      ..writeln('[$isoString] Repair Modified: ${auditReport.repairedCases}')
      ..writeln('[$isoString] Fallback Generated: ${auditReport.fallbackCount}')
      ..writeln('[$isoString] Finalized: ${auditReport.finalizedCases}')
      ..writeln('[$isoString] Generation Completed');
    await File('${dir.path}/latest_run.log').writeAsString(log.toString());

    debugPrint('📁 FORENSICS saved to ${dir.path}/latest_run.json');
    if (auditReport.aiErrorCode != null) {
      debugPrint(
        '❌ AI ERROR: ${auditReport.aiErrorCode} - ${auditReport.aiErrorMessage}',
      );
    }

    // ----- 3. NEW: full_dump_<timestamp>.json (never overwritten) -----
    final fullDump = _buildFullDump(session, auditReport, rawAiResponse);
    final timestampStr = timestamp.toIso8601String().replaceAll(':', '-');
    final fullDumpFile = File('${dir.path}/full_dump_$timestampStr.json');
    await fullDumpFile.writeAsString(jsonEncode(fullDump));
    debugPrint('📦 FULL DUMP saved to ${fullDumpFile.path}');
  }

  static Map<String, dynamic> _buildFullDump(
    GenerationSession session,
    PipelineAuditReport auditReport,
    String rawAiResponse,
  ) {
    final aiAccepted = auditReport.aiAcceptedCount ?? 0;
    final fallbackGen = auditReport.fallbackCount ?? 0;

    final testCaseDecisions = session.testCases.map((tc) {
      String source = tc.source.name;
      String reason = '';
      if (source == 'ai') {
        reason = 'AI returned valid test case';
      } else if (source == 'fallback') {
        if (aiAccepted == 0 && fallbackGen > 0) {
          reason = 'AI failed or returned zero cases; full fallback generated';
        } else {
          reason =
              'AI returned fewer cases than requested; missing cases filled by fallback generator';
        }
      } else if (source == 'repaired' || source == 'repairedAi') {
        reason =
            'AI‑generated case was repaired due to weak title or missing fields';
      } else {
        reason = 'Unknown source';
      }
      return {
        'id': tc.id,
        'title': tc.title,
        'source': source,
        'reason': reason,
      };
    }).toList();

    // Extract constraints from prompt
    String? constraints;
    if (auditReport.prompt != null &&
        auditReport.prompt!.contains('CONSTRAINTS:')) {
      final parts = auditReport.prompt!.split('CONSTRAINTS:');
      if (parts.length > 1) {
        constraints = parts[1].trim().split('\n').first;
      }
    }

    return {
      'generation_info': {
        'trace_id': session.traceId,
        'timestamp': DateTime.now().toIso8601String(),
        'module': session.testCases.isNotEmpty
            ? session.testCases.first.module
            : '',
        'feature': session.testCases.isNotEmpty
            ? session.testCases.first.feature
            : '',
        'platform': session.testCases.isNotEmpty
            ? session.testCases.first.platform
            : '',
        'requested_count': auditReport.totalInputCases,
        'mode': session.testCases.isNotEmpty
            ? (session.testCases.length > 8 ? 'PRO' : 'CORE')
            : 'UNKNOWN',
        'constraints': constraints,
      },
      'pipeline_decisions': {
        'ai_returned_count': auditReport.aiReturnedCount,
        'ai_accepted_count': aiAccepted,
        'ai_rejected_count': (auditReport.aiReturnedCount ?? 0) - aiAccepted,
        'repair_modified_count': auditReport.repairedCases,
        'fallback_generated_count': fallbackGen,
        'finalized_count': auditReport.finalizedCases,
        'test_case_decisions': testCaseDecisions,
        'fallback_triggers': auditReport.fallbackTriggers,
        'repair_log': auditReport.repairLog,
        'validation_rejects': auditReport.rejectedCases
            .map(
              (r) => {'title': r.title, 'reason': r.reason, 'stage': r.stage},
            )
            .toList(),
      },
      'inputs': {
        'prompt': auditReport.prompt,
        'raw_ai_response': rawAiResponse.isNotEmpty
            ? ErrorCaptureUtils.truncate(rawAiResponse, 5000)
            : null,
      },
      'outputs': {
        'final_test_cases': session.testCases
            .map(
              (tc) => {
                'id': tc.id,
                'title': tc.title,
                'preconditions': tc.preconditions,
                'testData': tc.testData,
                'steps': tc.steps
                    .map(
                      (s) => {
                        'action': s.action,
                        'data': s.data,
                        'expected': s.expected,
                      },
                    )
                    .toList(),
                'expectedResult': tc.expectedResult,
                'actualResult': tc.actualResult,
                'status': tc.status,
                'priority': tc.priority,
                'type': tc.type,
                'module': tc.module,
                'feature': tc.feature,
                'platform': tc.platform,
                'source': tc.source.name,
              },
            )
            .toList(),
      },
      'metadata': {
        'ai_latency_ms': auditReport.aiLatencyMs,
        'ai_status_code': auditReport.aiStatusCode,
        'ai_model': auditReport.aiModelName,
        'ai_error': auditReport.aiErrorCode,
        'cloud_function_latency_ms': auditReport.cloudLatencyMs,
        'total_duration_ms': auditReport.aiLatencyMs,
      },
    };
  }

  static String _determineFailureReason(PipelineAuditReport auditReport) {
    if (auditReport.aiErrorCode != null) return auditReport.aiErrorCode!;
    if (auditReport.aiHttpStatusCode == 429) return 'RATE_LIMIT';
    if (auditReport.aiHttpStatusCode == 503) return 'TIMEOUT';
    if ((auditReport.aiReturnedCount ?? 0) == 0) return 'EMPTY_RESPONSE';
    if (auditReport.wasResponseMalformed == true) return 'MALFORMED_RESPONSE';
    return 'UNKNOWN';
  }
}
