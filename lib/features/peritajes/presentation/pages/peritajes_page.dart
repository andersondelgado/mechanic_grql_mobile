import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/peritaje.dart';
import '../providers/peritajes_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PeritajesPage extends HookConsumerWidget {
  const PeritajesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peritajesState = ref.watch(peritajesProvider);
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAdmin ? 'Peritajes' : 'Resultados de Inspección',
            style: const TextStyle(
                color: AppColors.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.video_call, color: AppColors.primary),
              tooltip: 'Nuevo Video Análisis',
              onPressed: () {
                context.push('/peritajes/nuevo');
              },
            ),
        ],
      ),
      body: peritajesState.when(
        data: (peritajes) {
          if (peritajes.isEmpty) {
            return const Center(
                child: Text('No hay peritajes registrados',
                    style: TextStyle(color: AppColors.textSecondary)));
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(peritajesProvider.notifier).fetchPeritajes(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: peritajes.length,
              itemBuilder: (context, index) {
                final peritaje = peritajes[index];
                return Card(
                  color: AppColors.cardColor,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFF1F5F9))),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: peritaje.checkYes
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.danger.withValues(alpha: 0.1),
                      child: Icon(
                        peritaje.checkYes
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        color: peritaje.checkYes
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                    title: Text(peritaje.itemName ?? 'Inspección',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Fecha: ${peritaje.inspectionDate?.substring(0, 10) ?? 'N/A'}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        if (peritaje.observations != null)
                          Text(peritaje.observations!,
                              style: const TextStyle(
                                  fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    isThreeLine: true,
                    onTap: () {
                      // context.push('/peritajes/${peritaje.id}');
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
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                final dummyPeritaje =
                    Peritaje(vehiclesFkId: 'V-001', inspectionType: 'general');
                context.push('/peritajes/camara', extra: dummyPeritaje);
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text('Grabar Peritaje',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
