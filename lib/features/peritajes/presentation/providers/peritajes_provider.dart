import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../models/peritaje.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final peritajesProvider = StateNotifierProvider<PeritajesNotifier, AsyncValue<List<Peritaje>>>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final user = ref.read(authProvider).user;
  return PeritajesNotifier(apiClient, user?.role == 'client' ? user?.clientsFkId : null);
});

class PeritajesNotifier extends StateNotifier<AsyncValue<List<Peritaje>>> {
  final ApiClient _apiClient;
  final String? _clientsFkIdFilter;
  
  PeritajesNotifier(this._apiClient, this._clientsFkIdFilter) : super(const AsyncValue.loading()) {
    fetchPeritajes();
  }

  Future<void> fetchPeritajes() async {
    state = const AsyncValue.loading();
    try {
      // Nota: Si la lambda no soporta JOIN nativo de clients_fk_id a traves de vehicles, 
      // se necesitaria primero buscar los vehiculos y luego hacer un arrayFilter por vehicles_fk_id.
      // Asumimos que la lambda tiene soporte para resolver clients_fk_id.
      final query = _clientsFkIdFilter != null 
          ? {'filter': {'clients_fk_id': _clientsFkIdFilter}} 
          : null;
          
      final data = await _apiClient.getEntity('GestionTallerProd_inspection_cards', query: query);
      final list = data.map((json) => Peritaje.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPeritaje(Peritaje peritaje) async {
    try {
      final jsonResponse = await _apiClient.createEntity('GestionTallerProd_inspection_cards', peritaje.toJson());
      if (jsonResponse != null) {
        final newPer = Peritaje.fromJson(jsonResponse);
        if (state.hasValue) {
          state = AsyncValue.data([newPer, ...state.value!]);
        } else {
          state = AsyncValue.data([newPer]);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
