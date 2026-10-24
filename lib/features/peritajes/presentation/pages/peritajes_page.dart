import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
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
        title: Text(
          isAdmin ? 'Peritajes y Evaluaciones IA' : 'Mis Peritajes',
          style: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.read(peritajesProvider.notifier).fetchPeritajes();
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              tooltip: 'Nueva Inspección',
              onPressed: () {
                context.push('/peritajes/nuevo');
              },
            ),
        ],
      ),
      body: peritajesState.when(
        data: (peritajes) {
          if (peritajes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.car_crash_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay peritajes registrados',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (isAdmin)
                    ElevatedButton.icon(
                      onPressed: () => context.push('/peritajes/nuevo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Primera Inspección'),
                    ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(peritajesProvider.notifier).fetchPeritajes(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: peritajes.length,
              itemBuilder: (context, index) {
                final peritaje = peritajes[index];
                final code = peritaje.code;
                final plate = peritaje.licensePlate ?? 'SIN PLACA';
                final client = peritaje.clientName ?? 'Cliente del Taller';
                final date = peritaje.inspectionDate != null && peritaje.inspectionDate!.length >= 10
                    ? peritaje.inspectionDate!.substring(0, 10)
                    : peritaje.inspectionDate ?? 'N/A';
                final hasSignature = peritaje.clientSignature != null && peritaje.clientSignature!.isNotEmpty;

                return Card(
                  color: AppColors.cardColor,
                  elevation: 1,
                  shadowColor: Colors.black.withValues(alpha: 0.04),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      context.push('/peritajes/informe', extra: peritaje);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Codigo, Placa, Estado
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  plate,
                                  style: const TextStyle(
                                    color: Color(0xFF1D4ED8),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (hasSignature)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.verified_rounded, size: 12, color: Color(0xFF15803D)),
                                      SizedBox(width: 3),
                                      Text(
                                        'Firmado',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Cliente & Vehículo
                          Text(
                            client,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Fecha: $date • Tipo: ${peritaje.inspectionType.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (peritaje.observations != null && peritaje.observations!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              peritaje.observations!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Action bar
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  context.push('/peritajes/informe', extra: peritaje);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.description_outlined, size: 16),
                                label: const Text('Ver Informe', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              if (isAdmin)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    context.push('/peritajes/camara', extra: peritaje);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF7E22CE),
                                    side: const BorderSide(color: Color(0xFFE9D5FF)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.videocam_rounded, size: 16),
                                  label: const Text('IA Video', style: TextStyle(fontSize: 12)),
                                ),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
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
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/peritajes/nuevo');
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nuevo Peritaje',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
