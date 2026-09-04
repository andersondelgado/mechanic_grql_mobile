import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardPage extends HookConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white24,
                              child: Text(
                                user?.username.substring(0, 1).toUpperCase() ??
                                    'U',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bienvenido de vuelta,',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                  Text(
                                    user?.username ?? 'Usuario',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Cerrar sesión',
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                },
              )
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen General',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary),
                  ),
                  const SizedBox(height: 16),

                  // Dashboard Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: isAdmin
                        ? [
                            _buildStatCard('Clientes', '124', Icons.people,
                                AppColors.primary),
                            _buildStatCard('Vehículos', '312',
                                Icons.directions_car, AppColors.success),
                            _buildStatCard('En Taller', '18',
                                Icons.build_circle, AppColors.warning),
                            _buildStatCard('Peritajes IA', '45',
                                Icons.psychology, const Color(0xFF8B5CF6)),
                          ]
                        : [
                            _buildStatCard('Mis Autos', '2',
                                Icons.directions_car, AppColors.primary),
                            _buildStatCard('En Proceso', '1',
                                Icons.build_circle, AppColors.warning),
                            _buildStatCard('Facturas', '3', Icons.receipt,
                                AppColors.success),
                            _buildStatCard('Alertas', '0', Icons.notifications,
                                const Color(0xFF8B5CF6)),
                          ],
                  ),

                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isAdmin
                              ? Icons.admin_panel_settings
                              : Icons.verified_user,
                          size: 48,
                          color: AppColors.primary.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAdmin
                              ? 'Plataforma Administrativa Activa'
                              : 'Conectado de forma segura',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.secondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toda tu información está protegida por nuestra arquitectura en la nube con cifrado integral.',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                    letterSpacing: -0.5),
              ),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
