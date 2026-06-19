import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/generators/flow_graph_generator.dart';

void main() {
  group('FlowGraphGenerator', () {
    test('generate returns steps for known domain and action', () {
      final steps = FlowGraphGenerator.generate('Identity', 'login', 'Mobile', '');
      expect(steps, isNotEmpty);
      expect(steps.length, 4);
      expect(steps[0]['action'], 'TapLoginField');
      expect(steps[1]['action'], 'EnterCredentials');
      expect(steps[2]['action'], 'TapSubmit');
      expect(steps[3]['action'], 'VerifyDashboard');
    });

    test('generate returns steps for known platform variant', () {
      final steps = FlowGraphGenerator.generate('Identity', 'login', 'Web', '');
      expect(steps[0]['action'], 'ClickLoginButton');
      expect(steps[2]['action'], 'ClickSubmit');
    });

    test('generate returns steps for API platform', () {
      final steps = FlowGraphGenerator.generate('Identity', 'login', 'API', '');
      expect(steps[0]['action'], 'PostAuthPayload');
      expect(steps[2]['action'], 'VerifyStatusCode200');
    });

    test('generate returns fallback for unknown platform', () {
      final steps = FlowGraphGenerator.generate('Identity', 'login', 'Desktop', '');
      expect(steps, isNotEmpty);
    });

    test('generate returns fallback for unknown domain', () {
      final steps = FlowGraphGenerator.generate('UnknownDomain', 'someAction', 'Web', '');
      expect(steps.length, 1);
      expect(steps[0]['action'], contains('someAction'));
      expect(steps[0]['data'], 'Standard input data');
    });

    test('generate returns steps for Commerce domain', () {
      final steps = FlowGraphGenerator.generate('Commerce', 'add', 'Mobile', '');
      expect(steps[0]['action'], 'BrowseCatalog');
      expect(steps[1]['action'], 'TapAddToCart');
      expect(steps[2]['action'], 'VerifyCartBadge');
    });

    test('generate returns steps for Transaction domain', () {
      final steps = FlowGraphGenerator.generate('Transaction', 'transfer', 'Web', '');
      expect(steps[0]['action'], 'ClickMoveMoney');
      expect(steps[1]['action'], 'ChooseAccount');
      expect(steps[2]['action'], 'InputAmount');
      expect(steps[3]['action'], 'ClickConfirm');
    });

    test('generate returns steps for Scheduling domain', () {
      final steps = FlowGraphGenerator.generate('Scheduling', 'create', 'Web', '');
      expect(steps[0]['action'], 'NavigateToDateRange');
      expect(steps[2]['action'], 'VerifyApprovalStatus');
    });

    test('generate returns steps for Records domain', () {
      final steps = FlowGraphGenerator.generate('Records', 'view', 'Mobile', '');
      expect(steps[0]['action'], 'TapDocuments');
      expect(steps[1]['action'], 'OpenPDFDocument');
      expect(steps[2]['action'], 'VerifyContentVisibility');
    });

    test('generate returns steps for Integration domain', () {
      final steps = FlowGraphGenerator.generate('Integration', 'send', 'API', '');
      expect(steps[0]['action'], 'ClickTriggerPipeline');
      expect(steps[2]['action'], 'VerifyDeploymentSuccess');
    });

    test('generate provides domain sample data for known steps', () {
      final steps = FlowGraphGenerator.generate('Identity', 'login', 'Web', '');
      expect(steps[0]['data'], contains('Locate and click Login button'));
      expect(steps[1]['data'], contains('admin@test.com'));
    });

    test('_generateDataForStep provides domain-aware data', () {
      final steps = FlowGraphGenerator.generate('Commerce', 'add', 'Mobile', '');
      final dataSteps = steps.where((s) => s['data']!.isNotEmpty).toList();
      expect(dataSteps, isNotEmpty);
    });

    test('generate handles actions with no constraints required', () {
      final steps = FlowGraphGenerator.generate('Identity', 'reset', 'Web', 'some constraint');
      expect(steps, isNotEmpty);
      expect(steps[0]['action'], 'ClickResetLink');
    });
  });
}
