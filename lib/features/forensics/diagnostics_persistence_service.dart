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
    final timestamp = DateTime.now().toIso8601String();

    final jsonData = {
      'generation_info': {
        'trace_id': session.traceId,
        'timestamp': timestamp,
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
    ).writeAsString(jsonEncode(jsonData));

    final log = StringBuffer()
      ..writeln('[$timestamp] Generation Started (traceId=${session.traceId})')
      ..writeln(
        '[$timestamp] Module: ${session.testCases.isNotEmpty ? session.testCases.first.module : '?'}',
      )
      ..writeln(
        '[$timestamp] Feature: ${session.testCases.isNotEmpty ? session.testCases.first.feature : '?'}',
      )
      ..writeln(
        '[$timestamp] Platform: ${session.testCases.isNotEmpty ? session.testCases.first.platform : '?'}',
      )
      ..writeln(
        '[$timestamp] AI Model: ${auditReport.aiModelName ?? 'unknown'}',
      )
      ..writeln('[$timestamp] AI API URL: ${auditReport.aiApiUrl ?? 'unknown'}')
      ..writeln(
        '[$timestamp] AI HTTP Status: ${auditReport.aiHttpStatusCode ?? 'N/A'}',
      );
    if (auditReport.aiErrorCode != null) {
      log.writeln('[$timestamp] AI Error Code: ${auditReport.aiErrorCode}');
      log.writeln('[$timestamp] AI Error Msg: ${auditReport.aiErrorMessage}');
    }
    if (auditReport.parserErrorMessages.isNotEmpty) {
      log.writeln(
        '[$timestamp] Parser Errors: ${auditReport.parserErrorMessages.join('; ')}',
      );
    }
    log
      ..writeln('[$timestamp] AI Returned: ${auditReport.aiReturnedCount}')
      ..writeln('[$timestamp] AI Accepted: ${auditReport.aiAcceptedCount}')
      ..writeln(
        '[$timestamp] AI Rejected: ${(auditReport.aiReturnedCount ?? 0) - (auditReport.aiAcceptedCount ?? 0)}',
      )
      ..writeln('[$timestamp] Repair Modified: ${auditReport.repairedCases}')
      ..writeln('[$timestamp] Fallback Generated: ${auditReport.fallbackCount}')
      ..writeln('[$timestamp] Finalized: ${auditReport.finalizedCases}')
      ..writeln('[$timestamp] Generation Completed');
    await File('${dir.path}/latest_run.log').writeAsString(log.toString());

    debugPrint('📁 FORENSICS saved to ${dir.path}/latest_run.json');
    if (auditReport.aiErrorCode != null) {
      debugPrint(
        '❌ AI ERROR: ${auditReport.aiErrorCode} - ${auditReport.aiErrorMessage}',
      );
    }
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
