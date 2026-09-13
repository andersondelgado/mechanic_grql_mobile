import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../models/recepcion.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/network/workflow_types.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final recepcionesProvider =
    StateNotifierProvider<RecepcionesNotifier, AsyncValue<List<Recepcion>>>((
      ref,
    ) {
      final apiClient = ref.read(apiClientProvider);
      final user = ref.read(authProvider).user;
      return RecepcionesNotifier(
        apiClient,
        user?.role == 'client' ? user?.clientsFkId : null,
      );
    });

class RecepcionesNotifier extends StateNotifier<AsyncValue<List<Recepcion>>> {
  final ApiClient _apiClient;
  final String? _clientsFkIdFilter;

  RecepcionesNotifier(this._apiClient, this._clientsFkIdFilter)
    : super(const AsyncValue.loading()) {
    fetchRecepciones();
  }

  Future<void> fetchRecepciones() async {
    state = const AsyncValue.loading();
    try {
      final query = _clientsFkIdFilter != null
          ? WorkflowQuery(filter: {'clients_fk_id': _clientsFkIdFilter})
          : null;

      final data = await _apiClient.getEntity(
        'GestionTallerProd_vehicle_receipts',
        query: query,
      );
      final list = data.map((json) => Recepcion.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Recepcion?> addRecepcion(Recepcion recepcion) async {
    try {
      final jsonResponse = await _apiClient.createEntity(
        'GestionTallerProd_vehicle_receipts',
        recepcion.toJson(),
      );
      if (jsonResponse != null && jsonResponse is Map) {
        final newRec = Recepcion.fromJson(jsonResponse.cast<String, dynamic>());
        if (state.hasValue) {
          state = AsyncValue.data([newRec, ...state.value!]);
        } else {
          state = AsyncValue.data([newRec]);
        }
        return newRec;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
