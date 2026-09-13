import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/vehiculo.dart';
import '../../../../models/cliente.dart';
import '../../../../models/peritaje.dart';
import '../../../../core/widgets/searchable_dropdown.dart';
import '../providers/peritajes_provider.dart';

class PeritajeFormPage extends HookConsumerWidget {
  const PeritajeFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleIdNotifier = ValueNotifier<String?>(null);
    final clientIdNotifier = ValueNotifier<String?>(null);
    final inspectionTypeController = TextEditingController();
    final observationsController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Nueva Inspección',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.secondary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchableDropdown<Vehiculo>(
                label: 'ID Vehículo *',
                hintText: 'Buscar por placa o marca...',
                table: 'GestionTallerProd_vehicles',
                fromJson: (json) => Vehiculo.fromJson(json),
                displayStringForOption: (Vehiculo veh) =>
                    '${veh.licensePlate} - ${veh.brand ?? ''} ${veh.model ?? ''}'
                        .trim(),
                searchFilter: (Vehiculo veh, String query) {
                  final q = query.toLowerCase();
                  return veh.licensePlate.toLowerCase().contains(q) ||
                      (veh.brand?.toLowerCase().contains(q) ?? false) ||
                      (veh.model?.toLowerCase().contains(q) ?? false);
                },
                onSelected: (Vehiculo? veh) {
                  vehicleIdNotifier.value = veh?.id;
                },
              ),
              const SizedBox(height: 20),
              SearchableDropdown<Cliente>(
                label: 'ID Cliente *',
                hintText: 'Buscar por nombre o documento...',
                table: 'GestionTallerProd_clients',
                fromJson: (json) {
                  // Ajuste: si el JSON de api trae client_name o tax_id en vez de nombre/ci, el factory de Cliente ya lo procesa
                  return Cliente.fromJson(json);
                },
                displayStringForOption: (Cliente cli) =>
                    '${cli.nombre} - ${cli.ci}'.trim(),
                searchFilter: (Cliente cli, String query) {
                  final q = query.toLowerCase();
                  return cli.nombre.toLowerCase().contains(q) ||
                      cli.ci.toLowerCase().contains(q);
                },
                onSelected: (Cliente? cli) {
                  clientIdNotifier.value = cli?.id;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Tipo de Inspección',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: inspectionTypeController,
                decoration: InputDecoration(
                  hintText: 'Revisión mecánica, latonería, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Observaciones',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: observationsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Escribe aquí las notas generales del vehículo...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (vehicleIdNotifier.value == null ||
                        clientIdNotifier.value == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debe seleccionar Vehículo y Cliente'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }
                    try {
                      final newPeritaje = Peritaje(
                        vehiclesFkId: vehicleIdNotifier.value!,
                        clientsFkId: clientIdNotifier.value,
                        inspectionType:
                            inspectionTypeController.text.trim().isNotEmpty
                            ? inspectionTypeController.text.trim()
                            : 'general',
                        inspectionDate: DateTime.now().toIso8601String(),
                        observations:
                            observationsController.text.trim().isNotEmpty
                            ? observationsController.text.trim()
                            : null,
                        status: 'pending',
                      );

                      final created = await ref
                          .read(peritajesProvider.notifier)
                          .addPeritaje(newPeritaje);

                      if (context.mounted) {
                        if (created != null && created.id != null) {
                          context.pushReplacement(
                            '/peritajes/camara',
                            extra: created,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Peritaje guardado en la Lambda'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          context.pop();
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al guardar: $e'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Continuar a Grabación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
