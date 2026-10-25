import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/network/workflow_types.dart';
import '../../../../models/vehiculo.dart';
import '../../../../models/cliente.dart';

class ConsultaClientePage extends ConsumerStatefulWidget {
  const ConsultaClientePage({super.key});

  @override
  ConsumerState<ConsultaClientePage> createState() => _ConsultaClientePageState();
}

class _ConsultaClientePageState extends ConsumerState<ConsultaClientePage> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    if (!_formKey.currentState!.validate()) return;

    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(apiClientProvider);

      // 1. Intentar buscar por Placa
      final vehicleMatches = await client.searchVehiclesByPlate(query);
      if (vehicleMatches.isNotEmpty) {
        final vehData = vehicleMatches.first;
        final veh = Vehiculo.fromJson(vehData);

        // Buscar cliente asociado al vehículo
        Cliente? cli;
        if (veh.clientsFkId.isNotEmpty) {
          final cliData = await client.getEntityById('GestionTallerProd_clients', veh.clientsFkId);
          if (cliData != null) {
            cli = Cliente.fromJson(cliData);
          }
        }

        if (mounted) {
          context.push('/portal-cliente', extra: {
            'vehicle': veh,
            'client': cli,
          });
        }
        return;
      }

      // 2. Si no se encontró por placa, intentar buscar por Documento / Cédula / RIF o Nombre
      final clientMatches = await client.searchClientsByTaxId(query);
      if (clientMatches.isNotEmpty) {
        final cliData = clientMatches.first;
        final cli = Cliente.fromJson(cliData);
        final cliId = cli.id;

        // Buscar vehículos del cliente
        Vehiculo? veh;
        if (cliId != null && cliId.isNotEmpty) {
          final allVehs = await client.getEntity(
            'GestionTallerProd_vehicles',
            query: WorkflowQuery(pagination: {'page': 1, 'size': 500}),
          );
          final clientVehs = allVehs.where((v) {
            if (v is! Map) return false;
            final cFk = (v['clients_fk_id'] ?? '').toString();
            return cFk == cliId;
          }).toList();

          if (clientVehs.isNotEmpty) {
            veh = Vehiculo.fromJson((clientVehs.first as Map).cast<String, dynamic>());
          }
        }

        // Fallback: Si no se encontró en vehicles, buscar en recepciones
        if (veh == null) {
          final allReceipts = await client.getEntity(
            'GestionTallerProd_vehicle_receipts',
            query: WorkflowQuery(pagination: {'page': 1, 'size': 200}),
          );
          final cleanDoc = query.trim().toLowerCase().replaceAll('.', '').replaceAll('-', '');
          for (final r in allReceipts) {
            if (r is! Map) continue;
            final rTax = (r['owner_tax_id'] ?? '').toString().trim().toLowerCase().replaceAll('.', '').replaceAll('-', '');
            final rVehList = r['vehicles'];
            if (rVehList is List && rVehList.isNotEmpty) {
              final vMap = (rVehList.first as Map).cast<String, dynamic>();
              final vFk = (vMap['clients_fk_id'] ?? '').toString();
              if (vFk == cliId || (rTax.isNotEmpty && (rTax.contains(cleanDoc) || cleanDoc.contains(rTax)))) {
                veh = Vehiculo.fromJson(vMap);
                break;
              }
            }
          }
        }

        if (veh == null) {
          setState(() {
            _errorMessage =
                'El cliente "${cli.nombre}" no tiene vehículos asociados registrados en el sistema.';
          });
          return;
        }

        if (mounted) {
          context.push('/portal-cliente', extra: {
            'vehicle': veh,
            'client': cli,
          });
        }
        return;
      }

      // 3. Fallback: Buscar directamente en Fichas de Recepción
      final allReceipts = await client.getEntity(
        'GestionTallerProd_vehicle_receipts',
        query: WorkflowQuery(pagination: {'page': 1, 'size': 200}),
      );
      final clean = query.trim().toUpperCase().replaceAll(' ', '').replaceAll('.', '').replaceAll('-', '');
      for (final r in allReceipts) {
        if (r is! Map) continue;
        final plate = (r['license_plate'] ?? '').toString().trim().toUpperCase().replaceAll(' ', '').replaceAll('-', '');
        final taxId = (r['owner_tax_id'] ?? '').toString().trim().toUpperCase().replaceAll(' ', '').replaceAll('.', '').replaceAll('-', '');
        final ownerName = (r['owner_name'] ?? '').toString().trim().toUpperCase();

        if ((plate.isNotEmpty && (plate.contains(clean) || clean.contains(plate))) ||
            (taxId.isNotEmpty && (taxId.contains(clean) || clean.contains(taxId))) ||
            (ownerName.isNotEmpty && ownerName.contains(clean))) {
          Vehiculo? veh;
          final rVehList = r['vehicles'];
          if (rVehList is List && rVehList.isNotEmpty) {
            veh = Vehiculo.fromJson((rVehList.first as Map).cast<String, dynamic>());
          } else {
            veh = Vehiculo(
              id: (r['vehicles_fk_id'] ?? '').toString(),
              clientsFkId: '',
              licensePlate: (r['license_plate'] ?? query).toString(),
              brand: r['brand']?.toString(),
              model: r['model']?.toString(),
              color: r['color']?.toString(),
            );
          }

          Cliente? cli;
          final rCliList = (rVehList is List && rVehList.isNotEmpty && rVehList.first is Map)
              ? (rVehList.first as Map)['clients']
              : null;
          if (rCliList is List && rCliList.isNotEmpty) {
            cli = Cliente.fromJson((rCliList.first as Map).cast<String, dynamic>());
          } else {
            cli = Cliente(
              nombre: (r['owner_name'] ?? 'Cliente').toString(),
              ci: (r['owner_tax_id'] ?? query).toString(),
              telefono: (r['phone'] ?? '').toString(),
            );
          }

          if (mounted) {
            context.push('/portal-cliente', extra: {
              'vehicle': veh,
              'client': cli,
            });
          }
          return;
        }
      }

      // Si no hubo coincidencias
      setState(() {
        _errorMessage =
            'No se encontraron vehículos o registros activos para "$query". Verifique que la placa o cédula estén escritas correctamente.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión al consultar el sistema: $e';
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar con botón de volver al login
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      tooltip: 'Volver al Inicio',
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Portal Seguro de Consulta',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido Central
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icono y Título
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.directions_car_filled_rounded,
                              size: 52,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Estado de tu Vehículo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Consulta en tiempo real la ficha de recepción, presupuesto e informe de peritaje con IA sin necesidad de registrarte.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Tarjeta de Búsqueda
                          Card(
                            elevation: 12,
                            shadowColor: Colors.black.withValues(alpha: 0.4),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'INGRESA TU PLACA O CÉDULA',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF475569),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Input
                                    TextFormField(
                                      controller: _searchController,
                                      textCapitalization: TextCapitalization.characters,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        color: Color(0xFF0F172A),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Ej. AA640AR ó V-13420735',
                                        hintStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                          letterSpacing: 0,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.search_rounded,
                                          color: AppColors.primary,
                                        ),
                                        suffixIcon: _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear, color: Colors.grey),
                                                onPressed: () {
                                                  setState(() {
                                                    _searchController.clear();
                                                    _errorMessage = null;
                                                  });
                                                },
                                              )
                                            : null,
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Por favor ingrese su placa o documento';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _handleSearch(),
                                    ),
                                    const SizedBox(height: 8),

                                    // Chips de ejemplo rápido
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        _quickChip('AA640AR', 'Placa de ejemplo'),
                                        _quickChip('V-13420735', 'Cédula de ejemplo'),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Mensaje de Error
                                    if (_errorMessage != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFFECACA)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: const TextStyle(
                                                  color: Color(0xFF991B1B),
                                                  fontSize: 12,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // Botón Buscar
                                    SizedBox(
                                      height: 52,
                                      child: ElevatedButton.icon(
                                        onPressed: _isSearching ? null : _handleSearch,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 4,
                                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                                        ),
                                        icon: _isSearching
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : const Icon(Icons.arrow_forward_rounded, size: 20),
                                        label: Text(
                                          _isSearching ? 'CONSULTANDO...' : 'CONSULTAR MI VEHÍCULO',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Enlace para volver a Login del Staff
                          TextButton.icon(
                            onPressed: () => context.go('/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF94A3B8),
                            ),
                            icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                            label: const Text(
                              '¿Eres empleado del taller? Iniciar sesión aquí',
                              style: TextStyle(fontSize: 12, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
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

  Widget _quickChip(String value, String tooltip) {
    return InkWell(
      onTap: () {
        setState(() {
          _searchController.text = value;
          _errorMessage = null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
