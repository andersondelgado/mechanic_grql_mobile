import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workflow_types.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  
  // Constantes extraidas del proyecto web (config.ts)
  static const String baseUrl = 'https://db-grql.com';
  static const String dbLambdas = 'codeLambdas'; // de la web config.ts
  static const String apiKey = '68c4d2d7-31b6-455b-9d41-4c6e9491fb17'; // hardcodeado provisional o usar env
  
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        
        // Emular cliente web
        options.headers['x-grql-auth'] = apiKey;
        
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        final lambdaToken = prefs.getString('lambdaToken');
        if (lambdaToken != null) {
          options.headers['X-Grql-Lambda'] = lambdaToken;
        }

        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.remove('lambdaToken');
          // TODO: Trigger navigation to login
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  /// Ejecuta un workflow JSON simulando la funcion `workflowJson` de TS
  Future<Map<String, dynamic>> workflowJson({
    required WorkflowRequest request,
    String lambdaId = '6d033980-4806-4e69-a3e8-a5f8f86d4cec', // ID decodificado de workflow_taller_js
    String workspace = 'lambda',
  }) async {
    final url = '/api/secure-rQL/lambdas-json-run-node?db=$dbLambdas&table=$workspace&id=$lambdaId&format=json';
    
    // Nota: El manejo de cache de "query" se podria implementar aqui en el futuro con un local database o hive.
    try {
      final response = await _dio.post(url, data: request.toJson());
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Helpers CRUD de alto nivel (como en web/src/api/client.ts)
  
  Future<List<dynamic>> getEntity(String table, {Map<String, dynamic>? query}) async {
    final request = buildQueryRequest(
      flowName: 'workflow_taller',
      stepName: table,
      actionName: 'get',
      params: {
        'pagination': {'page': 1, 'size': 100},
        if (query != null) ...query,
      }
    );
    final response = await workflowJson(request: request);
    return _extractData(response);
  }

  Future<dynamic> createEntity(String table, Map<String, dynamic> data) async {
    final request = buildMutationRequest(
      flowName: 'workflow_taller',
      stepName: table,
      actionName: 'create',
      params: {'body': data}
    );
    final response = await workflowJson(request: request);
    return _extractFirst(response);
  }

  Future<dynamic> updateEntity(String table, String id, Map<String, dynamic> data) async {
    final request = buildMutationRequest(
      flowName: 'workflow_taller',
      stepName: table,
      actionName: 'putById',
      params: {
        'body': {...data, 'id': id},
        'path': {'id': id}
      }
    );
    final response = await workflowJson(request: request);
    return _extractFirst(response);
  }

  Future<void> deleteEntity(String table, String id) async {
    final request = buildMutationRequest(
      flowName: 'workflow_taller',
      stepName: table,
      actionName: 'deleteById',
      params: {
        'path': {'id': id}
      }
    );
    await workflowJson(request: request);
  }

  /// Extrae el 'content' del primer resultado del workflow
  List<dynamic> _extractData(Map<String, dynamic> response) {
    try {
      return response['response'][0]['actions'][0]['result']['content'] as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  /// Extrae el primer elemento del content (util para create/update)
  dynamic _extractFirst(Map<String, dynamic> response) {
    final data = _extractData(response);
    return data.isNotEmpty ? data.first : null;
  }
}
