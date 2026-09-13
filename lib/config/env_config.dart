/// Configuración centralizada y fuertemente tipada para la aplicación Flutter.
/// Los valores se inyectan en tiempo de compilación o depuración mediante
/// `--dart-define-from-file=env.json` o `--dart-define=KEY=VALUE`.
class EnvConfig {
  EnvConfig._();

  /// URL Base de la API gRQL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://db-grql.com',
  );

  /// URL del WebSocket
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://db-grql.com',
  );

  /// Clave de autenticación gRQL (X-Grql-Auth)
  static const String apiKey = String.fromEnvironment(
    'GRQL_API_KEY',
    defaultValue: '',
  );

  /// Lambda IDs codificados en Base64
  static const String lambdaCompose = String.fromEnvironment(
    'LAMBDA_COMPOSE',
    defaultValue: '',
  );

  /// Nombre de la base de datos principal
  static const String dbName = String.fromEnvironment(
    'DB_NAME',
    defaultValue: 'GestionTallerProd',
  );

  /// Nombre de la base de datos de Lambdas
  static const String dbLambdas = String.fromEnvironment(
    'DB_LAMBDAS',
    defaultValue: 'codeLambdas',
  );

  /// Propietario por defecto
  static const String defaultOwner = String.fromEnvironment(
    'DEFAULT_OWNER',
    defaultValue: '50735380-0_urbaezmotors',
  );

  /// Ambiente de ejecución: 'development', 'staging', 'production'
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Bandera booleana de producción
  static const bool isProduction = bool.fromEnvironment(
    'IS_PRODUCTION',
    defaultValue: false,
  );

  /// Habilitar logs en consola
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );

  /// Timeout de conexión en segundos (int)
  static const int connectTimeoutSeconds = int.fromEnvironment(
    'CONNECT_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  /// Timeout de recepción en segundos (int)
  static const int receiveTimeoutSeconds = int.fromEnvironment(
    'RECEIVE_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  /// Endpoint base de servicios seguros gRQL
  static String get apiBase => '$apiBaseUrl/api/secure-rQL';

  /// Endpoint para ejecución de lambdas Node
  static String get lambdaEndpointNode => '$apiBase/lambdas-json-run-node';
}
