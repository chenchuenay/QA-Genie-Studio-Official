import 'package:equatable/equatable.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/entities/test_step.dart';

// ignore: must_be_immutable
class FinalizedTestCase extends Equatable {
  int? dbId;
  String id;
  String title;
  List<String> preconditions;
  String testData;
  List<TestStep> steps;
  String expectedResult;
  String actualResult;
  String priority;
  String status;
  String type;
  String module;
  String feature;
  String platform;
  CaseSource source;

  FinalizedTestCase({
    this.dbId,
    required this.id,
    required this.title,
    required this.preconditions,
    required this.testData,
    required this.steps,
    required this.expectedResult,
    this.actualResult = '',
    required this.priority,
    this.status = 'Not Executed',
    required this.type,
    required this.module,
    required this.feature,
    required this.platform,
    this.source = CaseSource.ai,
  });

  FinalizedTestCase copyWith({
    int? dbId,
    String? id,
    String? title,
    List<String>? preconditions,
    String? testData,
    List<TestStep>? steps,
    String? expectedResult,
    String? actualResult,
    String? priority,
    String? status,
    String? type,
    String? module,
    String? feature,
    String? platform,
    CaseSource? source,
  }) {
    return FinalizedTestCase(
      dbId: dbId ?? this.dbId,
      id: id ?? this.id,
      title: title ?? this.title,
      preconditions: preconditions ?? List.from(this.preconditions),
      testData: testData ?? this.testData,
      steps: steps ?? this.steps.map((s) => s.copyWith()).toList(),
      expectedResult: expectedResult ?? this.expectedResult,
      actualResult: actualResult ?? this.actualResult,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      type: type ?? this.type,
      module: module ?? this.module,
      feature: feature ?? this.feature,
      platform: platform ?? this.platform,
      source: source ?? this.source,
    );
  }

  @override
  List<Object?> get props => [
    dbId,
    id,
    title,
    preconditions,
    testData,
    steps,
    expectedResult,
    actualResult,
    priority,
    status,
    type,
    module,
    feature,
    platform,
    source,
  ];
}
