import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qa_genie/engine/generation_service.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  group('Live Mass Generation Stress Tests', () {
    test('Generation respects hard case counts and updates pro forensics', () async {
      final service = GenerationService();
      
      for (final tier in ['core', 'pro']) {
        final maxCases = tier == 'pro' ? 16 : 8;
        final result = await service.execute(
          module: 'auth',
          feature: 'login',
          platform: 'Web',
          maxCases: maxCases,
        );
        
        expect(result.cases.length, equals(maxCases), 
          reason: 'Generation for $tier failed to respect hard count $maxCases');

        // Verify forensic artifact creation for this tier
        final pipelineFile = File('cache/test_results/${tier}_pipeline.txt');
        final analyticalFile = File('cache/test_results/${tier}_analytical_logs.txt');
        
        expect(pipelineFile.existsSync(), isTrue);
        expect(analyticalFile.existsSync(), isTrue);
        
        final analyticalContent = analyticalFile.readAsStringSync();
        expect(analyticalContent.contains('realismScore:'), isTrue);
        expect(analyticalContent.contains('lineage:'), isTrue);
      }
    });
  });
}
