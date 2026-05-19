import 'package:qa_genie/engine/models/pipeline_models.dart';

abstract class RepairRule {
  bool apply(WorkingCase tc);
  String get name;
}
