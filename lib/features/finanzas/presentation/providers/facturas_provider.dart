import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../models/factura.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/network/workflow_types.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final facturasProvider =
    StateNotifierProvider<FacturasNotifier, AsyncValue<List<Factura>>>((ref) {
      final apiClient = ref.read(apiClientProvider);
      final user = ref.read(authProvider).user;
      return FacturasNotifier(
        apiClient,
        user?.role == 'client' ? user?.clientsFkId : null,
      );
    });

class FacturasNotifier extends StateNotifier<AsyncValue<List<Factura>>> {
  final ApiClient _apiClient;
  final String? _clientsFkIdFilter;

  FacturasNotifier(this._apiClient, this._clientsFkIdFilter)
    : super(const AsyncValue.loading()) {
    fetchFacturas();
  }

  Future<void> fetchFacturas() async {
    state = const AsyncValue.loading();
    try {
      final query = _clientsFkIdFilter != null
          ? WorkflowQuery(filter: {'clients_fk_id': _clientsFkIdFilter})
          : null;

      final data = await _apiClient.getEntity(
        'GestionTallerProd_delivery_notes',
        query: query,
      );
      final list = data.map((json) => Factura.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
