/// Tipos equivalentes a workflow.types.ts de la web para armar los payloads de la Lambda

library;

class WorkflowRequest {
  final List<WorkflowFlow> flows;

  WorkflowRequest({required this.flows});

  Map<String, dynamic> toJson() => {
        'flows': flows.map((f) => f.toJson()).toList(),
      };
}

class WorkflowFlow {
  final String name;
  final List<WorkflowStep> steps;

  WorkflowFlow({required this.name, required this.steps});

  Map<String, dynamic> toJson() => {
        'name': name,
        'steps': steps.map((s) => s.toJson()).toList(),
      };
}

class WorkflowStep {
  final String name;
  final List<WorkflowAction> actions;

  WorkflowStep({required this.name, required this.actions});

  Map<String, dynamic> toJson() => {
        'name': name,
        'actions': actions.map((a) => a.toJson()).toList(),
      };
}

class WorkflowAction {
  final String name;
  final String action;
  final Map<String, dynamic>? params;

  WorkflowAction({
    required this.name,
    required this.action,
    this.params,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'action': action,
    };
    if (params != null) {
      map['params'] = params;
    }
    return map;
  }
}

/// Helper para armar consultas de forma rapida (similar a buildQueryRequest de TS)
WorkflowRequest buildQueryRequest({
  required String flowName,
  required String stepName,
  required String actionName,
  Map<String, dynamic>? params,
}) {
  return WorkflowRequest(
    flows: [
      WorkflowFlow(
        name: flowName,
        steps: [
          WorkflowStep(
            name: stepName,
            actions: [
              WorkflowAction(
                name: actionName,
                action: 'query',
                params: params,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Helper para armar mutaciones de forma rapida (similar a buildMutationRequest de TS)
WorkflowRequest buildMutationRequest({
  required String flowName,
  required String stepName,
  required String actionName,
  Map<String, dynamic>? params,
}) {
  return WorkflowRequest(
    flows: [
      WorkflowFlow(
        name: flowName,
        steps: [
          WorkflowStep(
            name: stepName,
            actions: [
              WorkflowAction(
                name: actionName,
                action: 'mutation',
                params: params,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
