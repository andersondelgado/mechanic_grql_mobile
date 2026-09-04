import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/clientes_provider.dart';

class ClientesPage extends HookConsumerWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesState = ref.watch(clientesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clientes', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: () {
              context.push('/clientes/nuevo');
            },
          ),
        ],
      ),
      body: clientesState.when(
        data: (clientes) {
          if (clientes.isEmpty) {
            return const Center(child: Text('No hay clientes registrados', style: TextStyle(color: AppColors.textSecondary)));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(clientesProvider.notifier).fetchClientes(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];
                return Card(
                  color: AppColors.cardColor,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(cliente.nombre.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(cliente.nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    subtitle: Text(cliente.telefono, style: const TextStyle(color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      context.push('/clientes/${cliente.id}/editar', extra: cliente);
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
              const SizedBox(height: 16),
              const Text('Error al cargar clientes', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
              Text(error.toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(clientesProvider.notifier).fetchClientes(),
                child: const Text('Reintentar'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

