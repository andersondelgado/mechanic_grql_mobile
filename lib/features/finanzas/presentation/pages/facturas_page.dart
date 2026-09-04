import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/facturas_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FacturasPage extends HookConsumerWidget {
  const FacturasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facturasState = ref.watch(facturasProvider);
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAdmin ? 'Facturación' : 'Mis Facturas',
            style: const TextStyle(
                color: AppColors.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: () {},
            ),
        ],
      ),
      body: facturasState.when(
        data: (facturas) {
          if (facturas.isEmpty) {
            return const Center(
                child: Text('No hay facturas registradas',
                    style: TextStyle(color: AppColors.textSecondary)));
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(facturasProvider.notifier).fetchFacturas(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: facturas.length,
              itemBuilder: (context, index) {
                final factura = facturas[index];
                return Card(
                  color: AppColors.cardColor,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFF1F5F9))),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                      child:
                          const Icon(Icons.receipt, color: AppColors.success),
                    ),
                    title: Text(factura.noteNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Fecha: ${factura.noteDate?.substring(0, 10) ?? 'N/A'}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        if (factura.clientName != null && isAdmin)
                          Text('Cliente: ${factura.clientName}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                      ],
                    ),
                    trailing: Text(
                      factura.total != null
                          ? '\$${factura.total!.toStringAsFixed(2)}'
                          : 'N/A',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16),
                    ),
                    isThreeLine: isAdmin && factura.clientName != null,
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
