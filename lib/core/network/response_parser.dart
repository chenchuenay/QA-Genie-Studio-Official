import 'dart:convert';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/data/models/test_case_model.dart';

class ResponseParser {
  static List<TestCaseModel> parseArray(String cleaned) {
    final normalized = cleaned.trim();

    // =====================================================

    // HARD RESPONSE VALIDATION

    // =====================================================

    if (normalized.isEmpty) {
      throw Exception('AI response is empty');
    }

    if (normalized.length < 20) {
      throw Exception('AI response too short');
    }

    if (!normalized.startsWith('[')) {
      throw Exception('Invalid AI JSON array response');
    }

    dynamic decoded;

    String repaired = normalized;

    // Fix JS-style repeat()
    repaired = repaired.replaceAllMapped(
      RegExp(r'"([^"]*)"\.repeat\((\d+)\)'),
      (m) {
        final text = m.group(1)!;
        final count = int.tryParse(m.group(2)!) ?? 1;
        return jsonEncode(text * count);
      },
    );
    try {
      decoded = jsonDecode(normalized);
    } catch (e) {
      print('FAILED JSON:');
      print(repaired);
      throw Exception('Invalid JSON format: $e');
    }

    if (decoded is! List) {
      throw Exception('Root JSON is not a List');
    }

    if (decoded.isEmpty) {
      throw Exception('Parsed JSON array is empty');
    }

    if (decoded.length > 200) {
      throw Exception('AI response too large');
    }

    final parsedCases = <TestCaseModel>[];

    final seenTitles = <String>{};

    final seenIntentHashes = <String>{};

    for (final item in decoded) {
      try {
        // =====================================================

        // SAFE MAP VALIDATION

        // =====================================================

        if (item is! Map<String, dynamic>) {
          continue;
        }

        final map = Map<String, dynamic>.from(item);

        map['source'] = CaseSource.ai.name;

        // =====================================================

        // NORMALIZE ARRAYS

        // =====================================================

        if (map['steps'] is! List) {
          map['steps'] = [];
        }

        if (map['preconditions'] is! List) {
          map['preconditions'] = [];
        }
        // =====================================================

        // NORMALIZE SCALARS

        // =====================================================

        map['id'] ??= '';

        map['module'] ??= '';

        map['feature'] ??= '';

        map['platform'] ??= '';

        map['priority'] ??= 'Medium';

        map['type'] ??= 'Functional';

        map['expectedResult'] ??= '';

        map['actualResult'] ??= '';

        map['status'] ??= 'Not Executed';

        // =====================================================

        // TITLE VALIDATION

        // =====================================================

        final title = (map['title'] ?? '').toString().trim();

        if (title.isEmpty) {
          continue;
        }

        if (title.length < 5) {
          continue;
        }







        // =====================================================

        // NORMALIZED TITLE DEDUP

        // =====================================================

        final normalizedTitle = title
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
            .trim();

        if (seenTitles.contains(normalizedTitle)) {
          continue;
        }

        // =====================================================

        // MODEL CONVERSION

        // =====================================================

        final tc = TestCaseModel.fromJson(map);

        // =====================================================

        // SAFE FIRST ACTION EXTRACTION

        // =====================================================

        final extractedAction = tc.steps.isNotEmpty
            ? tc.steps.first.action
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
                  .trim()
            : '';

        final firstAction = extractedAction.isEmpty
            ? normalizedTitle
            : extractedAction;

        // =====================================================

        // INTENT HASH DEDUP

        // =====================================================

        final intentHash = '$normalizedTitle|$firstAction';

        if (seenIntentHashes.contains(intentHash)) {
          continue;
        }

        

        // =====================================================

        // AUTO STEP RECOVERY

        // =====================================================

        while (tc.steps.length < 3) {
          tc.steps.add(
            TestStep(
              action: 'Validate application response state',
              data: '',
              expected:
                  'Application responds correctly and maintains stable behavior',
            ),
          );
        }

        // =====================================================

        // AUTO STEP FIELD RECOVERY

        // =====================================================

        for (final step in tc.steps) {
          if (step.action.trim().isEmpty) {
            step.action = 'Perform workflow action';
          }

          if (step.expected.trim().isEmpty) {
            step.expected =
                'Application responds correctly and maintains stable behavior';
          }
        }

        // =====================================================

        // AUTO EXPECTED RESULT RECOVERY

        // =====================================================

        if (tc.expectedResult.trim().isEmpty) {
          tc.expectedResult =
              'Application processes the workflow correctly and maintains stable behavior';
        }

        // =====================================================

        // AUTO PRECONDITION RECOVERY

        // =====================================================

        if (tc.preconditions.isEmpty) {
          tc.preconditions = ['Application is accessible and stable'];
        }

        // =====================================================

        // PRIORITY RECOVERY

        // =====================================================

        final normalizedPriority = tc.priority.trim().toLowerCase();

        switch (normalizedPriority) {
          case 'high':
            tc.priority = 'High';
            break;
          case 'low':
            tc.priority = 'Low';
            break;
          default:
            tc.priority = 'Medium';
        }

        // =====================================================

        // FINAL VALIDATION

        // =====================================================

        if (!TestCaseModel.isValid(tc)) {
          continue;
        }
        seenTitles.add(normalizedTitle);
        seenIntentHashes.add(intentHash);

        parsedCases.add(tc);
      } 
      catch (e, st) {
        print('PARSE ITEM FAILURE: $e');
        print(st);
        continue;
      }


    }

    // =====================================================

    // FINAL OUTPUT VALIDATION

    // =====================================================

    if (parsedCases.isEmpty) {
      throw Exception('All parsed testcases were invalid');
    }

    return parsedCases;
  }
}
