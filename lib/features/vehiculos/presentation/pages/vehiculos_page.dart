import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/vehiculos_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class VehiculosPage extends HookConsumerWidget {
  const VehiculosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiculosState = ref.watch(vehiculosProvider);
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAdmin ? 'Vehículos' : 'Mis Autos',
            style: const TextStyle(
                color: AppColors.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: () {
                // context.push('/vehiculos/nuevo');
              },
            ),
        ],
      ),
      body: vehiculosState.when(
        data: (vehiculos) {
          if (vehiculos.isEmpty) {
            return const Center(
                child: Text('No hay vehículos registrados',
                    style: TextStyle(color: AppColors.textSecondary)));
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(vehiculosProvider.notifier).fetchVehiculos(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehiculos.length,
              itemBuilder: (context, index) {
                final veh = vehiculos[index];
                return Card(
                  color: AppColors.cardColor,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFF1F5F9))),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.directions_car,
                          color: AppColors.primary),
                    ),
                    title: Text('${veh.brand ?? 'Vehículo'} ${veh.model ?? ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Placa: ${veh.licensePlate}',
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        if (veh.clientName != null)
                          Text('Cliente: ${veh.clientName}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                      ],
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      // context.push('/vehiculos/${veh.id}');
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: AppColors.danger))),
      ),
    );
  }
}
