import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState(isLoading: true)) {
    checkSession();
  }

  Future<void> checkSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final lambdaToken = prefs.getString('lambdaToken');
      
      // MOCK: Obtener usuario almacenado si existiese
      final username = prefs.getString('username');
      final role = prefs.getString('role');
      
      if (token != null && lambdaToken != null && role != null) {
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: UserModel(
            id: 'mock_id',
            username: username ?? 'Usuario',
            role: role,
            clientsFkId: prefs.getString('clientsFkId'),
          ),
        );
      } else {
        state = state.copyWith(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isAuthenticated: false, isLoading: false, error: e.toString());
    }
  }

  Future<void> login(String username, String password, {bool isAdminLogin = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Simulacion de llamada al Security Lambda
      // En un entorno real llamariamos a workflow_security (signin)
      /*
      final request = buildMutationRequest(
        flowName: 'workflow_security',
        stepName: 'security',
        actionName: 'signin',
        params: {'body': {'username': username, 'password': password}},
      );
      final response = await apiClient.workflowJson(request: request, lambdaId: 'id_de_seguridad');
      */

      // Simulamos la respuesta basándonos en si marcamos el checkbox "Admin" o no.
      await Future.delayed(const Duration(seconds: 1)); // Falso retardo
      
      final String role = isAdminLogin ? 'admin' : 'client';
      final String clientsFkId = isAdminLogin ? '' : 'CL-001'; // ID del cliente si es client

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'mock_jwt_token_123');
      await prefs.setString('lambdaToken', 'mock_lambda_token_456');
      await prefs.setString('username', username);
      await prefs.setString('role', role);
      if (!isAdminLogin) {
        await prefs.setString('clientsFkId', clientsFkId);
      }

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: UserModel(
          id: 'mock_id',
          username: username,
          role: role,
          clientsFkId: isAdminLogin ? null : clientsFkId,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Credenciales inválidas o error de red');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = AuthState(isAuthenticated: false, isLoading: false);
  }
}
