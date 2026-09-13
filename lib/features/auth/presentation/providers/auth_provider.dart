import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../../../core/network/providers.dart';

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

  /// Verifica si hay una sesión activa en SharedPreferences
  Future<void> checkSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final lambdaToken = prefs.getString('lambdaToken');
      final userJson = prefs.getString('user');

      if (token != null && lambdaToken != null && userJson != null) {
        try {
          final userMap = jsonDecode(userJson) as Map<String, dynamic>;
          state = state.copyWith(
            isAuthenticated: true,
            isLoading: false,
            user: UserModel.fromJson(userMap),
          );
        } catch (_) {
          // Token expirado o user corrupto
          await _clearSession();
          state = state.copyWith(isAuthenticated: false, isLoading: false);
        }
      } else {
        state = state.copyWith(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Login real contra workflow_security (equivalente a use-auth.tsx login)
  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ref.read(apiClientProvider);

      // Llamar a workflow_security → security → signin
      final response = await apiClient.signIn(username, password);

      final signinData = response['security']?['signin'];
      if (signinData == null || signinData['token'] == null) {
        final errorMsg =
            response['error'] ??
            'Login fallido: estructura de respuesta inválida';
        throw Exception(errorMsg);
      }

      final String token = signinData['token'] as String;

      // Decodificar JWT para extraer info del usuario (igual que use-auth.tsx)
      String userId = '';
      String role = 'admin';
      String? clientsFkId;
      try {
        final parts = token.split('.');
        if (parts.length >= 2) {
          var payload = parts[1];
          // Normalizar base64url
          payload = payload.replaceAll('-', '+').replaceAll('_', '/');
          // Agregar padding si es necesario
          while (payload.length % 4 != 0) {
            payload += '=';
          }
          final decoded = jsonDecode(utf8.decode(base64.decode(payload)));
          userId =
              decoded['userId']?.toString() ?? decoded['id']?.toString() ?? '';
          role =
              decoded['role']?.toString() ??
              decoded['rol']?.toString() ??
              'admin';
          clientsFkId =
              decoded['clients_fk_id']?.toString() ??
              decoded['clientsFkId']?.toString();
        }
      } catch (_) {
        // Si falla el decode, usar valores por defecto
      }

      // Guardar tokens (el token JWT se usa como lambdaToken, igual que en el web)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('lambdaToken', token);

      // Crear objeto usuario
      final user = UserModel(
        id: userId.isNotEmpty ? userId : 'admin',
        username: username,
        role: role,
        clientsFkId: clientsFkId,
      );

      // Guardar user como JSON para persistir entre sesiones
      await prefs.setString('user', jsonEncode(user.toJson()));

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Login mock para desarrollo (sin backend)
  Future<void> loginMock(String username, {bool isAdminLogin = true}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.delayed(const Duration(seconds: 1));

      final String role = isAdminLogin ? 'admin' : 'client';

      final user = UserModel(
        id: 'mock_id',
        username: username,
        role: role,
        clientsFkId: isAdminLogin ? null : 'CL-001',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'mock_jwt_token_123');
      await prefs.setString('lambdaToken', 'mock_lambda_token_456');
      await prefs.setString('user', jsonEncode(user.toJson()));

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Credenciales inválidas o error de red',
      );
    }
  }

  /// Cierra la sesión y limpia todo
  Future<void> logout() async {
    await _clearSession();
    state = AuthState(isAuthenticated: false, isLoading: false);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('lambdaToken');
    await prefs.remove('user');
    await prefs.remove('owner');
  }
}
