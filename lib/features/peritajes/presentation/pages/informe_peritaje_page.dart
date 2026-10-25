import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/services/mobile_pdf_service.dart';
import '../../../../core/widgets/signature_pad_dialog.dart';
import '../../../../models/peritaje.dart';
import '../../../../models/inspection_analysis.dart';

class InformePeritajePage extends ConsumerStatefulWidget {
  final Peritaje peritaje;
  final bool isGuestMode;

  const InformePeritajePage({
    super.key,
    required this.peritaje,
    this.isGuestMode = false,
  });

  @override
  ConsumerState<InformePeritajePage> createState() => _InformePeritajePageState();
}

class _InformePeritajePageState extends ConsumerState<InformePeritajePage> {
  late Peritaje _currentPeritaje;
  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  Uint8List? _clientSignatureBytes;

  @override
  void initState() {
    super.initState();
    _currentPeritaje = widget.peritaje;
    _initSignatureFromModel();
    _loadDetails();
  }

  void _initSignatureFromModel() {
    final sig = _currentPeritaje.clientSignature;
    if (sig != null && sig.isNotEmpty) {
      try {
        if (sig.startsWith('data:image')) {
          final comma = sig.indexOf(',');
          if (comma != -1) {
            _clientSignatureBytes = base64Decode(sig.substring(comma + 1));
          }
        } else {
          _clientSignatureBytes = base64Decode(sig);
        }
      } catch (_) {}
    }
  }

  Future<void> _loadDetails() async {
    // Si ya tiene análisis y vehículo cargado, no es indispensable recargar
    if (_currentPeritaje.analysis != null && _currentPeritaje.clientName != null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final pId = _currentPeritaje.id;

      if (pId != null && pId.isNotEmpty) {
        // Cargar análisis IA específico para este peritaje
        final analyses = await client.getEntity(
          'GestionTallerProd_inspection_analysis',
        );

        final match = analyses.firstWhere((a) {
          if (a is! Map) return false;
          final fk = (a['inspection_cards_fk_id'] ?? '').toString();
          return fk == pId;
        }, orElse: () => null);

        if (match != null && match is Map) {
          final parsedAnalysis = InspectionAnalysis.fromJson(match.cast<String, dynamic>());
          setState(() {
            _currentPeritaje = _currentPeritaje.copyWith(analysis: parsedAnalysis);
          });
        }
      }

      // Enriquecer datos del vehículo y cliente si faltan
      if (_currentPeritaje.licensePlate == null || _currentPeritaje.licensePlate == 'SIN PLACA') {
        final vId = _currentPeritaje.vehiclesFkId;
        if (vId.isNotEmpty) {
          final veh = await client.getEntityById('GestionTallerProd_vehicles', vId);
          if (veh != null) {
            setState(() {
              _currentPeritaje = _currentPeritaje.copyWith(
                licensePlate: veh['license_plate']?.toString(),
                vehicleBrand: veh['brand']?.toString(),
                vehicleModel: veh['model']?.toString(),
                vehicleYear: veh['year']?.toString(),
                vehicleColor: veh['color']?.toString(),
                vehicleVin: veh['vin']?.toString(),
              );
            });
          }
        }
      }
    } catch (_) {
      // Ignorar error secundario de enriquecimiento
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openSignaturePad() async {
    final bytes = await SignaturePadDialog.show(
      context,
      title: 'Firma de Conformidad del Peritaje',
      subtitle: 'Al firmar, usted certifica la revisión y dictamen técnico del vehículo ${_currentPeritaje.licensePlate}.',
    );

    if (bytes != null && mounted) {
      setState(() {
        _clientSignatureBytes = bytes;
        _currentPeritaje = _currentPeritaje.copyWith(
          clientSignature: signatureBytesToBase64(bytes),
          clientSignatureDate: DateTime.now().toString().substring(0, 16),
        );
      });

      // Guardar firma en el backend
      if (_currentPeritaje.id != null) {
        try {
          final client = ref.read(apiClientProvider);
          await client.savePeritajeSignature(
            _currentPeritaje.id!,
            signatureBytesToBase64(bytes),
            additionalData: {
              if (_currentPeritaje.vehiclesFkId.isNotEmpty) 'vehicles_fk_id': _currentPeritaje.vehiclesFkId,
              if (_currentPeritaje.clientsFkId != null) 'clients_fk_id': _currentPeritaje.clientsFkId,
              if (_currentPeritaje.employeesFkId != null) 'employees_fk_id': _currentPeritaje.employeesFkId,
              'inspection_type': _currentPeritaje.inspectionType,
              'inspection_date': _currentPeritaje.inspectionDate,
              'item_name': _currentPeritaje.itemName,
            },
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Firma de conformidad registrada exitosamente.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Firma guardada localmente. Error de sincronización: $e'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _handleViewPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfBytes = await MobilePdfService.generatePeritajePdf(
        _currentPeritaje,
        clientSignatureBytes: _clientSignatureBytes,
      );
      if (mounted) {
        await MobilePdfService.previewPdf(
          context,
          pdfBytes,
          'Informe_Peritaje_${_currentPeritaje.licensePlate}_${_currentPeritaje.code}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _currentPeritaje.analysis;
    final date = _currentPeritaje.inspectionDate != null && _currentPeritaje.inspectionDate!.length >= 10
        ? _currentPeritaje.inspectionDate!.substring(0, 10)
        : _currentPeritaje.inspectionDate ?? 'Hoy';

    // Severidad estilo
    final sev = (analysis?.damageSeverity ?? 'moderado').toLowerCase();
    Color sevColor = AppColors.warning;
    String sevLabel = 'Moderado';
    if (sev.contains('grave') || sev.contains('alto') || sev.contains('severo')) {
      sevColor = AppColors.danger;
      sevLabel = 'Grave / Severo';
    } else if (sev.contains('leve') || sev.contains('bajo')) {
      sevColor = AppColors.success;
      sevLabel = 'Leve';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informe Oficial de Peritaje IA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            Text(
              '${_currentPeritaje.code} • ${_currentPeritaje.licensePlate}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.secondary),
        actions: [
          IconButton(
            onPressed: _isGeneratingPdf ? null : _handleViewPdf,
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            tooltip: 'Ver y Descargar PDF',
          ),
          IconButton(
            onPressed: _openSignaturePad,
            icon: Icon(
              _clientSignatureBytes != null ? Icons.verified_rounded : Icons.draw_rounded,
              color: _clientSignatureBytes != null ? AppColors.success : AppColors.primary,
            ),
            tooltip: 'Firmar de conformidad',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 720),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Membrete oficial
                      _buildHeaderBanner(date),
                      const SizedBox(height: 14),

                      // 2. Franja de Título
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'FICHA DE CONTROL, INSPECCIÓN Y EVALUACIÓN PERICIAL CON IA GEMINI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Cajas: Cliente y Vehículo
                      _buildClientAndVehicleCards(),
                      const SizedBox(height: 14),

                      // 4. Panel de Evaluación Pericial con IA Gemini Multimodal
                      _buildAiAnalysisSection(analysis, sevColor, sevLabel),
                      const SizedBox(height: 14),

                      // 5. Observaciones generales
                      if (_currentPeritaje.observations != null &&
                          _currentPeritaje.observations!.isNotEmpty) ...[
                        _buildObservationsCard(),
                        const SizedBox(height: 14),
                      ],

                      // 6. Firmas y Conformidad
                      _buildSignaturesSection(date),
                      const SizedBox(height: 14),

                      // Pie de página
                      const Center(
                        child: Text(
                          'Documento oficial de dictamen técnico asistido por IA Gemini • Taller Integral 360 Garage C.A.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openSignaturePad,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _clientSignatureBytes != null ? AppColors.success : AppColors.primary,
                    side: BorderSide(
                      color: _clientSignatureBytes != null ? AppColors.success : AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(
                    _clientSignatureBytes != null ? Icons.check_circle_rounded : Icons.draw_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _clientSignatureBytes != null ? 'Firma Conforme' : 'Firmar Dictamen',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingPdf ? null : _handleViewPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.file_download_rounded, size: 18),
                  label: const Text(
                    'Descargar PDF',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(String date) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF0F172A), width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo-taller-360.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'TALLER INTEGRAL 360 GARAGE C.A.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Mecánica General • Latonería y Pintura • Peritaje Computarizado',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
                Text(
                  'RIF: J-50123456-7 • Telf: (0212) 555-0360 • Caracas, Venezuela',
                  style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _currentPeritaje.code,
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fecha: $date',
                style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
              ),
              Text(
                'Tipo: ${_currentPeritaje.inspectionType.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientAndVehicleCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        final clientCard = Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.person_pin_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'DATOS DEL PROPIETARIO / CLIENTE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              const Divider(height: 12, color: Color(0xFFE2E8F0)),
              _rowInfo('Nombre/Razón', _currentPeritaje.clientName ?? 'No especificado'),
              _rowInfo('C.I. / RIF', _currentPeritaje.clientTaxId ?? '-'),
              _rowInfo('Teléfono', _currentPeritaje.clientPhone ?? '-'),
              _rowInfo('Email', _currentPeritaje.clientEmail ?? '-'),
              _rowInfo('Dirección', _currentPeritaje.clientAddress ?? '-'),
            ],
          ),
        );

        final vehicleCard = Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.directions_car_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'DATOS DEL VEHÍCULO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD97706)),
                    ),
                    child: Text(
                      _currentPeritaje.licensePlate ?? 'SIN PLACA',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 12, color: Color(0xFFE2E8F0)),
              _rowInfo('Marca / Modelo', '${_currentPeritaje.vehicleBrand ?? ''} ${_currentPeritaje.vehicleModel ?? ''}'.trim()),
              _rowInfo('Año / Color', '${_currentPeritaje.vehicleYear ?? '-'} • ${_currentPeritaje.vehicleColor ?? '-'}'),
              _rowInfo('Kilometraje', '${_currentPeritaje.vehicleMileage ?? '-'} km'),
              _rowInfo('VIN / Chasis', _currentPeritaje.vehicleVin ?? 'No registrado'),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              clientCard,
              const SizedBox(height: 10),
              vehicleCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: clientCard),
            const SizedBox(width: 10),
            Expanded(child: vehicleCard),
          ],
        );
      },
    );
  }

  Widget _buildAiAnalysisSection(InspectionAnalysis? analysis, Color sevColor, String sevLabel) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header IA
          LayoutBuilder(
            builder: (context, constraints) {
              final badges = Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sevColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sevLabel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (analysis?.confidenceScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9D5FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${analysis!.confidenceScore}% Certeza',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF581C87),
                        ),
                      ),
                    ),
                ],
              );

              if (constraints.maxWidth < 520) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7E22CE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EVALUACIÓN PERICIAL CON IA GEMINI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF581C87),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Diagnóstico computarizado de daños en carrocería y mecánica',
                            style: TextStyle(fontSize: 10, color: Color(0xFF7E22CE)),
                          ),
                          const SizedBox(height: 8),
                          badges,
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7E22CE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'EVALUACIÓN PERICIAL CON IA GEMINI',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF581C87),
                                ),
                              ),
                              Text(
                                'Diagnóstico computarizado de daños en carrocería y mecánica',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10, color: Color(0xFF7E22CE)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  badges,
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          if (analysis == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.smart_toy_outlined, size: 36, color: Color(0xFFC084FC)),
                  const SizedBox(height: 6),
                  const Text(
                    'Aún no se ha ejecutado el dictamen pericial con IA para esta ficha.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B21A8)),
                  ),
                  const SizedBox(height: 8),
                  if (!widget.isGuestMode)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/peritajes/camara', extra: _currentPeritaje);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7E22CE),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.videocam_rounded, size: 16),
                      label: const Text('Grabar Video para IA'),
                    ),
                ],
              ),
            ),
          ] else ...[
            // Métricas (Tipo de Daño, Mano de Obra, Estado)
            Row(
              children: [
                Expanded(
                  child: _metricTile(
                    'TIPO DE DAÑO',
                    analysis.damageType?.replaceAll('_', ' ') ?? 'Revisión General',
                    Icons.car_crash_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricTile(
                    'MANO DE OBRA ESTIMADA',
                    '${analysis.repairEstimatedHours ?? 0} Horas de taller',
                    Icons.schedule_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricTile(
                    'ESTADO DICTAMEN',
                    analysis.status?.toUpperCase() ?? 'COMPLETADO',
                    Icons.verified_user_rounded,
                    valueColor: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Partes Afectadas
            if (analysis.affectedParts.isNotEmpty) ...[
              const Text(
                'Partes y Componentes Afectados:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: analysis.affectedParts.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      '• $p',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // Repuestos Necesarios
            if (analysis.partsNeeded.isNotEmpty) ...[
              const Text(
                'Repuestos Sugeridos para Sustitución:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: analysis.partsNeeded.map((r) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          r,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // Diagnóstico y Conclusiones de Gemini
            if (analysis.observations != null && analysis.observations!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diagnóstico Técnico y Conclusiones del Perito IA:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B21A8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      analysis.observations!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(icon, size: 13, color: valueColor ?? const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObservationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OBSERVACIONES GENERALES DE RECEPCIÓN:',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 3),
          Text(
            _currentPeritaje.observations!,
            style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturesSection(String date) {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF0F172A), width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Inspector
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 48,
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    _currentPeritaje.inspectorName ?? 'Inspector Técnico Automotriz',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 8, color: Color(0xFFCBD5E1)),
                const Text(
                  'FIRMA DEL INSPECTOR / PERITO',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Cliente
          Expanded(
            child: InkWell(
              onTap: _openSignaturePad,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                children: [
                  Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: _clientSignatureBytes != null
                        ? Image.memory(_clientSignatureBytes!, fit: BoxFit.contain)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.touch_app_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Tocar para firmar',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const Divider(height: 8, color: Color(0xFFCBD5E1)),
                  Text(
                    _clientSignatureBytes != null
                        ? 'FIRMA DIGITAL CONFORME DEL CLIENTE'
                        : 'FIRMA DE CONFORMIDAD DEL CLIENTE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _clientSignatureBytes != null ? AppColors.success : const Color(0xFF64748B),
                    ),
                  ),
                  if (_clientSignatureBytes != null)
                    Text(
                      'Validado digitalmente • ${_currentPeritaje.clientSignatureDate ?? date}',
                      style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF0F172A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
