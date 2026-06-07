import 'dart:math';

import 'package:qa_genie/engine/generators/data_generator.dart';

class TelehealthDataGenerator implements DataGenerator {
  @override
  Map<String, dynamic> generate({required String outcome, required String seed}) {
    final random = Random(seed.hashCode);
    switch (outcome) {
      case 'start_consultation':
      case 'join_consultation':
        return {
          'meeting_id': 'mtg_${random.nextInt(100000)}',
          'patient_id': 'pat_${random.nextInt(10000)}',
        };
      case 'end_consultation':
        return {'meeting_id': 'mtg_${random.nextInt(100000)}'};
      case 'provider_unavailable':
        return {'provider_id': 'prov_${random.nextInt(100)}', 'status': 'unavailable'};
      case 'patient_no_show':
        return {'meeting_id': 'mtg_${random.nextInt(100000)}', 'patient_id': 'pat_${random.nextInt(10000)}'};
      case 'network_failure':
        return {'meeting_id': 'mtg_${random.nextInt(100000)}', 'error_code': 'NETWORK_LOST'};
      case 'invalid_meeting_id':
        return {'meeting_id': 'INVALID_MEETING'};
      case 'missing_camera_permission':
      case 'missing_mic_permission':
        return {'meeting_id': 'mtg_${random.nextInt(100000)}'};
      default:
        return {};
    }
  }
}