import 'package:qa_genie/core/forensics/forensics_service.dart';
import 'package:qa_genie/core/forensics/forensics_service_prod.dart';

class ForensicsProvider {
  static ForensicsService? _service;

  static void init(ForensicsService service) {
    _service = service;
  }

  static ForensicsService get instance {
    return _service ?? ForensicsServiceProd();
  }
}
