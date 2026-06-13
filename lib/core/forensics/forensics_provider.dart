import 'package:flutter/foundation.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/core/config/app_environment.dart';
import 'package:qa_genie/core/forensics/forensics_service.dart';
import 'package:qa_genie/core/forensics/forensics_service_prod.dart';
import 'package:qa_genie/core/forensics/forensics_service_dev.dart';

class ForensicsProvider {
  static bool get isProd {
    // 🛡️ TRIPLE-LOCK SECURITY:
    // 1. Check Authority (MODE=prod)
    // 2. Check VM Product (Release build)
    // 3. Check AppConfig (Safe fallback)
    return EnvironmentAuthority.isProduction || 
           kReleaseMode || 
           AppConfig.isProduction;
  }

  static ForensicsService get instance {
    if (isProd) {
      return ForensicsServiceProd();
    } else {
      return ForensicsServiceDev();
    }
  }
}
