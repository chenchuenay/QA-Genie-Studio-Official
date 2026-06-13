import 'package:qa_genie/core/forensics/forensics_service.dart';
import 'package:qa_genie/core/forensics/forensics_service_prod.dart';
import 'package:qa_genie/core/forensics/forensics_service_dev.dart';

class ForensicsProvider {
  // bool.fromEnvironment is a compile-time constant. 
  // The Dart compiler will prune the unused branch for production builds.
  static const bool isProd = bool.fromEnvironment('MODE', defaultValue: false);

  static ForensicsService get instance {
    if (isProd) {
      return ForensicsServiceProd();
    } else {
      return ForensicsServiceDev();
    }
  }
}
