import 'package:qa_genie/core/database/database_service.dart';
class GetHistoryUseCase {
  Future<List<Map<String,dynamic>>> execute() async => await DatabaseService.getAllSuites();
}
