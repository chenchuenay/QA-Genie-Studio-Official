import 'package:qa_genie/engine/flows/generic_flow.dart';
import 'package:qa_genie/engine/adapters/platform_adapter.dart';

class ScenarioExpander {
  static List<WorkflowNode> expand(GenericFlow flow, String outcome) {
    final nodes = List<WorkflowNode>.from(flow.nodes);
    if (flow.id == 'AuthenticationFlow') {
      if (outcome == 'social_login') {
        final insertIndex = nodes.indexWhere(
          (n) => n.entity == EntityType.credentialForm,
        );
        if (insertIndex != -1) {
          nodes.insertAll(insertIndex + 1, [
            WorkflowNode(
              action: StepAction.select,
              entity: EntityType.oauthProvider,
            ),
            WorkflowNode(
              action: StepAction.submit,
              entity: EntityType.oauthConsent,
            ),
            WorkflowNode(action: StepAction.wait, entity: EntityType.callback),
          ]);
        }
      } else if (outcome == 'mfa_login') {
        final insertIndex = nodes.indexWhere(
          (n) => n.entity == EntityType.actionButton,
        );
        if (insertIndex != -1) {
          nodes.insert(
            insertIndex + 1,
            WorkflowNode(action: StepAction.input, entity: EntityType.otpCode),
          );
        }
      } else if (outcome == 'remembered_session') {
        nodes.add(
          WorkflowNode(
            action: StepAction.verify,
            entity: EntityType.sessionToken,
          ),
        );
      }
    }
    return nodes;
  }
}
