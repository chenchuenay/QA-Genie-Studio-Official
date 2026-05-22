import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

class AnalyticalFormatter {
  static String buildAnalyticalDump(List<TestCaseModel> cases) {
    final b = StringBuffer();
    
    final ai = cases.where((c) => c.source == CaseSource.ai).length;
    final repaired = cases.where((c) => c.source == CaseSource.repairedAi).length;
    final fallback = cases.where((c) => c.source == CaseSource.fallback).length;

    b.writeln('[SESSION]');
    b.writeln('timestamp=${DateTime.now().toUtc().toIso8601String()}');
    b.writeln('status=success');
    b.writeln('total=${cases.length}');
    b.writeln();

    b.writeln('[PIPELINE]');
    b.writeln('ai_cases=$ai');
    b.writeln('repaired_cases=$repaired');
    b.writeln('fallback_cases=$fallback');
    b.writeln();

    b.writeln('[PRIORITIES]');
    final high = cases.where((c) => c.priority == 'High').length;
    final medium = cases.where((c) => c.priority == 'Medium').length;
    final low = cases.where((c) => c.priority == 'Low').length;
    b.writeln('high=$high');
    b.writeln('medium=$medium');
    b.writeln('low=$low');
    b.writeln();

    return b.toString();
  }
}
