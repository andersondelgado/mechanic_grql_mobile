import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/env_config.dart';
import 'workflow_types.dart';

/// Cliente HTTP para comunicarse con las lambdas gRQL.
/// Patrón adoptado del proyecto web:
///  - Triple capa de auth: API Key + JWT Bearer + Lambda Token
///  - workflowJson() como función central
///  - Helpers CRUD de alto nivel
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;

  // ─── Endpoints y Configuración Dinámica (EnvConfig) ───────────────────
  static String get baseUrl => EnvConfig.apiBaseUrl;
  static String get apiBase => EnvConfig.apiBase;
  static String get lambdaEndpointNode => EnvConfig.lambdaEndpointNode;
  static String get dbLambdas => EnvConfig.dbLambdas;
  static String get apiKey => EnvConfig.apiKey;
  static String get lambdaCompose => EnvConfig.lambdaCompose;
  static String get defaultOwner => EnvConfig.defaultOwner;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(seconds: EnvConfig.connectTimeoutSeconds),
        receiveTimeout: Duration(seconds: EnvConfig.receiveTimeoutSeconds),
        contentType: Headers.jsonContentType,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();

          // 1. API Key (siempre presente)
          if (apiKey.isNotEmpty) {
            options.headers['x-grql-auth'] = apiKey;
          }

          // 2. Lambda Token (X-Grql-Lambda)
          final lambdaToken =
              prefs.getString('lambdaToken') ?? prefs.getString('token');
          if (lambdaToken != null && lambdaToken.isNotEmpty) {
            options.headers['X-Grql-Lambda'] = lambdaToken;
          }

          // 3. JWT Bearer Token
          final token = prefs.getString('token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('token');
            await prefs.remove('lambdaToken');
            // El widget de navegación detectará el cambio de auth
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // ─── Lambda Decode (equivalente a lambdaDecode de config.ts) ──────────

  /// Decodifica el LAMBDA_COMPOSE (base64) y retorna el UUID por nombre.
  /// Implementa coincidencia exacta y mapeos para taller/garage y security.
  static String? lambdaDecode(String name) {
    try {
      final raw = lambdaCompose.trim();
      if (raw.isEmpty) return null;

      // Limpiar posibles comillas envolventes
      final clean = raw.replaceAll(RegExp(r'^["\x27]|["\x27]$'), '').trim();
      if (clean.isEmpty) return null;

      final decodedStr = utf8.decode(base64.decode(clean));
      final decoded = jsonDecode(decodedStr);
      final list = (decoded as List).cast<Map<String, dynamic>>();

      // 1. Coincidencia exacta
      final exact = list.firstWhere((l) => l['name'] == name, orElse: () => {});
      if (exact.isNotEmpty && exact['id'] != null) {
        return exact['id'] as String;
      }

      // 2. Mapeo para workflow de taller / garage (ej. workflow_taller_js <-> workflow_garage_node)
      if (name.contains('taller') || name.contains('garage')) {
        final match = list.firstWhere((l) {
          final n = (l['name'] ?? '').toString();
          return n.contains('garage') || n.contains('taller');
        }, orElse: () => {});
        if (match.isNotEmpty && match['id'] != null) {
          return match['id'] as String;
        }
      }

      // 3. Mapeo para workflow de seguridad (ej. workflow_security_js <-> workflow_security_node)
      if (name.contains('security')) {
        final match = list.firstWhere((l) {
          final n = (l['name'] ?? '').toString();
          return n.contains('security');
        }, orElse: () => {});
        if (match.isNotEmpty && match['id'] != null) {
          return match['id'] as String;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Construye la URL completa para llamar a una lambda
  static String buildLambdaUrl(String lambdaId, {String workspace = 'lambda'}) {
    return '/api/secure-rQL/lambdas-json-run-node?db=$dbLambdas&table=$workspace&id=$lambdaId&format=json';
  }

  // ─── Core: workflowJson (equivalente a client.ts workflowJson) ─────────

  /// Envía un WorkflowRequest a la lambda indicada.
  /// Implementa caché para queries (simplificado vs web).
  Future<Map<String, dynamic>> workflowJson({
    required WorkflowRequest request,
    String lambdaName = 'workflow_taller_js',
    String workspace = 'lambda',
  }) async {
    final lambdaId = lambdaDecode(lambdaName);
    if (lambdaId == null) throw Exception('Lambda no encontrada: $lambdaName');

    final url = buildLambdaUrl(lambdaId, workspace: workspace);

    try {
      final response = await _dio.post(url, data: request.toJson());
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ─── callLambda (equivalente a callLambda del web) ─────────────────────

  /// Envía un payload arbitrario a la lambda principal (para video, IA, etc.)
  Future<Map<String, dynamic>> callLambda(Map<String, dynamic> payload) async {
    final lambdaId = lambdaDecode('workflow_taller_js');
    if (lambdaId == null) throw Exception('Lambda principal no encontrada');

    final url = buildLambdaUrl(lambdaId);
    try {
      final response = await _dio.post(url, data: payload);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ─── Helpers CRUD de alto nivel ───────────────────────────────────────
  static const String workflowName = 'workflow_taller';

  Future<List<dynamic>> getEntity(String table, {WorkflowQuery? query}) async {
    final request = buildQueryRequest(
      flowName: workflowName,
      stepName: table,
      actionName: 'get',
      query: query ?? WorkflowQuery(pagination: {'page': 1, 'size': 100}),
    );
    final response = await workflowJson(request: request);
    return _asList(extractData(response));
  }

  Future<List<dynamic>> getPaginatedEntity(
    String table, {
    WorkflowQuery? query,
    int pageSize = 10,
  }) async {
    final request = buildQueryRequest(
      flowName: workflowName,
      stepName: table,
      actionName: 'get',
      query: query ?? WorkflowQuery(pagination: {'page': 1, 'size': pageSize}),
    );
    final response = await workflowJson(request: request);
    return _asList(extractData(response));
  }

  Future<Map<String, dynamic>?> getEntityById(String table, String id) async {
    final request = buildQueryRequest(
      flowName: workflowName,
      stepName: table,
      actionName: 'get',
      query: WorkflowQuery(filter: {'id': id}),
    );
    final response = await workflowJson(request: request);
    final data = extractData(response);
    if (data is List && data.isNotEmpty) {
      return (data.first as Map).cast<String, dynamic>();
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return null;
  }

  Future<List<dynamic>> getEntitiesByFilter(
    String table,
    List<Map<String, dynamic>> arrayFilter,
  ) async {
    final request = buildQueryRequest(
      flowName: workflowName,
      stepName: table,
      actionName: 'dataFilter',
      query: WorkflowQuery(arrayFilter: arrayFilter),
    );
    final response = await workflowJson(request: request);
    return _asList(extractData(response));
  }

  Future<dynamic> createEntity(String table, Map<String, dynamic> data) async {
    final request = buildMutationRequest(
      flowName: workflowName,
      stepName: table,
      actionName: 'create',
      body: data,
    );
    final response = await workflowJson(request: request);
    return extractData(response);
  }

  Future<dynamic> updateEntity(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    final request = buildMutationRequest(
      flowName: workflowName,
      stepName: table,
      actionName: 'putById',
      body: {...data, 'id': id},
      path: {'id': id},
    );
    final response = await workflowJson(request: request);
    return extractData(response);
  }

  Future<void> deleteEntity(String table, String id) async {
    final request = buildMutationRequest(
      flowName: workflowName,
      stepName: table,
      actionName: 'deleteById',
      path: {'id': id},
    );
    await workflowJson(request: request);
  }

  // ─── Video + IA (equivalentes a uploadVideo/analyzeVideo del web) ─────

  Future<Map<String, dynamic>> uploadVideo(
    String video,
    String inspectionCardId,
  ) async {
    return callLambda({
      'table': 'GestionTallerProd_inspection_video',
      'method': 'UPLOAD',
      'data': {'video': video, 'inspection_cards_fk_id': inspectionCardId},
    });
  }

  Future<Map<String, dynamic>> analyzeVideo(
    String inspectionCardId,
    String videoUrl,
  ) async {
    return callLambda({
      'table': 'GestionTallerProd_inspection_analysis',
      'method': 'ANALYZE',
      'data': {
        'inspection_cards_fk_id': inspectionCardId,
        'video_url': videoUrl,
        'owner': defaultOwner,
      },
    });
  }

  // ─── Stats (equivalente a stats.service.ts) ───────────────────────────

  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final request = buildCustomFunctionRequest(
        flowName: workflowName,
        stepName: 'GestionTallerProd_stats',
      );
      final response = await workflowJson(request: request);

      // Intentar extraer stats de múltiples patrones de respuesta
      final tableData = response['GestionTallerProd_stats'];
      if (tableData is Map) {
        final result =
            (tableData['custom_function'] as Map?) ??
            (tableData['customFunction'] as Map?) ??
            (tableData['data'] as Map?) ??
            tableData;
        return result.cast<String, dynamic>();
      }
      if (response['data'] is Map) {
        return (response['data'] as Map).cast<String, dynamic>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Auth (equivalente a security.service.ts) ─────────────────────────

  Future<Map<String, dynamic>> signIn(String username, String password) async {
    final request = buildMutationRequest(
      flowName: 'workflow_security',
      stepName: 'security',
      actionName: 'signin',
      body: {'username': username, 'password': password},
    );
    return workflowJson(request: request, lambdaName: 'workflow_security_js');
  }

  // ─── Utilidades internas ──────────────────────────────────────────────

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map) return [data];
    return [];
  }
}
