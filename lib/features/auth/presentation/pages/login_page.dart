import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isAdmin = useState(false);
    final formKey = GlobalKey<FormState>();

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        context.go('/');
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.error!), backgroundColor: AppColors.danger),
        );
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF60A5FA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 24,
                shadowColor: Colors.black.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                color: Colors.white.withValues(alpha: 0.95),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.car_repair,
                              size: 64, color: AppColors.primary),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Taller Integrale\$',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondary,
                              letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Plataforma de Gestión Automotriz',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.surfaceLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ingreso Administrativo',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                              Switch(
                                value: isAdmin.value,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) => isAdmin.value = val,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              shadowColor:
                                  AppColors.primary.withValues(alpha: 0.4),
                            ),
                            onPressed: authState.isLoading
                                ? null
                                : () {
                                    if (formKey.currentState!.validate()) {
                                      ref.read(authProvider.notifier).login(
                                            usernameController.text,
                                            passwordController.text,
                                            isAdminLogin: isAdmin.value,
                                          );
                                    }
                                  },
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5))
                                : const Text('INICIAR SESIÓN',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
