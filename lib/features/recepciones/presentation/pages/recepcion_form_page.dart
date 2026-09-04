import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/vehiculo.dart';
import '../../../../core/widgets/searchable_dropdown.dart';

class RecepcionFormPage extends HookConsumerWidget {
  const RecepcionFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleIdNotifier = ValueNotifier<String?>(null);
    final ownerNameController = TextEditingController();
    final ownerPhoneController = TextEditingController();
    final observationsController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nueva Ficha de Recepción',
            style: TextStyle(
                color: AppColors.secondary, fontWeight: FontWeight.bold)),
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
                  offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchableDropdown<Vehiculo>(
                label: 'ID del Vehículo *',
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
              const Text('Propietario / Cliente',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.secondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: ownerNameController,
                decoration: InputDecoration(
                  hintText: 'Nombre de quien entrega',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 20),
              const Text('Teléfono',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.secondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: ownerPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '0414-XXXXXXX',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 20),
              const Text('Observaciones',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.secondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: observationsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Rayones, estado general al recibir...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
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
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // TODO: Implementar lógica de guardado llamando al provider
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Guardado correctamente')));
                    context.pop();
                  },
                  child: const Text('Guardar Ficha',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
