import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../models/repuesto.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/providers.dart';

final inventarioProvider = StateNotifierProvider<InventarioNotifier, AsyncValue<List<Repuesto>>>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return InventarioNotifier(apiClient);
});

class InventarioNotifier extends StateNotifier<AsyncValue<List<Repuesto>>> {
  final ApiClient _apiClient;
  
  InventarioNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchRepuestos();
  }

  Future<void> fetchRepuestos() async {
    state = const AsyncValue.loading();
    try {
      final data = await _apiClient.getEntity('GestionTallerProd_parts_catalog');
      final list = data.map((json) => Repuesto.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
