import 'package:qa_app/data/sources/local/database_service.dart';
class GetHistoryUseCase {
  Future<List<Map<String,dynamic>>> execute() async => await DatabaseService.getAllSuites();
}
