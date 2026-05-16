import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/core/network/response_parser.dart';
import 'package:qa_genie/core/network/response_cleaner.dart';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';
import 'package:qa_genie/core/network/providers/ai_provider.dart';
import 'package:qa_genie/core/network/providers/provider_factory.dart';

class ApiClient {
  final AiProvider _provider = ProviderFactory.create();

  Future<List<TestCaseModel>> generate(String prompt) async {
    final rawText = await _provider.generate(prompt);

    PipelineDebugStore.lastRawResponse = rawText;

    final providerName = _provider.runtimeType
        .toString()
        .replaceAll('Provider', '')
        .toLowerCase();

    PipelineDebugStore.lastProvider = providerName;

    late final String cleaned;
    try {
      cleaned = ResponseCleaner.clean(rawText, providerName);
    } catch (e) {
      PipelineDebugStore.lastCleanedResponse = '[CLEAN_FAILED] $e';
      rethrow;
    }

    PipelineDebugStore.lastCleanedResponse = cleaned;

    try {
      final parsedCases = ResponseParser.parseArray(cleaned);

      print(
        '[QA Genie Parser salvage] recoveredObjects=${PipelineDebugStore.recoveredObjectCount} '
        'rejectedChunks=${PipelineDebugStore.rejectedObjectCount} '
        'malformedSkipped=${PipelineDebugStore.malformedObjectsSkipped} '
        'partialRecovery=${PipelineDebugStore.partialRecoveryUsed} '
        'cleanerRepairCount=${PipelineDebugStore.cleanerRepairCount}',
      );

      return parsedCases;
    } catch (e) {
      PipelineDebugStore.lastCleanedResponse = cleaned;
      rethrow;
    }
  }
}
