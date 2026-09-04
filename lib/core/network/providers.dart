import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'api_client.dart';

/// Proveedor global para el cliente API
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
