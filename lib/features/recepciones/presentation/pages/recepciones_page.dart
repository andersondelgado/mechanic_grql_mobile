import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/recepciones_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class RecepcionesPage extends HookConsumerWidget {
  const RecepcionesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recepcionesState = ref.watch(recepcionesProvider);
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Órdenes de Trabajo' : 'Mis Órdenes',
          style: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: () {
                context.push('/recepciones/nueva');
              },
            ),
        ],
      ),
      body: recepcionesState.when(
        data: (recepciones) {
          if (recepciones.isEmpty) {
            return const Center(
              child: Text(
                'No hay órdenes registradas',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(recepcionesProvider.notifier).fetchRecepciones(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recepciones.length,
              itemBuilder: (context, index) {
                final rec = recepciones[index];
                return Card(
                  color: AppColors.cardColor,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(
                        rec.status,
                      ).withValues(alpha: 0.1),
                      child: Icon(
                        Icons.receipt_long,
                        color: _getStatusColor(rec.status),
                      ),
                    ),
                    title: Text(
                      'Orden #${rec.id != null && rec.id!.length >= 8 ? rec.id!.substring(0, 8) : (rec.id ?? 'N/A')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado: ${rec.status}',
                          style: TextStyle(
                            color: _getStatusColor(rec.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (rec.licensePlate != null)
                          Text(
                            'Placa: ${rec.licensePlate} - ${rec.brand ?? ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    isThreeLine: true,
                    onTap: () {
                      // context.push('/recepciones/${rec.id}');
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pendiente':
        return AppColors.warning;
      case 'in_progress':
      case 'en progreso':
        return AppColors.primary;
      case 'completed':
      case 'completado':
        return AppColors.success;
      default:
        return AppColors.secondary;
    }
  }
}
