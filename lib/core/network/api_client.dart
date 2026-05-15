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

    final cleaned = ResponseCleaner.clean(rawText, providerName);

    PipelineDebugStore.lastCleanedResponse = cleaned;

    final parsedCases = ResponseParser.parseArray(cleaned);

    return parsedCases;
  }
}
