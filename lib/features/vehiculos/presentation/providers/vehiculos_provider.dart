import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../models/vehiculo.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final vehiculosProvider = StateNotifierProvider<VehiculosNotifier, AsyncValue<List<Vehiculo>>>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final user = ref.read(authProvider).user;
  return VehiculosNotifier(apiClient, user?.role == 'client' ? user?.clientsFkId : null);
});

class VehiculosNotifier extends StateNotifier<AsyncValue<List<Vehiculo>>> {
  final ApiClient _apiClient;
  final String? _clientsFkIdFilter;
  
  VehiculosNotifier(this._apiClient, this._clientsFkIdFilter) : super(const AsyncValue.loading()) {
    fetchVehiculos();
  }

  Future<void> fetchVehiculos() async {
    state = const AsyncValue.loading();
    try {
      final query = _clientsFkIdFilter != null 
          ? {'filter': {'clients_fk_id': _clientsFkIdFilter}} 
          : null;
          
      final data = await _apiClient.getEntity('GestionTallerProd_vehicles', query: query);
      final list = data.map((json) => Vehiculo.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addVehiculo(Vehiculo vehiculo) async {
    try {
      final jsonResponse = await _apiClient.createEntity('GestionTallerProd_vehicles', vehiculo.toJson());
      if (jsonResponse != null) {
        final newVeh = Vehiculo.fromJson(jsonResponse);
        if (state.hasValue) {
          state = AsyncValue.data([newVeh, ...state.value!]);
        } else {
          state = AsyncValue.data([newVeh]);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
