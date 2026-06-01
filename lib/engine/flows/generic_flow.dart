import 'package:qa_genie/engine/adapters/platform_adapter.dart';

class GenericFlow {
  final String id; // e.g., 'AuthenticationFlow'
  final List<WorkflowNode> nodes;

  const GenericFlow({required this.id, required this.nodes});
}

class GenericFlows {
  static const authentication = GenericFlow(
    id: 'AuthenticationFlow',
    nodes: [
      WorkflowNode(action: StepAction.navigate, entity: EntityType.entryPoint),
      WorkflowNode(action: StepAction.input, entity: EntityType.credentialForm),
      WorkflowNode(action: StepAction.submit, entity: EntityType.actionButton),
      WorkflowNode(
        action: StepAction.verify,
        entity: EntityType.successIndicator,
      ),
    ],
  );

  static const transaction = GenericFlow(
    id: 'TransactionFlow',
    nodes: [
      WorkflowNode(action: StepAction.navigate, entity: EntityType.entryPoint),
      WorkflowNode(action: StepAction.select, entity: EntityType.item),
      WorkflowNode(action: StepAction.input, entity: EntityType.amount),
      WorkflowNode(action: StepAction.submit, entity: EntityType.actionButton),
      WorkflowNode(action: StepAction.verify, entity: EntityType.receipt),
    ],
  );

  static const recovery = GenericFlow(
    id: 'RecoveryFlow',
    nodes: [
      WorkflowNode(action: StepAction.navigate, entity: EntityType.entryPoint),
      WorkflowNode(action: StepAction.input, entity: EntityType.recoveryField),
      WorkflowNode(action: StepAction.submit, entity: EntityType.actionButton),
      WorkflowNode(action: StepAction.verify, entity: EntityType.confirmation),
    ],
  );

  static const session = GenericFlow(
    id: 'SessionFlow',
    nodes: [
      WorkflowNode(action: StepAction.navigate, entity: EntityType.entryPoint),
      WorkflowNode(action: StepAction.wait, entity: EntityType.timeout),
      WorkflowNode(action: StepAction.verify, entity: EntityType.sessionStatus),
    ],
  );
}
