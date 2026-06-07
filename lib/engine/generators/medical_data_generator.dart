import 'dart:math';
import 'package:qa_genie/engine/generators/data_generator.dart';


class MedicalDataGenerator implements DataGenerator {
  @override
  Map<String, dynamic> generate({
    required String outcome,
    required String seed,
  }) {
    final random = Random(seed.hashCode);
    switch (outcome) {
      case 'schedule_appointment':
        return {
          'patient_id': 'pat_${random.nextInt(10000)}',
          'doctor_id': 'doc_${random.nextInt(100)}',
          'date': '2025-${random.nextInt(12) + 1}-${random.nextInt(28) + 1}',
          'time': '${random.nextInt(12) + 9}:00',
        };
      case 'cancel_appointment':
      case 'reschedule_appointment':
        return {'appointment_id': 'apt_${random.nextInt(10000)}'};
      case 'prescription_refill_request':
        return {'prescription_id': 'rx_${random.nextInt(10000)}'};
      case 'view_lab_results':
        return {'patient_id': 'pat_${random.nextInt(10000)}'};
      case 'invalid_insurance':
        return {
          'insurance_id': 'INVALID_INS',
          'patient_id': 'pat_${random.nextInt(10000)}',
        };
      case 'duplicate_booking':
        return {
          'doctor_id': 'doc_${random.nextInt(100)}',
          'date': '2025-06-10',
          'time': '10:00',
        };
      case 'refill_too_early':
        return {
          'prescription_id': 'rx_${random.nextInt(10000)}',
          'last_refill': '2025-05-01',
        };
      case 'prescription_not_found':
        return {'prescription_id': 'NOT_FOUND'};
      case 'missing_consent':
        return {
          'patient_id': 'pat_${random.nextInt(10000)}',
          'consent_form': 'HIPAA_consent.pdf',
        };
      default:
        return {};
    }
  }
}
