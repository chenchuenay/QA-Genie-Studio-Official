import 'package:qa_genie/domain/entities/test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'test_case_dto.dart';
TestCase dtoToDomain(TestCaseDto dto) => TestCase(
  id:dto.id, title:dto.title, module:dto.module, feature:dto.feature, platform:'', priority:dto.priority, type:'Functional',
  preconditions:dto.preconditions,
  steps:dto.steps.map((s)=>TestStep(action:s['action']??'', data:s['data']??'', expected:s['expected']??'')).toList(),
  expectedResult:dto.expectedResult);
