import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/cliente.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/clientes_provider.dart';

class ClienteFormPage extends HookConsumerWidget {
  final Cliente? cliente;
  
  const ClienteFormPage({super.key, this.cliente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final isEditing = cliente != null;
    
    // Controladores
    final nombreController = TextEditingController(text: cliente?.nombre ?? '');
    final ciController = TextEditingController(text: cliente?.ci ?? '');
    final telefonoController = TextEditingController(text: cliente?.telefono ?? '');
    final emailController = TextEditingController(text: cliente?.email ?? '');
    final direccionController = TextEditingController(text: cliente?.direccion ?? '');

    Future<void> saveCliente() async {
      if (formKey.currentState!.validate()) {
        final newCliente = Cliente(
          id: cliente?.id,
          nombre: nombreController.text,
          ci: ciController.text,
          telefono: telefonoController.text,
          email: emailController.text.isNotEmpty ? emailController.text : null,
          direccion: direccionController.text.isNotEmpty ? direccionController.text : null,
        );

        try {
          if (isEditing) {
            await ref.read(clientesProvider.notifier).updateCliente(newCliente);
          } else {
            await ref.read(clientesProvider.notifier).addCliente(newCliente);
          }
          if (context.mounted) {
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cliente guardado exitosamente'), backgroundColor: AppColors.success),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
            );
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.secondary),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Eliminar Cliente'),
                    content: const Text('¿Está seguro de eliminar este cliente?'),
                    actions: [
                      TextButton(onPressed: () => context.pop(false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => context.pop(true), child: const Text('Eliminar', style: TextStyle(color: AppColors.danger))),
                    ],
                  ),
                );
                
                if (confirm == true && context.mounted) {
                  try {
                    await ref.read(clientesProvider.notifier).deleteCliente(cliente!.id!);
                    if (context.mounted) {
                      context.pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
                    }
                  }
                }
              },
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField('Nombre Completo *', nombreController, required: true),
              const SizedBox(height: 16),
              _buildTextField('Cédula / NIT *', ciController, required: true),
              const SizedBox(height: 16),
              _buildTextField('Teléfono *', telefonoController, required: true, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField('Correo Electrónico', emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField('Dirección', direccionController, maxLines: 2),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: saveCliente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEditing ? 'Guardar Cambios' : 'Registrar Cliente', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
          validator: required ? (value) => value == null || value.isEmpty ? 'Este campo es requerido' : null : null,
        ),
      ],
    );
  }
}
