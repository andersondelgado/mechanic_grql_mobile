/// Tipos equivalentes a workflow.types.ts de la web para armar los payloads de la Lambda gRQL.

library;

/// Estructura raíz de toda petición a la lambda gRQL
class WorkflowRequest {
  final WorkflowRequestData request;

  WorkflowRequest({required this.request});

  Map<String, dynamic> toJson() => {'request': request.toJson()};
}

class WorkflowRequestData {
  final List<Workflow> flows;

  WorkflowRequestData({required this.flows});

  Map<String, dynamic> toJson() => {
    'flows': flows.map((f) => f.toJson()).toList(),
  };
}

/// Workflow completo
class Workflow {
  final String name;
  final String description;
  final List<WorkflowStep> steps;

  Workflow({
    required this.name,
    required this.description,
    required this.steps,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'steps': steps.map((s) => s.toJson()).toList(),
  };
}

/// Paso dentro de un workflow
class WorkflowStep {
  final String name;
  final String type; // 'function'
  final String functionName;
  final List<WorkflowAction> actions;

  WorkflowStep({
    required this.name,
    this.type = 'function',
    required this.functionName,
    required this.actions,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'functionName': functionName,
    'actions': actions.map((a) => a.toJson()).toList(),
  };
}

/// Acción individual dentro de un paso del workflow
class WorkflowAction {
  final String name;
  final String type; // 'api'
  final String action; // 'query' | 'mutation' | 'custom_function'
  final Map<String, dynamic>? params;
  final Map<String, dynamic>? body;

  WorkflowAction({
    required this.name,
    this.type = 'api',
    required this.action,
    this.params,
    this.body,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'name': name, 'type': type, 'action': action};
    if (params != null) map['params'] = params;
    if (body != null) map['body'] = body;
    return map;
  }
}

/// Parámetros de consulta para acciones de tipo query
class WorkflowQuery {
  final bool? inverseFk;
  final Map<String, dynamic>? pagination;
  final Map<String, dynamic>? filter;
  final List<Map<String, dynamic>>? arrayFilter;
  final Map<String, dynamic>? extraFilter;
  final Map<String, dynamic>? avanzedFilter;
  final Map<String, dynamic>? order;
  final Map<String, dynamic>? otherFields;

  WorkflowQuery({
    this.inverseFk,
    this.pagination,
    this.filter,
    this.arrayFilter,
    this.extraFilter,
    this.avanzedFilter,
    this.order,
    this.otherFields,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (pagination != null) map['pagination'] = pagination;
    if (filter != null) map['filter'] = filter;
    if (arrayFilter != null) map['arrayFilter'] = arrayFilter;
    if (extraFilter != null) map['extraFilter'] = extraFilter;
    if (avanzedFilter != null) map['avanzedFilter'] = avanzedFilter;
    if (order != null) map['order'] = order;
    if (otherFields != null) map.addAll(otherFields!);
    return map;
  }
}

/// Helper para armar consultas de forma rápida (equivalente a buildQueryRequest de TS)
WorkflowRequest buildQueryRequest({
  required String flowName,
  required String stepName,
  required String actionName,
  WorkflowQuery? query,
}) {
  // Inyectar _inverse_fk: true en arrayFilter por defecto (como hace el web)
  final existingArrayFilter = query?.arrayFilter ?? [];
  final hasInverseFk = existingArrayFilter.any(
    (f) => f['field'] == '_inverse_fk',
  );
  final arrayFilter = hasInverseFk
      ? existingArrayFilter
      : [
          {'field': '_inverse_fk', 'value': true},
          ...existingArrayFilter,
        ];

  final mergedQuery = WorkflowQuery(
    pagination: query?.pagination ?? {'page': 1, 'size': 100},
    filter: query?.filter,
    arrayFilter: arrayFilter,
    extraFilter: query?.extraFilter,
    avanzedFilter: query?.avanzedFilter,
    order: query?.order,
    otherFields: query?.otherFields,
  );

  return WorkflowRequest(
    request: WorkflowRequestData(
      flows: [
        Workflow(
          name: flowName,
          description: flowName,
          steps: [
            WorkflowStep(
              name: stepName,
              functionName: stepName,
              actions: [
                WorkflowAction(
                  name: actionName,
                  action: 'query',
                  params: {'query': mergedQuery.toJson()},
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

/// Helper para armar mutaciones de forma rápida (equivalente a buildMutationRequest de TS)
WorkflowRequest buildMutationRequest({
  required String flowName,
  required String stepName,
  required String actionName,
  Map<String, dynamic>? body,
  Map<String, dynamic>? path,
}) {
  final params = <String, dynamic>{};
  if (body != null) params['body'] = body;
  if (path != null) params['path'] = path;

  return WorkflowRequest(
    request: WorkflowRequestData(
      flows: [
        Workflow(
          name: flowName,
          description: flowName,
          steps: [
            WorkflowStep(
              name: stepName,
              functionName: stepName,
              actions: [
                WorkflowAction(
                  name: actionName,
                  action: 'mutation',
                  params: params.isNotEmpty ? params : null,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

/// Helper para armar custom_function (ej: stats)
WorkflowRequest buildCustomFunctionRequest({
  required String flowName,
  required String stepName,
  Map<String, dynamic>? body,
}) {
  return WorkflowRequest(
    request: WorkflowRequestData(
      flows: [
        Workflow(
          name: flowName,
          description: flowName,
          steps: [
            WorkflowStep(
              name: stepName,
              functionName: stepName,
              actions: [
                WorkflowAction(
                  name: 'custom_function',
                  action: 'custom_function',
                  body: body ?? {},
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

/// Extrae el data del primer action result, o del payload directo de la lambda
/// Equivalente a extractData() de la web
dynamic extractData(dynamic response) {
  if (response == null) return null;
  if (response is List) return response;

  // 1. Patrón estándar Lusiana (request/flows)
  final standardData =
      response?['request']?['flows']?[0]?['steps']?[0]?['actions']?[0]?['result']?['data'];
  if (standardData != null) {
    if (standardData is List) return standardData;
    if (standardData is Map && standardData['content'] is List) {
      return standardData['content'];
    }
    return standardData;
  }

  // 2. Patrón de respuesta directa de la Lambda
  final keys = (response as Map).keys.where((k) => k != 'request');
  for (final key in keys) {
    final tableData = response[key];
    if (tableData is! Map) continue;

    // Respuesta paginada: { table: { paginate: { content: [...] } } }
    if (tableData['paginate'] is Map &&
        tableData['paginate']['content'] is List) {
      return tableData['paginate']['content'];
    }

    // Lista directa
    if (tableData['content'] is List) return tableData['content'];
    if (tableData is List) return tableData;

    // Objeto único válido (create/update con id)
    if (tableData['id'] != null || tableData['success'] != null) {
      return tableData;
    }
  }

  return null;
}

/// Extrae los metadatos de paginación del payload directo de la lambda
dynamic extractPagination(dynamic response) {
  if (response == null) return null;
  final keys = (response as Map).keys.where((k) => k != 'request');
  for (final key in keys) {
    final tableData = response[key];
    if (tableData is Map && tableData['paginate'] is Map) {
      final paginate = tableData['paginate'] as Map;
      final meta = Map.from(paginate)..remove('content');
      return meta;
    }
  }
  return null;
}
