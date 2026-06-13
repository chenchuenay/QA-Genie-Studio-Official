import 'dart:io';
import 'dart:convert';
import 'test_pipeline_observer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qa_genie/core/network/api_client.dart';
import 'package:qa_genie/data/dto/generation_dto.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/app/startup/app_dependencies.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/forensics/pipeline_observer.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/engine/forensics/trace_id_generator.dart';
import 'package:qa_genie/core/utils/finalized_test_case_adapter.dart';
import 'package:qa_genie/engine/orchestration/stages/ai_generation_stage.dart';

class ForensicRunner {
  static bool _initialized = false;
  static final TestPipelineObserver _observer = TestPipelineObserver();

  static Future<void> initialize() async {
    if (_initialized) return;

    PipelineForensics.setObserver(_observer);

    final envFile = File('.env.dev');
    if (envFile.existsSync()) {
      await dotenv.load(fileName: '.env.dev');
    } else {
      print('Warning: .env.dev not found, using default environment');
    }
    AiGenerationStage.useTestCaller((
      String prompt,

      GenerationRequest request,
    ) async {
      return await ApiClient.generate(prompt: prompt);
    });
    _initialized = true;
  }

  static Future<GenerationSession> execute({
    required String module,
    required String feature,
    required String constraints,
    required String platform,
    required bool isPro,
  }) async {
    await initialize();
    _observer.clear();

    final useCase = AppDependencies.generateTestCasesUseCase;
    final dto = GenerationDto(
      module: module,
      feature: feature,
      platform: platform,
      mode: isPro ? GenerationMode.pro : GenerationMode.core,
      count: isPro ? 16 : 8,
      constraints: constraints,
      domain: 'general',
      traceId: TraceIdGenerator.generate(),
    );

    final session = await useCase.execute(dto: dto);
    final report = session.auditReport;
    final tier = isPro ? 'pro' : 'core';

    final baseDir = Directory('test_results/gen_results');
    if (!baseDir.existsSync()) baseDir.createSync(recursive: true);

    final pipelineFile = File('${baseDir.path}/${tier}_pipeline.txt');
    final analyticalFile = File('${baseDir.path}/${tier}_analytical_logs.txt');
    final uaeTime = _toUaeTime(DateTime.now());

    final pipelineLog = StringBuffer();
    pipelineLog.writeln('=== QA GENIE FORENSIC PIPELINE LOG ===');
    pipelineLog.writeln('timestamp: $uaeTime');
    pipelineLog.writeln('mode: $tier');
    pipelineLog.writeln('requested_count: ${isPro ? 16 : 8}');
    pipelineLog.writeln('--- PROMPT ---');
    pipelineLog.writeln(report.prompt ?? 'Not captured');
    pipelineLog.writeln('--- RAW AI RESPONSE ---');
    pipelineLog.writeln(report.rawAiResponse ?? 'Not captured');
    pipelineLog.writeln('--- PROVIDER INFO ---');
    pipelineLog.writeln('model: ${report.aiModel ?? 'gemini-2.5-flash-lite'}');
    pipelineLog.writeln(
      'endpoint: ${report.aiEndpoint ?? 'https://generativelanguage.googleapis.com/v1beta/...'}',
    );
    pipelineLog.writeln('status_code: ${report.aiStatusCode ?? 200}');
    pipelineLog.writeln('latency_ms: ${report.aiLatencyMs ?? 0}');
    pipelineLog.writeln('--- COUNTS ---');
    pipelineLog.writeln('ai_returned: ${report.aiReturnedCount ?? 0}');
    pipelineLog.writeln('ai_accepted: ${report.aiAcceptedCount ?? 0}');
    pipelineLog.writeln(
      'structural_ok: ${(report.aiReturnedCount ?? 0) - (report.structuralRejectedCount ?? 0)}',
    );
    pipelineLog.writeln(
      'semantic_ok: ${(report.aiReturnedCount ?? 0) - (report.structuralRejectedCount ?? 0) - (report.semanticRejectedCount ?? 0)}',
    );
    pipelineLog.writeln(
      'realism_ok: ${(report.aiReturnedCount ?? 0) - (report.structuralRejectedCount ?? 0) - (report.semanticRejectedCount ?? 0) - (report.realismRejectedCount ?? 0)}',
    );
    pipelineLog.writeln(
      'export_ok: ${(report.aiReturnedCount ?? 0) - (report.structuralRejectedCount ?? 0) - (report.semanticRejectedCount ?? 0) - (report.realismRejectedCount ?? 0) - (report.exportSafetyRejectedCount ?? 0)}',
    );
    pipelineLog.writeln('repaired: ${report.repairedCount ?? 0}');
    pipelineLog.writeln('fallback: ${report.fallbackCount ?? 0}');
    pipelineLog.writeln('final: ${session.testCases.length}');
    pipelineLog.writeln('--- FINALIZED TEST CASES ---');
    pipelineLog.writeln(
      jsonEncode(session.testCases.map((c) => _toProductionJson(c)).toList()),
    );
    pipelineLog.writeln('--- REJECTED DETAILS ---');
    for (final rejected in report.rejectedCases) {
      pipelineLog.writeln(
        '${rejected.stage}: ${rejected.title} -> ${rejected.reason}',
      );
    }
    if (report.hasFailures)
      pipelineLog.writeln('--- ERROR ---\nPipeline had failures.');
    await pipelineFile.writeAsString(pipelineLog.toString());

    final analyticalLine =
        '$uaeTime,$tier,${isPro ? 16 : 8},${session.testCases.length},'
        '${report.structuralRejectedCount ?? 0},${report.semanticRejectedCount ?? 0},'
        '${report.realismRejectedCount ?? 0},${report.exportSafetyRejectedCount ?? 0},'
        '${report.repairedCount ?? 0},${report.fallbackCount ?? 0},'
        '${report.averageConfidence},${report.aiLatencyMs ?? 0}\n';
    await analyticalFile.writeAsString(analyticalLine, mode: FileMode.append);

    final jsonList = session.testCases.map((tc) {
      final legacy = FinalizedTestCaseAdapter.toLegacy(tc);
      return legacy.toJson();
    }).toList();
    final casesFile = File('test_results/last_generation.json');
    await casesFile.create(recursive: true);
    await casesFile.writeAsString(jsonEncode(jsonList));

    return session;
  }

  static Future<List<FinalizedTestCase>> loadLastGeneratedCases() async {
    final file = File('test_results/last_generation.json');
    if (!file.existsSync())
      throw Exception(
        'No saved generation. Run generation_pipeline_test.dart first.',
      );
    final jsonString = await file.readAsString();
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((j) {
      final legacy = TestCaseModel.fromJson(j as Map<String, dynamic>);
      return FinalizedTestCaseAdapter.fromLegacy(legacy);
    }).toList();
  }

  static Map<String, dynamic> _toProductionJson(FinalizedTestCase tc) {
    final legacy = FinalizedTestCaseAdapter.toLegacy(tc);
    return legacy.toJson();
  }

  static String _toUaeTime(DateTime dt) {
    final uae = dt.toUtc().add(const Duration(hours: 4));
    final iso = uae.toIso8601String();
    final withoutMillis = iso.split('.').first;
    return '$withoutMillis+04:00';
  }
}


mkdir -p FORENSIC_BAK/lib/features/forensics

git show ai-reintegration:lib/features/forensics/diagnostics_persistence_service.dart \
> FORENSIC_BAK/lib/features/forensics/diagnostics_persistence_service.dart

git show ai-reintegration:lib/features/forensics/production_diagnostics_screen.dart \
> FORENSIC_BAK/lib/features/forensics/production_diagnostics_screen.dart
