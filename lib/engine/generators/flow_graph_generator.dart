import '../ontology/domain_registry.dart';
import '../ontology/domain_data.dart';

class FlowGraphGenerator {
  static List<Map<String, String>> generate(
    String domain,
    String action,
    String platform,
    String constraints,
  ) {
    final pattern = DomainRegistry.ontology[domain]?[action];
    if (pattern == null) {
      return [{'action': 'Execute $action for $domain', 'data': 'Standard input data', 'expected': 'Operation completes successfully'}];
    }

    final constraintList = constraints.split(',').map((s) => s.trim()).toList();
    for (final req in pattern.requiredConstraints) {
      if (!constraintList.contains(req)) {
        return [{'action': 'Skip action', 'data': 'Constraints not met: $req', 'expected': 'Action skipped'}];
      }
    }

    final dataSamples = DomainData.samples[domain] ?? {};
    final steps = <Map<String, String>>[];
    final actionSteps = pattern.stepsByPlatform[platform] ?? pattern.stepsByPlatform.values.first;

    for (int i = 0; i < actionSteps.length; i++) {
      final step = actionSteps[i];
      final stepData = dataSamples[step] ?? _generateDataForStep(step, domain, action, i);
      final stepExpected = _generateExpected(step, domain, action, i, actionSteps.length);
      steps.add({
        'action': step,
        'data': stepData,
        'expected': stepExpected,
      });
    }

    return steps;
  }

  static String _generateDataForStep(String step, String domain, String action, int index) {
    if (step.contains('Login') || step.contains('Email') || step.contains('Credential')) {
      if (index == 0) return 'Navigate to login page and wait for form to render';
      if (index == 1) return 'admin@demo.com / SecurePass789!';
      return 'Valid credentials authenticated via POST /auth';
    }
    if (step.contains('OTP') || step.contains('Token') || step.contains('Code') || step.contains('Verif')) {
      return 'Enter 6-digit code: 482916 (sent to registered mobile/email)';
    }
    if (step.contains('Amount') || step.contains('Price') || step.contains('Quantity')) {
      return '250.00 (valid range: 1.00 - 9999.99)';
    }
    if (step.contains('Search') || step.contains('Select') || step.contains('Choose') || step.contains('Browse')) {
      return 'Select from dropdown: option matching "headphones" filter';
    }
    if (step.contains('Submit') || step.contains('Confirm') || step.contains('Place') || step.contains('Send')) {
      return 'Complete all required fields and tap confirm';
    }
    if (step.contains('Address') || step.contains('Shipping') || step.contains('Location')) {
      return '42 Maple Drive, Springfield, IL 62701, United States';
    }
    if (step.contains('Payment') || step.contains('Card') || step.contains('Billing')) {
      return 'VISA **** 4242 | Exp: 08/27 | CVV: 345 | Billing matches shipping';
    }
    if (step.contains('Password') || step.contains('Reset') || step.contains('NewPassword')) {
      return 'NewCred#789 / Confirm: NewCred#789 (min 8 chars, 1 special, 1 num)';
    }
    if (step.contains('Date') || step.contains('Schedule') || step.contains('Time')) {
      return 'Start: 2026-07-15 09:00, End: 2026-07-15 17:00 (business hours)';
    }
    if (step.contains('File') || step.contains('Upload') || step.contains('Document') || step.contains('PDF')) {
      return 'Upload: report_Q2_2026.pdf (2.4 MB, application/pdf)';
    }
    if (step.contains('Delete') || step.contains('Remove') || step.contains('Cancel')) {
      return 'Confirm deletion: type "DELETE" in confirmation field';
    }
    if (step.contains('Comment') || step.contains('Note') || step.contains('Description')) {
      return 'Enter text: "Approved after reviewing all test cases. Ready for UAT."';
    }
    if (step.contains('Filter') || step.contains('Sort')) {
      return 'Apply filter: status=active, sortBy=createdDate, order=desc';
    }
    if (step.contains('Error') || step.contains('Invalid') || step.contains('Wrong')) {
      return 'Input: invalid@ / xyz (malformed data for negative testing)';
    }
    return _domainAwareData(domain, step, index);
  }

  static String _domainAwareData(String domain, String step, int index) {
    if (domain == 'Identity') return 'user@domain.com / auth payload prepared';
    if (domain == 'Commerce') return 'Product SKU-7755 — in stock, \$49.99';
    if (domain == 'Transaction') return 'From: Savings XXXX-8901, To: Checking XXXX-3456, Amt: 350.00';
    if (domain == 'Scheduling') return 'Date range: 2026-08-01 to 2026-08-05, type: Annual Leave';
    if (domain == 'Records') return 'Record ID: REC-2026-0042, accessible via search';
    if (domain == 'Integration') return 'Webhook URL: https://api.example.com/hooks/v1/trigger';
    return 'Standard input value for step $index';
  }

  static String _generateExpected(String step, String domain, String action, int index, int total) {
    if (step.startsWith('Verify') || step.startsWith('Check') || step.startsWith('Assert')) {
      return 'System displays accurate data matching source of truth — no discrepancies';
    }
    if (step.contains('Submit') || step.contains('Confirm') || step.contains('Place')) {
      return 'Server responds 200 OK with success payload; confirmation UI shown';
    }
    if (step.contains('Error') || step.contains('Fail') || step.contains('Invalid')) {
      return 'Validation error message appears inline; form does not submit';
    }
    if (step.contains('Login') || step.contains('Sign') || step.contains('Auth')) {
      return 'User is redirected to dashboard/home page with authenticated session';
    }
    if (step.contains('OTP') || step.contains('Token') || step.contains('Verif')) {
      return 'System accepts OTP and proceeds to next step; error if expired or wrong';
    }
    if (step.contains('Delete') || step.contains('Remove') || step.contains('Cancel')) {
      return 'Item is permanently removed; confirmation toast shown; list refreshes';
    }
    if (step.contains('Search') || step.contains('Filter') || step.contains('Sort')) {
      return 'List updates to show filtered/sorted results matching criteria';
    }
    if (step.contains('Upload') || step.contains('File') || step.contains('Document')) {
      return 'File is uploaded successfully; progress bar reaches 100%; thumbnail appears';
    }
    if (step.contains('Payment') || step.contains('Pay') || step.contains('Billing')) {
      return 'Payment gateway returns success; receipt generated; balance updated';
    }
    if (index == total - 1) {
      return 'End-to-end flow completes successfully — all assertions pass';
    }
    return 'Step completes without error; UI reflects the new state';
  }
}
