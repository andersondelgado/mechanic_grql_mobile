import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/network/providers.dart';
import '../../../../models/cliente.dart';
import '../../../../core/network/api_client.dart';

final clientesProvider = StateNotifierProvider<ClientesNotifier, AsyncValue<List<Cliente>>>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ClientesNotifier(apiClient);
});

class ClientesNotifier extends StateNotifier<AsyncValue<List<Cliente>>> {
  final ApiClient _apiClient;
  
  ClientesNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchClientes();
  }

  Future<void> fetchClientes() async {
    state = const AsyncValue.loading();
    try {
      final data = await _apiClient.getEntity('GestionTallerProd_clients');
      final clientes = data.map((json) => Cliente.fromJson(json)).toList();
      state = AsyncValue.data(clientes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCliente(Cliente cliente) async {
    try {
      final jsonResponse = await _apiClient.createEntity('GestionTallerProd_clients', cliente.toJson());
      if (jsonResponse != null) {
        final newCliente = Cliente.fromJson(jsonResponse);
        if (state.hasValue) {
          state = AsyncValue.data([newCliente, ...state.value!]);
        } else {
          state = AsyncValue.data([newCliente]);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCliente(Cliente cliente) async {
    if (cliente.id == null) return;
    try {
      final jsonResponse = await _apiClient.updateEntity('GestionTallerProd_clients', cliente.id!, cliente.toJson());
      if (jsonResponse != null && state.hasValue) {
        final updated = Cliente.fromJson(jsonResponse);
        final newList = state.value!.map((c) => c.id == updated.id ? updated : c).toList();
        state = AsyncValue.data(newList);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCliente(String id) async {
    try {
      await _apiClient.deleteEntity('GestionTallerProd_clients', id);
      if (state.hasValue) {
        final newList = state.value!.where((c) => c.id != id).toList();
        state = AsyncValue.data(newList);
      }
    } catch (e) {
      rethrow;
    }
  }
}
